//
//  CreateRequestView.swift
//  BloodQ
//

import SwiftUI
import MapKit

struct CreateRequestView: View {
    @EnvironmentObject var requestViewModel: BloodRequestViewModel
    @EnvironmentObject var donorViewModel: DonorViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var requesterName = ""
    @State private var requesterPhone = ""
    @State private var selectedBloodGroup = ""
    @State private var numberOfBags = 1
    @State private var urgency: RequestUrgency = .normal
    @State private var hospitalName = ""
    @State private var description = ""
    
    // Location fields
    @State private var selectedDistrict = ""
    @State private var selectedUpazilla = ""
    @State private var detailedAddress = ""
    @State private var locationName = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let bloodGroups = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
    let districts: [District]
    
    init() {
        self.districts = DonorViewModel().loadDistricts()
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Requester Information") {
                    TextField("Full Name", text: $requesterName)
                    TextField("Phone Number", text: $requesterPhone)
                        .keyboardType(.phonePad)
                }
                
                Section("Blood Requirement") {
                    Picker("Blood Group", selection: $selectedBloodGroup) {
                        Text("Select").tag("")
                        ForEach(bloodGroups, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                    
                    Stepper("Bags Needed: \(numberOfBags)", value: $numberOfBags, in: 1...10)
                    
                    Picker("Urgency", selection: $urgency) {
                        ForEach(RequestUrgency.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }
                
                Section("Location Details") {
                    // District Picker
                    Menu {
                        ForEach(districts) { district in
                            Button(district.name) {
                                selectedDistrict = district.name
                                selectedUpazilla = "" // Reset upazilla when district changes
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
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(10)
                    }
                    
                    // Upazilla Picker (only show if district selected)
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
                                Text(selectedUpazilla.isEmpty ? "Select Upazilla/Area" : selectedUpazilla)
                                    .foregroundColor(selectedUpazilla.isEmpty ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(10)
                        }
                    }
                    
                    // Detailed Address
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.red)
                            Text("Detailed Address")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        TextField("e.g., Khulna Medical College, Khulna", text: $detailedAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Hospital name, road number, landmark, etc.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    
                    // Location Name Preview
                    if !selectedDistrict.isEmpty && !selectedUpazilla.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Label("Location Preview", systemImage: "eye.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formattedLocation)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(8)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                        }
                        .padding(.top, 5)
                    }
                }
                
                Section("Additional Details") {
                    TextField("Description (e.g., emergency, patient condition)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button(action: createRequest) {
                        HStack {
                            if requestViewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Request")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color.red)
                    .disabled(!isFormValid || requestViewModel.isLoading)
                }
            }
            .navigationTitle("Request Blood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Blood Request", isPresented: $showAlert) {
                Button("OK") {
                    if requestViewModel.successMessage.contains("success") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                if let donor = donorViewModel.currentDonor {
                    requesterName = donor.name
                    requesterPhone = donor.mobile
                }
            }
        }
    }
    
    var isFormValid: Bool {
        !requesterName.isEmpty &&
        donorViewModel.validatePhoneNumber(requesterPhone) &&
        !selectedBloodGroup.isEmpty &&
        !selectedDistrict.isEmpty &&
        !selectedUpazilla.isEmpty &&
        !detailedAddress.isEmpty &&
        !description.isEmpty
    }
    
    var formattedLocation: String {
        var components: [String] = []
        if !detailedAddress.isEmpty {
            components.append(detailedAddress)
        }
        if !selectedUpazilla.isEmpty {
            components.append(selectedUpazilla)
        }
        if !selectedDistrict.isEmpty {
            components.append(selectedDistrict)
        }
        return components.joined(separator: ", ")
    }
    
    func getUpazillas() -> [String] {
        districts.first(where: { $0.name == selectedDistrict })?.upazillas ?? []
    }
    
    func createRequest() {
        let defaultLocation = GeoLocation(latitude: 0, longitude: 0)
        
        requestViewModel.createRequest(
            requesterName: requesterName,
            requesterPhone: requesterPhone,
            bloodGroup: selectedBloodGroup,
            numberOfBags: numberOfBags,
            urgency: urgency,
            location: defaultLocation,
            locationName: formattedLocation,
            district: selectedDistrict,
            upazilla: selectedUpazilla,
            hospitalName: detailedAddress.isEmpty ? nil : detailedAddress,
            description: description
        ) { success in
            if success {
                alertMessage = "Blood request created successfully!."
            } else {
                alertMessage = requestViewModel.errorMessage
            }
            showAlert = true
        }
    }
}
