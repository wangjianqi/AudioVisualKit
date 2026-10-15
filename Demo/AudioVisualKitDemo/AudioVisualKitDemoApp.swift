import SwiftUI

@main
struct AudioVisualKitDemoApp: App {
    var body: some Scene {
        WindowGroup {
            DemoHomeView()
                .preferredColorScheme(.dark)
        }
    }
}
