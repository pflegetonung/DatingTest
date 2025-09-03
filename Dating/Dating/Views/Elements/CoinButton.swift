import SwiftUI

struct CoinButton: View {
    var body: some View {
        Button {
            withAnimation {
                
            }
        } label: {
            HStack(spacing: 6) {
                Text("78")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Image("coin")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
            }
        }
        .padding(4)
        .padding(.leading, 8)
        .background(Capsule().foregroundColor(Color(.systemGray3)))
    }
}
