import SwiftUI

enum Tab: CaseIterable, Hashable {
    case live, feed, chat, profile
    
    var title: String {
        switch self {
        case .live:    return "Live"
        case .feed:  return "Feed"
        case .chat: return "Chat"
        case .profile: return "Profile"
        }
    }
    
    var image: String {
        switch self {
        case .live:    return "live"
        case .feed:  return "feed"
        case .chat: return "chat"
        case .profile: return "profile"
        }
    }
}
