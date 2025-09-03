import Foundation
import Adapty
import Combine

@MainActor
class AdaptyService: ObservableObject {
    @Published var isPremiumUser = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var availableProducts: [AdaptyPaywallProduct] = []
    @Published var currentPaywall: AdaptyPaywall?
    
    static let shared = AdaptyService()
    
    private init() {
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    func checkSubscriptionStatus() async {
        do {
            let profile = try await Adapty.getProfile()
            isPremiumUser = profile.accessLevels["premium"]?.isActive == true
        } catch {
            print("Failed to get profile: \(error)")
            errorMessage = "Failed to check subscription status"
        }
    }
    
    func loadPaywall() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let paywall = try await Adapty.getPaywall(placementId: "dating_premium", locale: "en")
            currentPaywall = paywall
            
            let paywallProducts = try await Adapty.getPaywallProducts(paywall: paywall)
            availableProducts = paywallProducts
        } catch {
            print("Failed to load paywall: \(error)")
            errorMessage = "Failed to load products"
            
            await createMockProducts()
        }
        
        isLoading = false
    }
    
    private func createMockProducts() async {
        print("Using mock products for testing")
        availableProducts = []
    }
    
    func purchaseProduct(_ product: AdaptyPaywallProduct) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Adapty.makePurchase(product: product)
            
            let profile = try await Adapty.getProfile()
            let hasPremiumAccess = profile.accessLevels["premium"]?.isActive == true
            
            if hasPremiumAccess {
                isPremiumUser = true
                isLoading = false
                return true
            } else {
                errorMessage = "Purchase was not successful"
                isLoading = false
                return false
            }
            
        } catch {
            print("Purchase failed: \(error)")
            
            let errorDescription = error.localizedDescription.lowercased()
            if errorDescription.contains("cancel") || errorDescription.contains("abort") {
                print("Payment was cancelled by user")
                errorMessage = nil
            } else {
                errorMessage = "Purchase failed. Please try again."
            }
            
            isLoading = false
            return false
        }
    }
    
    func mockPurchase() async -> Bool {
        print("Starting mock purchase...")
        isLoading = true
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        isPremiumUser = true
        isLoading = false
        
        print("Mock purchase successful - user is now premium: \(isPremiumUser)")
        return true
    }
    
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await Adapty.restorePurchases()
            
            let profile = try await Adapty.getProfile()
            isPremiumUser = profile.accessLevels["premium"]?.isActive == true
            
            isLoading = false
            return isPremiumUser
            
        } catch {
            print("Restore failed: \(error)")
            errorMessage = "Failed to restore purchases"
            isLoading = false
            return false
        }
    }
    
    func mockRestore() async -> Bool {
        isLoading = true
        
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        let hasRestoredPurchase = Bool.random()
        
        if hasRestoredPurchase {
            isPremiumUser = true
            print("Mock restore successful - user premium status restored")
        } else {
            errorMessage = "No previous purchases found"
        }
        
        isLoading = false
        return hasRestoredPurchase
    }
    
    func logout() {
        print("Logging out - resetting premium status...")
        isPremiumUser = false
        availableProducts = []
        errorMessage = nil
        print("User is now free: \(isPremiumUser)")
    }
}
