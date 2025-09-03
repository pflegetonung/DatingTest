import SwiftUI

struct PremiumTestView: View {
    @ObservedObject private var adaptyService = AdaptyService.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Premium Status Test")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Current Status: \(adaptyService.isPremiumUser ? "Premium ✅" : "Free ❌")")
                .font(.headline)
                .foregroundColor(adaptyService.isPremiumUser ? .green : .red)
                .onChange(of: adaptyService.isPremiumUser) { newValue in
                    print("🔄 Premium status changed to: \(newValue)")
                }
            
            VStack(spacing: 12) {
                Button("Activate Premium (Mock)") {
                    Task {
                        _ = await adaptyService.mockPurchase()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(adaptyService.isLoading)
                
                Button("Reset to Free") {
                    adaptyService.logout()
                }
                .buttonStyle(.bordered)
                .disabled(adaptyService.isLoading)
            }
            
            if adaptyService.isLoading {
                ProgressView("Processing...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            Text("Check the Feed tab to see 'Premium' text when active")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    PremiumTestView()
}
