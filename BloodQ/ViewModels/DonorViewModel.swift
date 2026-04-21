//
//  DonorViewModel.swift
//  BloodQ
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

@MainActor
class DonorViewModel: ObservableObject {
    @Published var donors: [Donor] = []
    @Published var currentDonor: Donor?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var leaderboard: [LeaderboardEntry] = []
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func fetchDonorProfile(userId: String, completion: ((Donor?) -> Void)? = nil) {
        isLoading = true
        
        db.collection("donors").document(userId).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion?(nil)
                    return
                }
                
                if let donor = try? snapshot?.data(as: Donor.self) {
                    self?.currentDonor = donor
                    completion?(donor)
                } else {
                    completion?(nil)
                }
            }
        }
    }
    
    func searchDonors(district: String, upazilla: String, bloodGroup: String) {
        isLoading = true
        errorMessage = ""
        
        var query: Query = db.collection("donors")
        
        if !district.isEmpty {
            query = query.whereField("district", isEqualTo: district)
        }
        if !upazilla.isEmpty {
            query = query.whereField("upazilla", isEqualTo: upazilla)
        }
        if !bloodGroup.isEmpty {
            query = query.whereField("bloodGroup", isEqualTo: bloodGroup)
        }
        
        query.getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self?.donors = []
                    return
                }
                
                self?.donors = documents.compactMap { doc in
                    try? doc.data(as: Donor.self)
                }.filter { $0.isVerified }
            }
        }
    }
    
    func saveDonorProfile(donor: Donor, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        do {
            var updatedDonor = donor
            updatedDonor.updatedAt = Date()
            
            try db.collection("donors").document(donor.userId).setData(from: updatedDonor) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        completion(false)
                    } else {
                        self?.currentDonor = updatedDonor
                        self?.successMessage = "Profile saved successfully"
                        completion(true)
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                completion(false)
            }
        }
    }
    
    func profileExists(userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("donors").document(userId).getDocument { snapshot, error in
            DispatchQueue.main.async {
                let exists = snapshot?.exists ?? false
                completion(exists)
            }
        }
    }
    
    func addDonationRecord(date: Date, location: String, notes: String? = nil, completion: @escaping (Bool) -> Void) {
        guard var donor = currentDonor else {
            completion(false)
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let record = DonationRecord(date: date, location: location, notes: notes)
        donor.donationHistory.append(record)
        donor.donationHistory.sort { $0.date > $1.date }
        donor.totalDonations = donor.donationHistory.count
        donor.lastDonationDate = dateFormatter.string(from: date)
        
        saveDonorProfile(donor: donor) { success in
            completion(success)
        }
    }
    
    func updateLastDonationDate(date: Date, completion: @escaping (Bool) -> Void) {
        guard var donor = currentDonor else {
            completion(false)
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        donor.lastDonationDate = dateFormatter.string(from: date)
        
        saveDonorProfile(donor: donor, completion: completion)
    }
    
    func fetchLeaderboard() {
        isLoading = true
        
        db.collection("donors")
            .order(by: "totalDonations", descending: true)
            .limit(to: 100)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.leaderboard = []
                        return
                    }
                    
                    self?.leaderboard = documents.enumerated().compactMap { index, doc in
                        guard let donor = try? doc.data(as: Donor.self) else {
                            return nil
                        }
                        
                        return LeaderboardEntry(
                            userId: donor.userId,
                            name: donor.name,
                            bloodGroup: donor.bloodGroup,
                            totalDonations: donor.totalDonations,
                            profileImageURL: donor.profileImageURL,
                            rank: index + 1
                        )
                    }
                    
                    print("Leaderboard updated: \(self?.leaderboard.count ?? 0) donors")
                }
            }
    }
    
    func uploadProfileImage(_ image: UIImage, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
            return
        }
        
        let storageRef = storage.reference().child("profile_images/\(userId).jpg")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                }
            }
        }
    }
    
    func loadDistricts() -> [District] {
        guard let url = Bundle.main.url(forResource: "areas", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let areaData = try? JSONDecoder().decode(AreaData.self, from: data) else {
            return []
        }
        return areaData.districts
    }
    
    func validatePhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = "^01[3-9]\\d{8}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
    
    func validateNIDNumber(_ nid: String) -> Bool {
        let nidRegex = "^\\d{10}$|^\\d{13}$|^\\d{17}$"
        let nidPredicate = NSPredicate(format: "SELF MATCHES %@", nidRegex)
        return nidPredicate.evaluate(with: nid)
    }
}
