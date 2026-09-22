import SwiftUI

@main
@MainActor
struct SwiftUIDemoApp: App {
    init() {
        // Registration precedes ContentView's property-wrapper initialization.
        DemoDependencies.register()
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
