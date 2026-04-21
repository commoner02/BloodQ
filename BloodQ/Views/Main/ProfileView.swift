//
//  ProfileView.swift
//  BloodQ
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var donorViewModel: DonorViewModel
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var donor: Donor? {
        donorViewModel.currentDonor
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 12) {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 90, height: 90)
                            .overlay(
                                Text(String(donor?.name.prefix(1) ?? "U"))
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        Text(donor?.name ?? "User")
                            .font(.title3.bold())
                        
                        Text(donor?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Blood Group Badge
                        Text(donor?.bloodGroup ?? "")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .cornerRadius(20)
                        
                        if donor?.isVerified ?? false {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                                Text("Verified Donor")
                                    .font(.caption.bold())
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.top, 16)
                    
                    // Info Cards
                    VStack(spacing: 12) {
                        InfoRow(icon: "phone.fill", title: "Phone", value: donor?.mobile ?? "Not set")
                        InfoRow(icon: "mappin.circle.fill", title: "Location", value: "\(donor?.upazilla ?? ""), \(donor?.district ?? "")")
                        InfoRow(icon: "drop.fill", title: "Total Donations", value: "\(donor?.totalDonations ?? 0)")
                        
                        if let lastDate = donor?.lastDonationDate, !lastDate.isEmpty {
                            InfoRow(icon: "calendar", title: "Last Donation", value: lastDate)
                        }
                        
                        if let nid = donor?.nidNumber {
                            InfoRow(icon: "creditcard.fill", title: "NID", value: nid)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 10) {
                        NavigationLink(destination: EditProfileView()) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.red)
                                Text("Edit Profile")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(.red)
                                Text("Settings")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            alertMessage = "Are you sure you want to sign out?"
                            showAlert = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                Text("Sign Out")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Version Info
                    Text("BloodQ v1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                }
            }
            .background(Color.gray.opacity(0.04).ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let userId = authViewModel.user?.uid {
                    donorViewModel.fetchDonorProfile(userId: userId)
                }
            }
            .alert("Sign Out", isPresented: $showAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @EnvironmentObject var donorViewModel: DonorViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var mobile = ""
    @State private var selectedBloodGroup = ""
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var donor: Donor? {
        donorViewModel.currentDonor
    }
    
    let bloodGroups = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
    
    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("Full Name", text: $name)
                    .autocapitalization(.words)
                
                TextField("Mobile Number", text: $mobile)
                    .keyboardType(.phonePad)
                
                Picker("Blood Group", selection: $selectedBloodGroup) {
                    ForEach(bloodGroups, id: \.self) { group in
                        Text(group).tag(group)
                    }
                }
            }
            
            Section {
                Button(action: saveChanges) {
                    HStack {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save Changes")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                }
                .disabled(!isFormValid || isSaving)
            }
            .listRowBackground(Color.red)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
        .onAppear {
            name = donor?.name ?? ""
            mobile = donor?.mobile ?? ""
            selectedBloodGroup = donor?.bloodGroup ?? ""
        }
        .alert("Update", isPresented: $showAlert) {
            Button("OK") {
                if alertMessage.contains("success") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    var isFormValid: Bool {
        !name.isEmpty && donorViewModel.validatePhoneNumber(mobile) && !selectedBloodGroup.isEmpty
    }
    
    func saveChanges() {
        guard var donor = donor else { return }
        
        donor.name = name
        donor.mobile = mobile
        donor.bloodGroup = selectedBloodGroup
        donor.updatedAt = Date()
        
        isSaving = true
        
        donorViewModel.saveDonorProfile(donor: donor) { success in
            isSaving = false
            if success {
                alertMessage = "Profile updated successfully!"
                showAlert = true
            } else {
                alertMessage = donorViewModel.errorMessage
                showAlert = true
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("notificationsEnabled") var notificationsEnabled = true
    @AppStorage("darkModeEnabled") var darkModeEnabled = false
    
    var body: some View {
        Form {
            Section("Preferences") {
                Toggle("Push Notifications", isOn: $notificationsEnabled)
                Toggle("Dark Mode", isOn: $darkModeEnabled)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("1")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button("Privacy Policy") { }
                Button("Terms of Service") { }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") { dismiss() }
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.red)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
            
            Spacer()
        }
    }
}
