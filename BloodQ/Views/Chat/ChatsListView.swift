//
//  ChatsListView.swift
//  BloodQ
//

import SwiftUI

struct ChatsListView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            List(chatViewModel.conversations) { conversation in
                NavigationLink(destination: ChatView(conversation: conversation)) {
                    ChatRow(conversation: conversation, currentUserId: authViewModel.user?.uid ?? "")
                }
            }
            .navigationTitle("Messages")
            .onAppear {
                if let userId = authViewModel.user?.uid {
                    chatViewModel.fetchConversations(userId: userId)
                }
            }
        }
        .tabItem {
            Label("Chats", systemImage: "message.fill")
        }
        .badge(chatViewModel.totalUnreadCount > 0 ? chatViewModel.totalUnreadCount : 0)
    }
}

struct ChatRow: View {
    let conversation: ChatConversation
    let currentUserId: String
    
    var otherPersonName: String {
        conversation.participantNames.first(where: { $0.key != currentUserId })?.value ?? "Unknown"
    }
    
    var unreadCount: Int {
        conversation.unreadCount[currentUserId] ?? 0
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(otherPersonName.prefix(1)))
                        .font(.headline.bold())
                        .foregroundColor(.red)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(otherPersonName)
                        .font(.headline)
                    
                    if unreadCount > 0 {
                        Text("• \(unreadCount) new")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(unreadCount > 0 ? .primary : .secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(conversation.lastMessageTime, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(minWidth: 20, minHeight: 20)
                        .padding(.horizontal, 6)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}
