import SwiftUI

struct LiveView: View {
    var body: some View {
        Text("*Live View*")
    }
}

struct ChatView: View {
    var body: some View {
        Text("*Chat View*")
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("*Profile View*")
                    .font(.title2)
                    .padding()
                
                NavigationLink("Test Premium Features") {
                    PremiumTestView()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .navigationTitle("Profile")
        }
    }
}

struct TermsView: View {
    var body: some View {
        Text("*Terms of Use View*")
    }
}

struct PrivacyView: View {
    var body: some View {
        Text("*Privacy Policy View*")
    }
}

