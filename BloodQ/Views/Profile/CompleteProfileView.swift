//
//  CompleteProfileView.swift
//  BloodQ
//

import SwiftUI
import PhotosUI

struct CompleteProfileView: View {
    @EnvironmentObject var donorViewModel: DonorViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var mobile = ""
    @State private var selectedDistrict = ""
    @State private var selectedUpazilla = ""
    @State private var selectedBloodGroup = ""
    @State private var lastDonationDate = Date()
    @State private var hasNeverDonated = true
    
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    @State private var showImagePicker = false
    @State private var imagePickerType: ImagePickerType = .front
    @State private var isVerifying = false
    @State private var nidNumber = ""
    @State private var nidVerified = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isSaving = false
    @State private var shouldDismiss = false
    
    let bloodGroups = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
    let districts: [District]
    
    init() {
        self.districts = DonorViewModel().loadDistricts()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 55))
                            .foregroundColor(.red)
                        Text("Complete Your Profile")
                            .font(.title2.bold())
                        Text("Please provide your details to continue")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    if !nidVerified {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("National ID Verification")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Text("Required for donor verification")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                ImageUploadBox(
                                    title: "Front Side",
                                    image: frontImage,
                                    onTap: {
                                        imagePickerType = .front
                                        showImagePicker = true
                                    }
                                )
                                
                                ImageUploadBox(
                                    title: "Back Side",
                                    image: backImage,
                                    onTap: {
                                        imagePickerType = .back
                                        showImagePicker = true
                                    }
                                )
                            }
                            .padding(.horizontal)
                            
                            if frontImage != nil && backImage != nil && !isVerifying {
                                Button(action: verifyNID) {
                                    HStack {
                                        if isVerifying {
                                            ProgressView().tint(.white)
                                        } else {
                                            Text("Verify NID")
                                            Image(systemName: "checkmark.shield.fill")
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .disabled(isVerifying)
                                .padding(.horizontal)
                            }
                            
                            if isVerifying {
                                HStack {
                                    ProgressView()
                                    Text("Verifying NID...")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                        }
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.04))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("NID Verified")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Text("Your identity has been verified")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.08))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    if nidVerified {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 22)
                                TextField("Full Name", text: $name)
                                    .autocapitalization(.words)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.04), radius: 4, y: 1)
                            
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 22)
                                TextField("Mobile (01XXXXXXXXX)", text: $mobile)
                                    .keyboardType(.phonePad)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.04), radius: 4, y: 1)
                            
                            Menu {
                                ForEach(bloodGroups, id: \.self) { group in
                                    Button(group) {
                                        selectedBloodGroup = group
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "drop.fill")
                                        .foregroundColor(.red)
                                    Text(selectedBloodGroup.isEmpty ? "Select Blood Group" : selectedBloodGroup)
                                        .foregroundColor(selectedBloodGroup.isEmpty ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 1)
                            }
                            
                            Menu {
                                ForEach(districts) { district in
                                    Button(district.name) {
                                        selectedDistrict = district.name
                                        selectedUpazilla = ""
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "map.fill")
                                        .foregroundColor(.red)
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
                                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 1)
                            }
                            
                            if !selectedDistrict.isEmpty {
                                Menu {
                                    ForEach(getUpazillas(), id: \.self) { upazilla in
                                        Button(upazilla) {
                                            selectedUpazilla = upazilla
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.red)
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
                                    .shadow(color: Color.black.opacity(0.04), radius: 4, y: 1)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Never donated before", isOn: $hasNeverDonated)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                
                                if !hasNeverDonated {
                                    DatePicker("Last Donation Date", selection: $lastDonationDate, displayedComponents: .date)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Button(action: saveProfile) {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Complete Profile")
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
                            .shadow(radius: 4)
                        }
                        .disabled(!isFormValid || isSaving)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .background(Color.gray.opacity(0.04).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: imagePickerType == .front ? $frontImage : $backImage)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") {
                    if alertTitle == "Success" {
                        shouldDismiss = true
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: shouldDismiss) { newValue in
                if newValue {
                    dismiss()
                }
            }
        }
    }
    
    var isFormValid: Bool {
        !name.isEmpty &&
        donorViewModel.validatePhoneNumber(mobile) &&
        !selectedBloodGroup.isEmpty &&
        !selectedDistrict.isEmpty &&
        !selectedUpazilla.isEmpty &&
        nidVerified
    }
    
    func getUpazillas() -> [String] {
        districts.first(where: { $0.name == selectedDistrict })?.upazillas ?? []
    }
    
    func verifyNID() {
        guard let front = frontImage, let back = backImage else {
            alertTitle = "Error"
            alertMessage = "Please select both front and back images of your NID"
            showAlert = true
            return
        }
        
        isVerifying = true
        
        NIDVerificationService.shared.verifyNID(frontImage: front, backImage: back) { result in
            DispatchQueue.main.async {
                self.isVerifying = false
                
                switch result {
                case .success(let nidData):
                    if nidData.isValid {
                        self.nidVerified = true
                        self.nidNumber = nidData.nidNumber ?? ""
                        if let extractedName = nidData.name, !extractedName.isEmpty {
                            self.name = extractedName
                        }
                        self.alertTitle = "Success"
                        self.alertMessage = "NID verified successfully! Please complete your profile."
                        self.showAlert = true
                    } else {
                        self.alertTitle = "Verification Failed"
                        self.alertMessage = nidData.errorMessage ?? "NID verification failed. Please ensure your images are clear and try again."
                        self.showAlert = true
                    }
                case .failure(let error):
                    self.alertTitle = "Error"
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                }
            }
        }
    }
    
    func saveProfile() {
        guard !isSaving else { return }
        
        guard let userId = authViewModel.user?.uid,
              let email = authViewModel.user?.email else {
            alertTitle = "Error"
            alertMessage = "User not found. Please sign in again."
            showAlert = true
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let donor = Donor(
            id: userId,
            userId: userId,
            name: name,
            email: email,
            mobile: mobile,
            district: selectedDistrict,
            upazilla: selectedUpazilla,
            bloodGroup: selectedBloodGroup,
            lastDonationDate: hasNeverDonated ? "" : dateFormatter.string(from: lastDonationDate),
            isVerified: true,
            nidNumber: nidNumber
        )
        
        isSaving = true
        
        donorViewModel.saveDonorProfile(donor: donor) { success in
            DispatchQueue.main.async {
                self.isSaving = false
                if success {
                    self.alertTitle = "Success"
                    self.alertMessage = "Profile completed successfully!"
                    self.showAlert = true
                } else {
                    self.alertTitle = "Error"
                    self.alertMessage = self.donorViewModel.errorMessage
                    self.showAlert = true
                }
            }
        }
    }
}

enum ImagePickerType {
    case front, back
}

struct ImageUploadBox: View {
    let title: String
    let image: UIImage?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 110)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.gray)
                        .frame(height: 110)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}
