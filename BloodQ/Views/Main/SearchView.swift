//
//  SearchView.swift
//  BloodQ
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var donorViewModel: DonorViewModel
    @State private var selectedDistrict = ""
    @State private var selectedUpazilla = ""
    @State private var selectedBloodGroup = ""
    @State private var showResults = false
    
    let bloodGroups = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
    let districts: [District]
    
    init() {
        self.districts = DonorViewModel().loadDistricts()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gray.opacity(0.04).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.system(size: 55))
                                .foregroundColor(.red)
                            Text("Find Blood Donors")
                                .font(.title3.bold())
                            Text("Search by location and blood group")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 16)
                        
                        // Search Form
                        VStack(spacing: 16) {
                            // Blood Group
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Blood Group")
                                    .font(.headline)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                                    ForEach(bloodGroups, id: \.self) { group in
                                        Button(action: {
                                            selectedBloodGroup = group
                                        }) {
                                            Text(group)
                                                .font(.subheadline.bold())
                                                .foregroundColor(selectedBloodGroup == group ? .white : .red)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(
                                                    selectedBloodGroup == group ?
                                                    Color.red : Color.white
                                                )
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.red, lineWidth: 1.5)
                                                )
                                        }
                                    }
                                }
                            }
                            
                            // District
                            VStack(alignment: .leading, spacing: 8) {
                                Text("District")
                                    .font(.headline)
                                
                                Menu {
                                    ForEach(districts) { district in
                                        Button(district.name) {
                                            selectedDistrict = district.name
                                            selectedUpazilla = ""
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedDistrict.isEmpty ? "Select District" : selectedDistrict)
                                            .foregroundColor(selectedDistrict.isEmpty ? .secondary : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                }
                            }
                            
                            // Upazilla
                            if !selectedDistrict.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Upazilla")
                                        .font(.headline)
                                    
                                    Menu {
                                        ForEach(getUpazillas(), id: \.self) { upazilla in
                                            Button(upazilla) {
                                                selectedUpazilla = upazilla
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(selectedUpazilla.isEmpty ? "Select Upazilla" : selectedUpazilla)
                                                .foregroundColor(selectedUpazilla.isEmpty ? .secondary : .primary)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            
                            // Search Button
                            Button(action: searchDonors) {
                                HStack {
                                    if donorViewModel.isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "magnifyingglass")
                                        Text("Search Donors")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(colors: [.red, .pink], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
                            }
                            .disabled(!isSearchValid || donorViewModel.isLoading)
                            .opacity(isSearchValid ? 1.0 : 0.6)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                        .padding(.horizontal)
                        
                        // Results
                        if showResults {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Found \(donorViewModel.donors.count) donors")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                if donorViewModel.donors.isEmpty {
                                    VStack(spacing: 16) {
                                        Image(systemName: "person.2.slash.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.gray)
                                        Text("No donors found")
                                            .font(.headline)
                                        Text("Try adjusting your search criteria")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                } else {
                                    ForEach(donorViewModel.donors) { donor in
                                        DonorResultCard(donor: donor)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    var isSearchValid: Bool {
        !selectedBloodGroup.isEmpty && !selectedDistrict.isEmpty
    }
    
    func getUpazillas() -> [String] {
        districts.first(where: { $0.name == selectedDistrict })?.upazillas ?? []
    }
    
    func searchDonors() {
        donorViewModel.searchDonors(
            district: selectedDistrict,
            upazilla: selectedUpazilla,
            bloodGroup: selectedBloodGroup
        )
        showResults = true
    }
}

struct DonorResultCard: View {
    let donor: Donor
    @State private var showCopiedToast = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Profile Circle
            Circle()
                .fill(Color.red.opacity(0.1))
                .frame(width: 55, height: 55)
                .overlay(
                    Text(donor.bloodGroup)
                        .font(.headline.bold())
                        .foregroundColor(.red)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(donor.name)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                    Text("\(donor.upazilla), \(donor.district)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                if !donor.lastDonationDate.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("Last: \(donor.lastDonationDate)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                if donor.canDonate {
                    Text("✓ Available to donate")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Call Button
            Button(action: makePhoneCall) {
                Image(systemName: "phone.fill")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.green)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
        .padding(.horizontal)
        .overlay(
            Group {
                if showCopiedToast {
                    Text("Number copied to clipboard")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .transition(.opacity)
                        .offset(y: -45)
                }
            }
        )
    }
    
    func makePhoneCall() {
        let phoneNumber = donor.mobile
        let formattedNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        
        #if targetEnvironment(simulator)
        UIPasteboard.general.string = formattedNumber
        
        withAnimation {
            showCopiedToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedToast = false
            }
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            let alert = UIAlertController(
                title: "📱 Donor Contact",
                message: "Phone number copied to clipboard:\n\(formattedNumber)\n\nYou can paste it in your Phone app.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            rootVC.present(alert, animated: true)
        }
        #else
        if let url = URL(string: "tel://\(formattedNumber)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            print(" Cannot call: \(formattedNumber)")
        }
        #endif
    }
}
