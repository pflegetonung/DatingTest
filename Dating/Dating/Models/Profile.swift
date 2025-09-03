import Foundation
import SwiftUI

struct Profile: Identifiable, Codable {
    let id: String
    let name: String
    let age: Int
    let imageURL: String
    let isOnline: Bool
    let country: String
    let lastSeen: Date?
    let onlineStatus: String?
    
    var onlineState: OnlineState {
        if let status = onlineStatus?.lowercased() {
            switch status {
            case "online": return .online
            case "offline": return .offline
            case "recently": return .recently
            default: return .offline
            }
        }
        return isOnline ? .online : .offline
    }
}

enum OnlineState: String, CaseIterable {
    case online = "online"
    case offline = "offline"
    case recently = "recently"
    
    var dotColor: Color {
        switch self {
        case .online: return .green
        case .offline: return Color(.systemGray3)
        case .recently: return .yellow
        }
    }
    
    var displayText: String {
        return self.rawValue
    }
}
    
enum CodingKeys: String, CodingKey {
    case id
    case name
    case age
    case imageURL = "image_url"
    case isOnline = "is_online"
    case country
    case lastSeen = "last_seen"
    case onlineStatus = "online_status"
}

struct ProfileResponse: Codable {
    let profiles: [Profile]
    let total: Int
    let page: Int
    let limit: Int
}
