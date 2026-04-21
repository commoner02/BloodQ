import SwiftUI
import Firebase

struct ChatView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    let conversation: ChatConversation
    
    @State private var messageText = ""
    @State private var requestDetails: BloodRequest?
    @State private var isLoadingRequest = true
    
    var currentUserId: String {
        authViewModel.user?.uid ?? ""
    }
    
    var currentUserName: String {
        authViewModel.user?.displayName ?? "You"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Request Reference Header
            if let request = requestDetails {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("📋 Blood Request Reference")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(request.bloodGroup)
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(request.locationName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(request.upazilla), \(request.district)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(request.urgency.rawValue)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(request.urgency == .critical ? Color.red : request.urgency == .urgent ? Color.orange : Color.blue)
                                .cornerRadius(6)
                            
                            Text("\(request.numberOfBags) bag(s) needed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
            } else if isLoadingRequest {
                HStack {
                    ProgressView()
                    Text("Loading request details...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatViewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == currentUserId
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    chatViewModel.listenToMessages(chatId: conversation.id)
                    chatViewModel.markMessagesAsRead(chatId: conversation.id, userId: currentUserId)
                    fetchRequestDetails()
                }
                .onChange(of: chatViewModel.messages.count) { _ in
                    if let lastMessage = chatViewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input Bar
            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .lineLimit(1...5)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(messageText.isEmpty ? Color.gray : Color.red)
                        .clipShape(Circle())
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color.white)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Chat")
                    .font(.headline)
            }
        }
    }
    
    func sendMessage() {
        chatViewModel.sendMessage(
            chatId: conversation.id,
            senderId: currentUserId,
            senderName: currentUserName,
            text: messageText
        ) { success in
            if success {
                messageText = ""
            }
        }
    }
    
    func fetchRequestDetails() {
        let db = Firestore.firestore()
        db.collection("bloodRequests").document(conversation.requestId).getDocument { snapshot, error in
            DispatchQueue.main.async {
                isLoadingRequest = false
                if let request = try? snapshot?.data(as: BloodRequest.self) {
                    requestDetails = request
                    print("Loaded request details for chat")
                } else {
                    print("Failed to load request details")
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .background(isFromCurrentUser ? Color.red : Color.gray.opacity(0.2))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 250, alignment: isFromCurrentUser ? .trailing : .leading)
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
}
