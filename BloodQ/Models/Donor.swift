//
//  Donor.swift
//  BloodQ
//
//

import Foundation
import FirebaseFirestore
import CoreLocation

// Donor Model
struct Donor: Identifiable, Codable {
    var id: String
    var userId: String
    var name: String
    var email: String
    var mobile: String
    var district: String
    var upazilla: String
    var bloodGroup: String
    var lastDonationDate: String
    var donationHistory: [DonationRecord]
    var totalDonations: Int
    var isVerified: Bool
    var nidNumber: String?
    var profileImageURL: String?
    var fcmToken: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString,
         userId: String,
         name: String,
         email: String,
         mobile: String,
         district: String,
         upazilla: String,
         bloodGroup: String,
         lastDonationDate: String = "",
         donationHistory: [DonationRecord] = [],
         totalDonations: Int = 0,
         isVerified: Bool = false,
         nidNumber: String? = nil,
         profileImageURL: String? = nil,
         fcmToken: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.name = name
        self.email = email
        self.mobile = mobile
        self.district = district
        self.upazilla = upazilla
        self.bloodGroup = bloodGroup
        self.lastDonationDate = lastDonationDate
        self.donationHistory = donationHistory
        self.totalDonations = totalDonations
        self.isVerified = isVerified
        self.nidNumber = nidNumber
        self.profileImageURL = profileImageURL
        self.fcmToken = fcmToken
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var canDonate: Bool {
        guard !lastDonationDate.isEmpty else { return true }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let lastDate = dateFormatter.date(from: lastDonationDate) else { return true }
        let daysSinceLastDonation = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSinceLastDonation >= 90
    }
    
    var nextEligibleDate: Date? {
        guard !lastDonationDate.isEmpty else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let lastDate = dateFormatter.date(from: lastDonationDate) else { return nil }
        return Calendar.current.date(byAdding: .day, value: 90, to: lastDate)
    }
}

//Donation Record
struct DonationRecord: Identifiable, Codable {
    var id: String
    var date: Date
    var location: String
    var notes: String?
    
    init(id: String = UUID().uuidString,
         date: Date,
         location: String,
         notes: String? = nil) {
        self.id = id
        self.date = date
        self.location = location
        self.notes = notes
    }
}

//Blood Request
struct BloodRequest: Identifiable, Codable {
    var id: String
    var requesterId: String
    var requesterName: String
    var requesterPhone: String
    var bloodGroup: String
    var numberOfBags: Int
    var urgency: RequestUrgency
    var location: GeoLocation
    var locationName: String
    var district: String
    var upazilla: String
    var hospitalName: String?
    var description: String
    var status: RequestStatus
    var createdAt: Date
    var expiresAt: Date
    var respondedDonors: [String]
    
    init(id: String = UUID().uuidString,
         requesterId: String,
         requesterName: String,
         requesterPhone: String,
         bloodGroup: String,
         numberOfBags: Int,
         urgency: RequestUrgency,
         location: GeoLocation,
         locationName: String,
         district: String,
         upazilla: String,
         hospitalName: String? = nil,
         description: String,
         status: RequestStatus = .active,
         createdAt: Date = Date(),
         expiresAt: Date = Date().addingTimeInterval(48 * 3600),
         respondedDonors: [String] = []) {
        self.id = id
        self.requesterId = requesterId
        self.requesterName = requesterName
        self.requesterPhone = requesterPhone
        self.bloodGroup = bloodGroup
        self.numberOfBags = numberOfBags
        self.urgency = urgency
        self.location = location
        self.locationName = locationName
        self.district = district
        self.upazilla = upazilla
        self.hospitalName = hospitalName
        self.description = description
        self.status = status
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.respondedDonors = respondedDonors
    }
}

enum RequestUrgency: String, Codable, CaseIterable {
    case critical = "Critical"
    case urgent = "Urgent"
    case normal = "Normal"
    
    var color: String {
        switch self {
        case .critical: return "red"
        case .urgent: return "orange"
        case .normal: return "blue"
        }
    }
}

enum RequestStatus: String, Codable {
    case active = "Active"
    case fulfilled = "Fulfilled"
    case expired = "Expired"
    case cancelled = "Cancelled"
}

//  GeoLocation
struct GeoLocation: Codable {
    var latitude: Double
    var longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    func distance(to other: GeoLocation) -> Double {
        let from = CLLocation(latitude: latitude, longitude: longitude)
        let to = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return from.distance(from: to) / 1000 // Convert to kilometers
    }
}

// Chat Message
struct ChatMessage: Identifiable, Codable {
    var id: String
    var chatId: String
    var senderId: String
    var senderName: String
    var text: String
    var timestamp: Date
    var isRead: Bool
    
    init(id: String = UUID().uuidString,
         chatId: String,
         senderId: String,
         senderName: String,
         text: String,
         timestamp: Date = Date(),
         isRead: Bool = false) {
        self.id = id
        self.chatId = chatId
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.timestamp = timestamp
        self.isRead = isRead
    }
}

// Chat Conversation
struct ChatConversation: Identifiable, Codable {
    var id: String
    var requestId: String
    var participantIds: [String]
    var participantNames: [String: String]
    var lastMessage: String
    var lastMessageTime: Date
    var unreadCount: [String: Int]
    
    init(id: String = UUID().uuidString,
         requestId: String,
         participantIds: [String],
         participantNames: [String: String],
         lastMessage: String = "",
         lastMessageTime: Date = Date(),
         unreadCount: [String: Int] = [:]) {
        self.id = id
        self.requestId = requestId
        self.participantIds = participantIds
        self.participantNames = participantNames
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.unreadCount = unreadCount
    }
}

// Area Data Models
struct AreaData: Codable {
    let districts: [District]
}

struct District: Codable, Identifiable {
    var id: String { name }
    let name: String
    let upazillas: [String]
}

// Leaderboard Entry
struct LeaderboardEntry: Identifiable {
    var id: String { userId }
    let userId: String
    let name: String
    let bloodGroup: String
    let totalDonations: Int
    let profileImageURL: String?
    let rank: Int
}


