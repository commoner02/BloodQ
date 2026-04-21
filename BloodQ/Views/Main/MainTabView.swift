import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "heart.text.square.fill")
                }
                .badge(notificationManager.totalUnreadCount > 0 ? notificationManager.totalUnreadCount : 0)
                .tag(0)
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            LeaderboardView()
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy.fill")
                }
                .tag(3)
            
            ChatsListView()
                .tabItem {
                    Label("Chats", systemImage: "message.fill")
                }
                .badge(chatViewModel.totalUnreadCount > 0 ? chatViewModel.totalUnreadCount : 0)
                .tag(4)
        }
        .accentColor(.red)
        .onAppear {
            if let userId = authViewModel.user?.uid {
                chatViewModel.fetchConversations(userId: userId)
            }
        }
    }
}
