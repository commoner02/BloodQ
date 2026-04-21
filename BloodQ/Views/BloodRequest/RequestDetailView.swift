//
//  RequestDetailView.swift
//  BloodQ
//

import SwiftUI
import MapKit

struct RequestDetailView: View {
    @EnvironmentObject var requestViewModel: BloodRequestViewModel
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var donorViewModel: DonorViewModel
    @Environment(\.dismiss) var dismiss
    let request: BloodRequest
    
    @State private var region: MKCoordinateRegion
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isResponding = false
    @State private var navigateToChat = false
    @State private var createdChatId: String?
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var existingConversationId: String?
    
    init(request: BloodRequest) {
        self.request = request
        _region = State(initialValue: MKCoordinateRegion(
            center: request.location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var isMyRequest: Bool {
        request.requesterId == authViewModel.user?.uid
    }
    
    var hasResponded: Bool {
        guard let userId = authViewModel.user?.uid else { return false }
        return request.respondedDonors.contains(userId)
    }
    
    var hasExistingChat: Bool {
        return existingConversationId != nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Request Info
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text(request.bloodGroup)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.red)
                                
                                Spacer()
                                
                                Text(request.urgency.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(request.urgency == .critical ? Color.red : request.urgency == .urgent ? Color.orange : Color.blue)
                                    .cornerRadius(10)
                            }
                            
                            Text("\(request.numberOfBags) bag\(request.numberOfBags > 1 ? "s" : "") needed")
                                .font(.title3.bold())
                            
                            Divider()
                            
                            DetailRow(icon: "person.fill", title: "Requester", value: request.requesterName)
                            DetailRow(icon: "phone.fill", title: "Contact", value: request.requesterPhone)
                            DetailRow(icon: "mappin.circle.fill", title: "Location", value: request.locationName)
                            DetailRow(icon: "building.2.fill", title: "Area", value: "\(request.upazilla), \(request.district)")
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Description")
                                    .font(.headline)
                                Text(request.description)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Posted")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(request.createdAt, style: .relative)
                                        .font(.subheadline.bold())
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Expires")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(request.expiresAt, style: .relative)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.05), radius: 10)
                        .padding(.horizontal)
                        
                        //Chat Button
                        if hasExistingChat {
                            Button(action: openChat) {
                                HStack {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                    Text("View Chat")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                            }
                            .padding(.horizontal)
                        } else if isMyRequest && !request.respondedDonors.isEmpty {
                            // Requester: Someone responded, but no chat yet
                            Button(action: createChatAsRequester) {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("Message Responder")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                            }
                            .padding(.horizontal)
                        } else if !isMyRequest && !hasResponded {
                            // Donor: Not responded yet
                            Button(action: respondToRequest) {
                                HStack {
                                    if isResponding {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "message.fill")
                                        Text("I Can Help")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                            }
                            .disabled(isResponding)
                            .padding(.horizontal)
                        } else if !isMyRequest && hasResponded {
                            // Donor: Already responded
                            Button(action: openChat) {
                                HStack {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                    Text("Go to Chat")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Show responders list for requester
                        if isMyRequest && !request.respondedDonors.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("\(request.respondedDonors.count) donor(s) responded")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(request.respondedDonors, id: \.self) { donorId in
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Donor is ready to help")
                                            .font(.subheadline)
                                        Spacer()
                                        Button("Message") {
                                            createChatWithDonor(donorId: donorId)
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
                .alert(alertTitle, isPresented: $showAlert) {
                    Button("OK") {
                        if alertTitle == "Success" && createdChatId != nil {
                            navigateToChat = true
                        }
                    }
                } message: {
                    Text(alertMessage)
                }
                
                // Navigation to Chat
                NavigationLink(
                    destination: Group {
                        if let chatId = createdChatId ?? existingConversationId {
                            ChatView(conversation: ChatConversation(
                                id: chatId,
                                requestId: request.id,
                                participantIds: [],
                                participantNames: [:],
                                lastMessage: "",
                                lastMessageTime: Date(),
                                unreadCount: [:]
                            ))
                        }
                    },
                    isActive: $navigateToChat
                ) {
                    EmptyView()
                }
                
                // Toast View
                if showToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(toastMessage)
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 30)
                    }
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showToast = false
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            // Fetch conversations to check for existing chat
            if let userId = authViewModel.user?.uid {
                chatViewModel.fetchConversations(userId: userId)
                
                // Check for existing conversation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let conversation = chatViewModel.conversations.first(where: { $0.requestId == request.id }) {
                        existingConversationId = conversation.id
                        print("Found existing conversation: \(conversation.id)")
                    }
                }
            }
        }
    }
    
    func respondToRequest() {
        guard let userId = authViewModel.user?.uid,
              let userName = donorViewModel.currentDonor?.name ?? authViewModel.user?.displayName else {
            alertTitle = "Error"
            alertMessage = "Unable to get your profile information"
            showAlert = true
            return
        }
        
        isResponding = true
        print("Responding to request: \(request.id)")
        
        chatViewModel.createOrGetConversation(
            requestId: request.id,
            currentUserId: userId,
            currentUserName: userName,
            otherUserId: request.requesterId,
            otherUserName: request.requesterName
        ) { chatId in
            guard let chatId = chatId else {
                DispatchQueue.main.async {
                    self.isResponding = false
                    self.alertTitle = "Error"
                    self.alertMessage = "Failed to create conversation"
                    self.showAlert = true
                }
                return
            }
            
            print("Chat created: \(chatId)")
            self.createdChatId = chatId
            self.existingConversationId = chatId
            
            self.requestViewModel.respondToRequest(
                requestId: self.request.id,
                donorId: userId,
                donorName: userName,
                requesterId: self.request.requesterId
            ) { success in
                DispatchQueue.main.async {
                    self.isResponding = false
                    
                    if success {
                        self.alertTitle = "Success"
                        self.alertMessage = "You can now chat with the requester!"
                        self.showAlert = true
                    } else {
                        self.alertTitle = "Success"
                        self.alertMessage = "Chat is ready!"
                        self.showAlert = true
                    }
                }
            }
        }
    }
    
    func createChatAsRequester() {
        guard let userId = authViewModel.user?.uid,
              let userName = donorViewModel.currentDonor?.name ?? authViewModel.user?.displayName else {
            alertTitle = "Error"
            alertMessage = "Unable to get your profile"
            showAlert = true
            return
        }
        
        // Get the first responder
        guard let donorId = request.respondedDonors.first else {
            alertTitle = "Error"
            alertMessage = "No responders found"
            showAlert = true
            return
        }
        
        print("Requester creating chat with donor: \(donorId)")
        
        chatViewModel.createOrGetConversation(
            requestId: request.id,
            currentUserId: userId,
            currentUserName: userName,
            otherUserId: donorId,
            otherUserName: "Donor"
        ) { chatId in
            DispatchQueue.main.async {
                if let chatId = chatId {
                    self.createdChatId = chatId
                    self.existingConversationId = chatId
                    self.alertTitle = "Success"
                    self.alertMessage = "Chat ready! You can now message the donor."
                    self.showAlert = true
                } else {
                    self.alertTitle = "Error"
                    self.alertMessage = "Failed to create chat"
                    self.showAlert = true
                }
            }
        }
    }
    
    func createChatWithDonor(donorId: String) {
        guard let userId = authViewModel.user?.uid,
              let userName = donorViewModel.currentDonor?.name ?? authViewModel.user?.displayName else {
            alertTitle = "Error"
            alertMessage = "Unable to get your profile"
            showAlert = true
            return
        }
        
        print("Requester creating chat with specific donor: \(donorId)")
        
        chatViewModel.createOrGetConversation(
            requestId: request.id,
            currentUserId: userId,
            currentUserName: userName,
            otherUserId: donorId,
            otherUserName: "Donor"
        ) { chatId in
            DispatchQueue.main.async {
                if let chatId = chatId {
                    self.createdChatId = chatId
                    self.existingConversationId = chatId
                    self.navigateToChat = true
                } else {
                    self.alertTitle = "Error"
                    self.alertMessage = "Failed to create chat"
                    self.showAlert = true
                }
            }
        }
    }
    
    func openChat() {
        navigateToChat = true
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.red)
                .frame(width: 25)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
            
            Spacer()
        }
    }
}
