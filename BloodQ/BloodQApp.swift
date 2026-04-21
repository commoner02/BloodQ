//
//  BloodQApp.swift
//  BloodQ
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

@main
struct BloodQApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var donorViewModel = DonorViewModel()
    @StateObject private var bloodRequestViewModel = BloodRequestViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var notificationManager = NotificationManager()
    
    init() {
        FirebaseApp.configure()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(donorViewModel)
                .environmentObject(bloodRequestViewModel)
                .environmentObject(chatViewModel)
                .environmentObject(notificationManager)
                .preferredColorScheme(.light)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    notificationManager.clearBadge()
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted")
                    application.registerForRemoteNotifications()
                } else if let error = error {
                    print("Notification error: \(error.localizedDescription)")
                } else {
                    print("Notification permission denied")
                }
            }
        }
        
        Messaging.messaging().delegate = self
        
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("FCM Token: \(token)")
            if let userId = Auth.auth().currentUser?.uid {
                Firestore.firestore().collection("donors").document(userId).updateData([
                    "fcmToken": token
                ])
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([[.banner, .sound, .badge]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String {
            if type == "new_request", let requestId = userInfo["requestId"] as? String {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenRequestDetail"),
                    object: nil,
                    userInfo: ["requestId": requestId]
                )
            } else if type == "response", let requestId = userInfo["requestId"] as? String {
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenChat"),
                    object: nil,
                    userInfo: ["requestId": requestId]
                )
            }
        }
        
        completionHandler()
    }
}

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var donorViewModel: DonorViewModel
    @State private var isLoading = true
    @State private var needsProfile = false
    @State private var isCheckingProfile = false
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if isLoading || isCheckingProfile {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading profile...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if needsProfile {
                    CompleteProfileView()
                } else {
                    MainTabView()
                }
            } else {
                WelcomeView()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { newValue in
            if newValue {
                checkProfileStatus()
            } else {
                isLoading = false
                needsProfile = false
            }
        }
        .onAppear {
            if authViewModel.isAuthenticated {
                checkProfileStatus()
            }
            NotificationManager.shared.requestPermission()
        }
    }
    
    private func checkProfileStatus() {
        guard !isCheckingProfile else { return }
        guard let userId = authViewModel.user?.uid else {
            isLoading = false
            needsProfile = true
            return
        }
        
        isCheckingProfile = true
        isLoading = true
        
        donorViewModel.fetchDonorProfile(userId: userId) { donor in
            DispatchQueue.main.async {
                isLoading = false
                isCheckingProfile = false
                
                if let donor = donor, donor.isVerified && !donor.name.isEmpty {
                    needsProfile = false
                } else {
                    needsProfile = true
                }
            }
        }
    }
}
