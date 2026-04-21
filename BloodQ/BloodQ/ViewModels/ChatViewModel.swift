//
//  ChatViewModel.swift
//  BloodQ
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [ChatConversation] = []
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var totalUnreadCount = 0
    
    private let db = Firestore.firestore()
    private var messagesListener: ListenerRegistration?
    private var conversationsListener: ListenerRegistration?
    
    func fetchConversations(userId: String) {
        conversationsListener = db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageTime", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    self?.conversations = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: ChatConversation.self)
                    } ?? []
                    
                    self?.updateUnreadCount(userId: userId)
                }
            }
    }
    
    private func updateUnreadCount(userId: String) {
        var total = 0
        for conversation in conversations {
            total += conversation.unreadCount[userId] ?? 0
        }
        totalUnreadCount = total
        NotificationManager.shared.updateTotalBadgeCount()
    }
    
    func markMessagesAsRead(chatId: String, userId: String) {
        db.collection("conversations").document(chatId).updateData([
            "unreadCount.\(userId)": 0
        ]) { _ in
            NotificationManager.shared.updateTotalBadgeCount()
        }
    }
    
    func createOrGetConversation(
        requestId: String,
        currentUserId: String,
        currentUserName: String,
        otherUserId: String,
        otherUserName: String,
        completion: @escaping (String?) -> Void
    ) {
        db.collection("conversations")
            .whereField("requestId", isEqualTo: requestId)
            .whereField("participantIds", arrayContains: currentUserId)
            .getDocuments { [weak self] snapshot, error in
                if let existingConversation = snapshot?.documents.first,
                   let conversation = try? existingConversation.data(as: ChatConversation.self),
                   conversation.participantIds.contains(otherUserId) {
                    completion(conversation.id)
                    return
                }
                
                let conversationId = UUID().uuidString
                let conversation = ChatConversation(
                    id: conversationId,
                    requestId: requestId,
                    participantIds: [currentUserId, otherUserId],
                    participantNames: [
                        currentUserId: currentUserName,
                        otherUserId: otherUserName
                    ],
                    lastMessage: "",
                    lastMessageTime: Date(),
                    unreadCount: [currentUserId: 0, otherUserId: 0]
                )
                
                do {
                    try self?.db.collection("conversations").document(conversationId).setData(from: conversation) { error in
                        if error != nil {
                            completion(nil)
                        } else {
                            completion(conversationId)
                        }
                    }
                } catch {
                    completion(nil)
                }
            }
    }
    
    func listenToMessages(chatId: String) {
        messagesListener?.remove()
        
        messagesListener = db.collection("conversations")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    self?.messages = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: ChatMessage.self)
                    } ?? []
                }
            }
    }
    
    func sendMessage(
        chatId: String,
        senderId: String,
        senderName: String,
        text: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(false)
            return
        }
        
        let message = ChatMessage(
            chatId: chatId,
            senderId: senderId,
            senderName: senderName,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        do {
            try db.collection("conversations")
                .document(chatId)
                .collection("messages")
                .document(message.id)
                .setData(from: message) { [weak self] error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self?.errorMessage = error.localizedDescription
                            completion(false)
                        }
                        return
                    }
                    
                    self?.db.collection("conversations").document(chatId).getDocument { snapshot, _ in
                        guard var conversation = try? snapshot?.data(as: ChatConversation.self) else {
                            completion(false)
                            return
                        }
                        
                        conversation.lastMessage = text
                        conversation.lastMessageTime = Date()
                        
                        for participantId in conversation.participantIds where participantId != senderId {
                            conversation.unreadCount[participantId, default: 0] += 1
                        }
                        
                        try? self?.db.collection("conversations").document(chatId).setData(from: conversation) { _ in
                            completion(true)
                            if let userId = Auth.auth().currentUser?.uid {
                                self?.updateUnreadCount(userId: userId)
                            }
                        }
                    }
                }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                completion(false)
            }
        }
    }
    
    func getUnreadCount(userId: String) -> Int {
        return conversations.reduce(0) { total, conversation in
            total + (conversation.unreadCount[userId] ?? 0)
        }
    }
    
    func stopListening() {
        messagesListener?.remove()
        conversationsListener?.remove()
    }
    
    deinit {
        Task { @MainActor in
            stopListening()
        }
    }
}
