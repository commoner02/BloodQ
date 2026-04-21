//
//  NotificationManager.swift
//  BloodQ
//

import UIKit
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import AVFoundation

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    @Published var totalUnreadCount = 0
    
    private var lastNotificationPerDonor: [String: Date] = [:]
    private let minimumInterval: TimeInterval = 60
    private var processedResponseIds: Set<String> = []
    private var processedRequestIds: Set<String> = []
    private var db = Firestore.firestore()
    
    init() {
        checkPermission()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                if granted {
                    print("Notification permission granted")
                }
            }
        }
    }
    
    private func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleNewRequestNotificationForDonor(
        bloodGroup: String,
        district: String,
        upazilla: String,
        urgency: String,
        requestId: String,
        donorId: String
    ) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              currentUserId == donorId else {
            print("Skipping: Current user is not the target donor")
            return
        }
        
        let notificationKey = "new_\(requestId)"
        if processedRequestIds.contains(notificationKey) {
            print("Already notified donor about this request: \(requestId)")
            return
        }
        
        if let lastTime = lastNotificationPerDonor[donorId],
           Date().timeIntervalSince(lastTime) < minimumInterval {
            print("Rate limiting: Last notification was \(Int(Date().timeIntervalSince(lastTime))) seconds ago")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Blood Needed - \(urgency)"
        content.body = "\(bloodGroup) blood needed in \(upazilla), \(district)"
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        content.userInfo = [
            "requestId": requestId,
            "type": "new_request",
            "donorId": donorId
        ]
        
        let identifier = "new_request_\(requestId)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule new request notification: \(error.localizedDescription)")
            } else {
                print("Success: New request notification sent to donor: \(donorId)")
                self.processedRequestIds.insert(notificationKey)
                self.lastNotificationPerDonor[donorId] = Date()
                self.updateTotalBadgeCount()
            }
        }
    }
    
    func scheduleResponseNotificationForRequester(
        donorName: String,
        bloodGroup: String,
        requestId: String,
        requesterId: String
    ) {
        print("Scheduling response notification - Requester ID: \(requesterId)")
        print("Current user ID: \(Auth.auth().currentUser?.uid ?? "nil")")
        
        let notificationKey = "response_\(requestId)_\(donorName)"
        if processedResponseIds.contains(notificationKey) {
            print("Already showed response notification for this donor-response")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Donor Responded"
        content.body = "\(donorName) can help with your \(bloodGroup) blood request"
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        content.userInfo = [
            "requestId": requestId,
            "type": "response",
            "requesterId": requesterId,
            "donorName": donorName
        ]
        
        let identifier = "response_\(requestId)_\(donorName)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule response notification: \(error.localizedDescription)")
            } else {
                print("Success: Response notification scheduled")
                self.processedResponseIds.insert(notificationKey)
                self.updateTotalBadgeCount()
            }
        }
    }
    
    func updateTotalBadgeCount() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    func clearBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    func playAlertSound() {
        let systemSoundID: SystemSoundID = 1007
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        clearBadge()
    }
}
