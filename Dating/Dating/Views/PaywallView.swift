import SwiftUI
import StoreKit
import Adapty

struct PaywallView: View {
    @State private var currentPage = 0
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @Environment(\.dismiss) private var dismiss
    
    // Adapty integration
    @ObservedObject private var adaptyService = AdaptyService.shared
    @State private var purchaseState: PurchaseState = .idle
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let pageData = [
        ("Get 599 coins NOW and\nEvery Week", "pw1"),
        ("Send Unlimited messages", "pw2"),
        ("turn off camera & sound", "pw3"),
        ("Mark your profile with\nVIP status", "pw4")
    ]
    
    var body: some View {
        VStack(spacing: 22) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                }
                
                Spacer()
                
                Button {
                    Task {
                        await handleRestore()
                    }
                } label: {
                    if purchaseState.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Restore")
                            .font(.system(size: 16, weight: .regular))
                    }
                }
                .disabled(purchaseState.isLoading)
            }
            .foregroundColor(Color(.systemGray3))
            
            TabView(selection: $currentPage) {
                ForEach(0..<4, id: \.self) { index in
                    VStack(spacing: 16) {
                        Text(pageData[index].0)
                            .foregroundColor(.black)
                            .font(.system(size: 24, weight: .heavy))
                            .multilineTextAlignment(.center)
                            .frame(height: 64)
                        
                        Image(pageData[index].1)
                            .resizable()
                            .scaledToFit()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .padding(.horizontal, -16)
            
            HStack {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .frame(height: 6)
                        .foregroundColor(index == currentPage ? .cpurple : Color(.systemGray3))
                }
            }
            
            ZStack {
                Image("pwbg")
                    .resizable()
                    .scaledToFit()
                    .padding(-16)
                    .padding(.bottom, -47)
                
                VStack(spacing: 6) {
                    Text("Subscribe for $0.99 weekly")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Plan automatically renews. Cancel anytime.")
                        .font(.system(size: 13, weight: .regular))
                    
                    Button {
                        Task {
                            await handlePurchase()
                        }
                    } label: {
                        ZStack {
                            LinearGradient(colors: [.ccyan1, .ccyan2], startPoint: .top, endPoint: .bottom)
                                .frame(height: 48)
                                .clipShape(Capsule())
                            
                            HStack {
                                if purchaseState.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Processing...")
                                        .font(.system(size: 18, weight: .semibold))
                                } else {
                                    Text("Subscribe")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                        }
                    }
                    .disabled(purchaseState.isLoading)
                    .padding(.vertical, 12)
                    
                    HStack {
                        Button {
                            showingTerms = true
                        } label: {
                            Text("Terms of Use")
                                .font(.system(size: 13, weight: .regular))
                                .underline()
                        }
                        
                        Spacer()
                        
                        Button {
                            showingPrivacy = true
                        } label: {
                            Text("Privacy & Policy")
                                .font(.system(size: 13, weight: .regular))
                                .underline()
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .foregroundColor(.white)
                .padding(.horizontal)
            }
        }
        .padding()
        .sheet(isPresented: $showingTerms) {
            TermsView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyView()
        }
        .alert("Subscription", isPresented: $showingAlert) {
            Button("OK") {
                showingAlert = false
                if case .success = purchaseState {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .task {
            await adaptyService.loadPaywall()
        }
    }
    
    private func handlePurchase() async {
        purchaseState = .loading
        
        let success = await adaptyService.mockPurchase()
        
        if success {
            purchaseState = .success
            alertMessage = "Premium subscription activated! Enjoy unlimited access to all features."
        } else {
            purchaseState = .failed("Purchase failed")
            alertMessage = adaptyService.errorMessage ?? "Something went wrong. Please try again."
        }
        
        showingAlert = true
    }
    
    private func handleRestore() async {
        purchaseState = .loading
        
        let success = await adaptyService.mockRestore()
        
        if success {
            purchaseState = .success
            alertMessage = "Subscription restored successfully! You now have premium access."
        } else {
            purchaseState = .failed("Restore failed")
            alertMessage = adaptyService.errorMessage ?? "No previous purchases found."
        }
        
        showingAlert = true
    }
}

#Preview {
    PaywallView()
}
