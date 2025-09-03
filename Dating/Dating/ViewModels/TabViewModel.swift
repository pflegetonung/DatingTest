import SwiftUI
import Combine

final class TabViewModel: ObservableObject {
    @Published var selected: Tab = .feed
    
    func select(_ tab: Tab) {
        guard tab != selected else { return }
        selected = tab
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}
