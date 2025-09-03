import SwiftUI

struct ContentView: View {
    @StateObject private var vm = TabViewModel()
    @ObservedObject private var adaptyService = AdaptyService.shared
    
    var body: some View {
        ZStack {
            Group {
                switch vm.selected {
                case .live: LiveView()
                case .feed: FeedView()
                case .chat: ChatView()
                case .profile: ProfileView()
                }
            }
            .transition(.opacity.combined(with: .scale))
            .padding(.bottom, 55)
            
            VStack {
                Spacer()
                
                CustomTabBar(viewModel: vm)
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}

struct CustomTabBarItemView: View {
    let tab: Tab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(tab.image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 28)
                
                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? Color.primary : Color.secondary)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct CustomTabBar: View {
    @ObservedObject var viewModel: TabViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                CustomTabBarItemView(
                    tab: tab,
                    isSelected: viewModel.selected == tab,
                    action: { viewModel.select(tab) }
                )
            }

        }
        .padding(.bottom, 29)
        .padding(.horizontal, 12)
        .background(
            VStack(spacing: 0) {
                Color(.systemGray6)
                    .frame(height: 1)
                
                Color.white
            }
        )
        .clipShape(Rectangle())
        .padding(.top, 8)
    }
}
