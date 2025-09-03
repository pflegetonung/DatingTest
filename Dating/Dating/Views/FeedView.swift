import SwiftUI

enum ProfileFilter: String, CaseIterable {
    case online = "Online"
    case popular = "Popular"
    case new = "New"
    case following = "Following"
}

struct FeedView: View {
    @StateObject private var profileService = ProfileService()
    @State private var showingPaywall = false
    @State private var activeFilters: Set<ProfileFilter> = []
    @ObservedObject private var adaptyService = AdaptyService.shared
    
    private var filteredProfiles: [Profile] {
        if activeFilters.isEmpty {
            return profileService.profiles
        }
        
        return profileService.profiles.filter { profile in
            activeFilters.allSatisfy { filter in
                switch filter {
                case .online:
                    return profile.onlineState == .online
                case .popular:
                    return true
                case .new:
                    return true
                case .following:
                    return true
                }
            }
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                HStack {
                    HStack(spacing: 8) {
                        Text("Feed")
                            .font(.system(size: 20, weight: .heavy))
                        
                        if adaptyService.isPremiumUser {
                            Text("Premium")
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(.cpurple)
                                .transition(.scale.combined(with: .opacity))
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: adaptyService.isPremiumUser)
                        }
                    }
                    
                    Spacer()
                    
                    CoinButton()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(ProfileFilter.allCases, id: \.self) { filter in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if activeFilters.contains(filter) {
                                        activeFilters.remove(filter)
                                    } else {
                                        activeFilters.insert(filter)
                                    }
                                }
                            } label: {
                                Text(filter.rawValue)
                                    .font(.system(size: 18, weight: activeFilters.contains(filter) ? .heavy : .medium))
                                    .foregroundColor(activeFilters.contains(filter) ? .black : .gray)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(activeFilters.contains(filter) ? Color(.systemGray6) : Color.clear)
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, -16)
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    if profileService.isLoading || profileService.profiles.isEmpty {
                        ForEach(0..<6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray3))
                                .aspectRatio(2.0/3.0, contentMode: .fit)
                        }
                    } else {
                        ForEach(filteredProfiles) { profile in
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray3))
                                
                                GeometryReader { proxy in
                                    AsyncImage(url: URL(string: profile.imageURL)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: proxy.size.width, height: proxy.size.height)
                                        case .failure(_):
                                            Color.clear
                                        case .empty:
                                            Color.clear
                                        @unknown default:
                                            Color.clear
                                        }
                                    }
                                }
                                
                                VStack {
                                    HStack {
                                        HStack(spacing: 4) {
                                            Circle()
                                                .foregroundColor(profile.onlineState.dotColor)
                                                .frame(height: 8)
                                            
                                            Text(profile.onlineState.displayText)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 2)
                                        .padding(4)
                                        .background(Capsule().foregroundColor(.black.opacity(0.55)))
                                        
                                        Spacer()
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(spacing: 12) {
                                        HStack {
                                            Image("flag")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 14)
                                            
                                            Text("\(profile.name), \(profile.age)")
                                                .font(.system(size: 15, weight: .heavy))
                                                .foregroundColor(.white)
                                        }
                                        
                                        HStack(spacing: 22) {
                                            Button {
                                                showingPaywall = true
                                            } label: {
                                                Image("chatbutton")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 21)
                                            }
                                            
                                            Button {
                                                showingPaywall = true
                                            } label: {
                                                Image("livebutton")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 32)
                                            }
                                            
                                            Button {
                                                showingPaywall = true
                                            } label: {
                                                Image("likebutton")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 21)
                                            }
                                        }
                                    }
                                    .shadow(radius: 12)
                                    .padding(.bottom, 6)
                                }
                                .padding(8)
                            }
                            .aspectRatio(2.0/3.0, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .contentShape(Rectangle())
                            .onTapGesture { showingPaywall = true }
                            .onAppear {
                                if profile.id == filteredProfiles.last?.id {
                                    Task { await profileService.fetchNextPageIfPossible() }
                                }
                            }
                        }
                        if profileService.isLoadingNextPage {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .gridCellColumns(2)
                        }
                    }
                }
                
                if let error = profileService.error {
                    Text(error)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding()
            .fullScreenCover(isPresented: $showingPaywall) {
                PaywallView()
            }
            .task {
                await profileService.resetAndLoadFirstPage(limit: 20)
            }
        }
    }
}
