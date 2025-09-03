import Foundation
import Adapty

enum SubscriptionType: String, CaseIterable {
    case weekly = "dating_premium_weekly"
    case monthly = "dating_premium_monthly"
    case yearly = "dating_premium_yearly"
    
    var displayName: String {
        switch self {
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }
    
    var price: String {
        switch self {
        case .weekly:
            return "$0.99"
        case .monthly:
            return "$9.99"
        case .yearly:
            return "$99.99"
        }
    }
    
    var description: String {
        switch self {
        case .weekly:
            return "Subscribe for $0.99 weekly"
        case .monthly:
            return "Subscribe for $9.99 monthly"
        case .yearly:
            return "Subscribe for $99.99 yearly"
        }
    }
    
    var recurringDescription: String {
        switch self {
        case .weekly:
            return "Plan automatically renews weekly. Cancel anytime."
        case .monthly:
            return "Plan automatically renews monthly. Cancel anytime."
        case .yearly:
            return "Plan automatically renews yearly. Cancel anytime."
        }
    }
}

struct PremiumFeature {
    let title: String
    let imageName: String
}

extension PremiumFeature {
    static let features: [PremiumFeature] = [
        PremiumFeature(title: "Get 599 coins NOW and\nEvery Week", imageName: "pw1"),
        PremiumFeature(title: "Send Unlimited messages", imageName: "pw2"),
        PremiumFeature(title: "turn off camera & sound", imageName: "pw3"),
        PremiumFeature(title: "Mark your profile with\nVIP status", imageName: "pw4")
    ]
}

enum PurchaseState {
    case idle
    case loading
    case success
    case failed(String)
    case cancelled
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .failed(let message) = self {
            return message
        }
        return nil
    }
}

struct SubscriptionStatus {
    let isActive: Bool
    let subscriptionType: SubscriptionType?
    let expiresAt: Date?
    let isLifetime: Bool
    
    static let inactive = SubscriptionStatus(
        isActive: false,
        subscriptionType: nil,
        expiresAt: nil,
        isLifetime: false
    )
}

extension AdaptyPaywallProduct {
    var subscriptionType: SubscriptionType? {
        return SubscriptionType(rawValue: vendorProductId)
    }
    
    var displayPrice: String {
        return localizedPrice ?? subscriptionType?.price ?? "N/A"
    }
    
    var displayDescription: String {
        return subscriptionType?.description ?? "Premium Subscription"
    }
}

struct MockProduct {
    let id: String
    let price: String
    let description: String
    let type: SubscriptionType
    
    static let weeklyProduct = MockProduct(
        id: "dating_premium_weekly",
        price: "$0.99",
        description: "Subscribe for $0.99 weekly",
        type: .weekly
    )
    
    static let monthlyProduct = MockProduct(
        id: "dating_premium_monthly",
        price: "$9.99",
        description: "Subscribe for $9.99 monthly",
        type: .monthly
    )
    
    static let yearlyProduct = MockProduct(
        id: "dating_premium_yearly",
        price: "$99.99",
        description: "Subscribe for $99.99 yearly",
        type: .yearly
    )
    
    static let allProducts = [weeklyProduct, monthlyProduct, yearlyProduct]
}
