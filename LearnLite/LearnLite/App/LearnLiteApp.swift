import SwiftUI

@main
struct LearnLiteApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
