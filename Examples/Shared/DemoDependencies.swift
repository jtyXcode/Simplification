import Combine
import Foundation
import Simplification

@MainActor
protocol GreetingProviding: AnyObject {
    func greeting(for name: String) -> String
}

@MainActor
final class GreetingService: GreetingProviding {
    func greeting(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return "你好，\(trimmed.isEmpty ? "朋友" : trimmed)"
    }
}

@MainActor
final class CounterStore: ObservableObject {
    @Published var name = "Simplification"
    @Published private(set) var count = 0
    let instanceID = UUID().uuidString.prefix(8)
    private let greetings: any GreetingProviding

    init(greetings: any GreetingProviding) {
        self.greetings = greetings
    }

    var greeting: String { greetings.greeting(for: name) }
    func increment() { count += 1 }
    func reset() { count = 0 }
}

@MainActor
enum DemoDependencies {
    /// Call once at startup, before constructing views or controllers.
    static func register() {
        let container = Simplification.shared
        // Register a protocol, then resolve it inside another dependency's factory.
        container.register((any GreetingProviding).self, lifeCycle: .singleton) {
            GreetingService()
        }
        // Both pages retain the same state, including across view reconstruction.
        container.register(CounterStore.self, lifeCycle: .lazySingleton) {
            CounterStore(greetings: container.resolve((any GreetingProviding).self))
        }
    }
}
