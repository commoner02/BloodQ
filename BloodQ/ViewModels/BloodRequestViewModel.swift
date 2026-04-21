//
//  BloodRequestViewModel.swift
//  BloodQ
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

@MainActor
class BloodRequestViewModel: ObservableObject {
    @Published var requests: [BloodRequest] = []
    @Published var myRequests: [BloodRequest] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var showNewRequestToast = false
    @Published var toastMessage = ""
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var previousRequestIds: Set<String> = []
    private var notifiedRequestIds: Set<String> = []
    
    func createRequest(
        requesterName: String,
        requesterPhone: String,
        bloodGroup: String,
        numberOfBags: Int,
        urgency: RequestUrgency,
        location: GeoLocation,
        locationName: String,
        district: String,
        upazilla: String,
        hospitalName: String?,
        description: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be logged in to create a request"
            completion(false)
            return
        }
        
        guard !requesterName.isEmpty else {
            errorMessage = "Please enter your name"
            completion(false)
            return
        }
        
        guard validatePhoneNumber(requesterPhone) else {
            errorMessage = "Please enter a valid phone number"
            completion(false)
            return
        }
        
        guard numberOfBags > 0 && numberOfBags <= 10 else {
            errorMessage = "Number of bags must be between 1 and 10"
            completion(false)
            return
        }
        
        isLoading = true
        
        let request = BloodRequest(
            requesterId: userId,
            requesterName: requesterName,
            requesterPhone: requesterPhone,
            bloodGroup: bloodGroup,
            numberOfBags: numberOfBags,
            urgency: urgency,
            location: location,
            locationName: locationName,
            district: district,
            upazilla: upazilla,
            hospitalName: hospitalName,
            description: description
        )
        
        print("Creating request: \(request.bloodGroup) by \(request.requesterName)")
        
        do {
            try db.collection("bloodRequests").document(request.id).setData(from: request) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print("Error creating request: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                        completion(false)
                    } else {
                        print("Request created successfully")
                        self?.successMessage = "Request created successfully"
                        completion(true)
                    }
                }
            }
        } catch {
            print("Exception creating request: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                completion(false)
            }
        }
    }
    
    func respondToRequest(requestId: String, donorId: String, donorName: String, requesterId: String, completion: @escaping (Bool) -> Void) {
        print("Donor responding: \(donorName) to request \(requestId)")
        
        db.collection("bloodRequests").document(requestId).updateData([
            "respondedDonors": FieldValue.arrayUnion([donorId])
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error recording response: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    print("Response recorded successfully")
                    self?.successMessage = "Response sent successfully"
                    
                    self?.db.collection("bloodRequests").document(requestId).getDocument { snapshot, _ in
                        var bloodGroup = ""
                        if let request = try? snapshot?.data(as: BloodRequest.self) {
                            bloodGroup = request.bloodGroup
                        }
                        
                        NotificationManager.shared.scheduleResponseNotificationForRequester(
                            donorName: donorName,
                            bloodGroup: bloodGroup,
                            requestId: requestId,
                            requesterId: requesterId
                        )
                    }
                    
                    NotificationCenter.default.post(
                        name: NSNotification.Name("DonorRespondedToRequest"),
                        object: nil,
                        userInfo: [
                            "donorName": donorName,
                            "requestId": requestId,
                            "requesterId": requesterId
                        ]
                    )
                    
                    completion(true)
                }
            }
        }
    }
    
    func startListeningToRequests() {
        print("Starting feed listener for all active requests")
        
        listener?.remove()
        notifiedRequestIds.removeAll()
        
        listener = db.collection("bloodRequests")
            .whereField("status", isEqualTo: "Active")
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Feed listener error: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("No documents found")
                        self?.requests = []
                        return
                    }
                    
                    var allRequests: [BloodRequest] = []
                    let currentRequestIds = Set(documents.compactMap { $0.documentID })
                    
                    for doc in documents {
                        if let request = try? doc.data(as: BloodRequest.self) {
                            allRequests.append(request)
                            
                            let isNewRequest = !(self?.previousRequestIds.contains(doc.documentID) ?? false)
                            let isNotMyRequest = request.requesterId != Auth.auth().currentUser?.uid
                            let notNotified = !(self?.notifiedRequestIds.contains(doc.documentID) ?? false)
                            
                            if isNewRequest && isNotMyRequest && notNotified {
                                print("New request detected: \(request.bloodGroup) from \(request.requesterName)")
                                
                                self?.notifiedRequestIds.insert(doc.documentID)
                                self?.showNewRequestToast = true
                                self?.toastMessage = "New \(request.bloodGroup) request in \(request.upazilla)"
                                NotificationManager.shared.playAlertSound()
                            }
                        }
                    }
                    
                    allRequests.sort { $0.createdAt > $1.createdAt }
                    self?.previousRequestIds = currentRequestIds
                    self?.requests = allRequests
                    print("Feed updated: \(allRequests.count) requests visible")
                }
            }
    }
    
    func stopListening() {
        print("Stopped feed listener")
        listener?.remove()
        notifiedRequestIds.removeAll()
    }
    
    func fetchActiveRequests() {
        isLoading = true
        
        db.collection("bloodRequests")
            .whereField("status", isEqualTo: "Active")
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print("Fetch error: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.requests = []
                        return
                    }
                    
                    let requests = documents.compactMap { doc -> BloodRequest? in
                        try? doc.data(as: BloodRequest.self)
                    }
                    
                    self?.requests = requests
                    print("Fetched \(requests.count) requests")
                }
            }
    }
    
    func fetchMyRequests() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        db.collection("bloodRequests")
            .whereField("requesterId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    self?.myRequests = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: BloodRequest.self)
                    } ?? []
                }
            }
    }
    
    func updateRequestStatus(requestId: String, status: RequestStatus, completion: @escaping (Bool) -> Void) {
        db.collection("bloodRequests").document(requestId).updateData([
            "status": status.rawValue
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    self?.successMessage = "Request updated successfully"
                    completion(true)
                }
            }
        }
    }
    
    func deleteRequest(requestId: String, completion: @escaping (Bool) -> Void) {
        db.collection("bloodRequests").document(requestId).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    self?.successMessage = "Request deleted successfully"
                    self?.myRequests.removeAll { $0.id == requestId }
                    completion(true)
                }
            }
        }
    }
    
    private func validatePhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = "^01[3-9]\\d{8}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
}
