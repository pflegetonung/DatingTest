import SwiftUI
import Adapty

@main
struct DatingApp: App {
    init() {
        Adapty.activate(AdaptyConfiguration.getAPIKey())
        
        #if DEBUG
        print("Adapty initialized in testing mode: \(AdaptyConfiguration.isTestingMode)")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
