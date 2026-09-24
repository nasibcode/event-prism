import SwiftUI

@main
struct EventPrismDemoApp: App {
    @State private var session = DemoSession()

    var body: some Scene {
        WindowGroup {
            ContentView(session: session)
        }
    }
}
