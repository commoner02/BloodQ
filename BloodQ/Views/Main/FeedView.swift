//
//  FeedView.swift
//  BloodQ
//

import SwiftUI

struct FeedView: View {
    @EnvironmentObject var requestViewModel: BloodRequestViewModel
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showCreateRequest = false
    @State private var selectedRequest: BloodRequest?
    @State private var searchText = ""
    
    var filteredRequests: [BloodRequest] {
        if searchText.isEmpty {
            return requestViewModel.requests
        }
        return requestViewModel.requests.filter {
            $0.bloodGroup.lowercased().contains(searchText.lowercased()) ||
            $0.locationName.lowercased().contains(searchText.lowercased()) ||
            $0.district.lowercased().contains(searchText.lowercased()) ||
            $0.requesterName.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gray.opacity(0.05).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search blood group, location, name...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    
                    // Request List
                    if requestViewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxHeight: .infinity)
                    } else if filteredRequests.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "heart.slash.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No Blood Requests")
                                .font(.title3.bold())
                            Text("Be the first to create a request")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(filteredRequests.indices, id: \.self) { index in
                                    let request = filteredRequests[index]
                                    BloodRequestCard(request: request)
                                        .onTapGesture {
                                            selectedRequest = request
                                        }
                                }
                            }
                            .padding()
                        }
                        .refreshable {
                            requestViewModel.fetchActiveRequests()
                        }
                    }
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showCreateRequest = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Request Blood")
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(colors: [.red, .pink], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(25)
                            .shadow(color: .red.opacity(0.4), radius: 10, y: 5)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
                
                // Toast Notification for New Request
                if requestViewModel.showNewRequestToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.red)
                            Text(requestViewModel.toastMessage)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                        .padding(.horizontal)
                        .padding(.bottom, 80)
                    }
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                requestViewModel.showNewRequestToast = false
                            }
                        }
                    }
                }
            }
            .navigationTitle("Blood Requests")
            .onAppear {
                requestViewModel.startListeningToRequests()
            }
            .onDisappear {
                requestViewModel.stopListening()
            }
            .sheet(isPresented: $showCreateRequest) {
                CreateRequestView()
            }
            .sheet(item: $selectedRequest) { request in
                RequestDetailView(request: request)
            }
        }
    }
}

// Blood Request Card
struct BloodRequestCard: View {
    let request: BloodRequest
    
    var urgencyColor: Color {
        switch request.urgency {
        case .critical: return .red
        case .urgent: return .orange
        case .normal: return .blue
        }
    }
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(request.createdAt)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 24 {
            return "\(hours / 24)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else {
            return "\(minutes)m ago"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(request.bloodGroup)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .cornerRadius(12)
                
                Spacer()
                
                Text(request.urgency.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(urgencyColor)
                    .cornerRadius(8)
            }
            
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                Text(request.requesterName)
                    .font(.headline)
            }
            
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                VStack(alignment: .leading) {
                    Text(request.locationName)
                        .font(.subheadline)
                    Text("\(request.upazilla), \(request.district)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.red)
                Text("\(request.numberOfBags) bag\(request.numberOfBags > 1 ? "s" : "") needed")
                    .font(.subheadline.bold())
            }
            
            Divider()
            
            Text(request.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 5) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                    Text("\(request.respondedDonors.count) responded")
                        .font(.caption)
                }
                .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}
