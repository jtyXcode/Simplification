import XCTest
import Simplification
#if canImport(SwiftUI)
import SwiftUI
#endif

private protocol Service: AnyObject {}
private final class Instance: Service {}
private final class WeakService {
    weak var value: (any Service)?
    init(_ value: any Service) { self.value = value }
}
private enum First { final class Duplicate {} }
private enum Second { final class Duplicate {} }

final class SimplificationTests: XCTestCase {
    @MainActor
    func testDefaultInjectedInitializer() async {
        @MainActor final class Consumer {
            @Injected var value: Int
        }
        Simplification.shared.register(Int.self) { 7 }
        XCTAssertEqual(Consumer().value, 7)
    }

    @MainActor
    func testBackgroundAccessHopsToMainActor() async {
        let container = Simplification()
        container.register(Int.self, lifeCycle: .singleton) { 42 }
        let value = await Task.detached { await container.resolve(Int.self) }.value
        XCTAssertTrue(value == 42)
    }

    @MainActor
    func testEagerSingleton() async {
        let container = Simplification()
        var calls = 0
        container.register(Instance.self, lifeCycle: .singleton) { calls += 1; return Instance() }
        XCTAssertTrue(calls == 1)
        XCTAssertTrue(container.resolve(Instance.self) === container.resolve(Instance.self))
        XCTAssertTrue(calls == 1)
    }

    @MainActor
    func testLazySingleton() async {
        let container = Simplification()
        var calls = 0
        container.lazyPut({ calls += 1; return Instance() }, autoRelease: false)
        XCTAssertTrue(calls == 0)
        XCTAssertTrue(container.resolve(Instance.self) === container.resolve(Instance.self))
        XCTAssertTrue(calls == 1)
    }

    @MainActor
    func testWeakProtocolRegistrationRebuildsAfterRelease() async {
        let container = Simplification()
        var calls = 0
        container.register((any Service).self) { calls += 1; return Instance() }
        var first: (any Service)? = container.resolve((any Service).self)
        let reference = WeakService(first!)
        XCTAssertTrue(first === container.resolve((any Service).self))
        XCTAssertTrue(calls == 1)
        first = nil
        XCTAssertTrue(reference.value == nil)
        let rebuilt: any Service = container.resolve()
        XCTAssertTrue(calls == 2)
        XCTAssertTrue(rebuilt === container.resolve((any Service).self))
    }

    @MainActor
    func testValueTypeIsRetained() async {
        struct Value { let number: Int }
        let container = Simplification()
        var calls = 0
        container.register(Value.self) { calls += 1; return Value(number: calls) }
        XCTAssertTrue(container.resolve(Value.self).number == 1)
        XCTAssertTrue(container.resolve(Value.self).number == 1)
        XCTAssertTrue(calls == 1)
    }

    @MainActor
    func testLifecycleReplacement() async {
        let container = Simplification()
        container.register(Instance.self, lifeCycle: .lazySingleton) { Instance() }
        let original: Instance = container.resolve()
        container.register(Instance.self, lifeCycle: .transient) { Instance() }
        let first: Instance = container.resolve()
        let second: Instance = container.resolve()
        XCTAssertTrue(first !== original)
        XCTAssertTrue(first !== second)
        container.register(Instance.self, lifeCycle: .singleton) { original }
        XCTAssertTrue(container.resolve(Instance.self) === original)
    }

    @MainActor
    func testNestedFactories() async {
        struct Parent { let child: Instance }
        let container = Simplification()
        container.register(Instance.self, lifeCycle: .lazySingleton) { Instance() }
        container.register(Parent.self) { Parent(child: container.resolve()) }
        XCTAssertTrue(container.resolve(Parent.self).child === container.resolve(Instance.self))
    }

    @MainActor
    func testSameNameTypesAreDistinct() async {
        let container = Simplification()
        container.register(First.Duplicate.self) { First.Duplicate() }
        container.register(Second.Duplicate.self) { Second.Duplicate() }
        let first: First.Duplicate = container.resolve()
        let second: Second.Duplicate = container.resolve()
        XCTAssertTrue(first === container.resolve(First.Duplicate.self))
        XCTAssertTrue(second === container.resolve(Second.Duplicate.self))
    }

    @MainActor
    func testInjectedUsesSelectedContainerAndLifecycle() async {
        let container = Simplification()
        container.register(Instance.self, lifeCycle: .transient) { Instance() }
        let wrapper = Injected<Instance>(container: container)
        XCTAssertTrue(wrapper.wrappedValue !== wrapper.wrappedValue)
    }

    #if canImport(SwiftUI)
    @MainActor private final class Model: ObservableObject { @Published var value = 0 }

    @MainActor
    func testDefaultObservableInitializer() async {
        @MainActor struct Consumer {
            @InjectedObject var model: Model
        }
        Simplification.shared.register(Model.self) { Model() }
        let consumer = Consumer()
        XCTAssertTrue(consumer.model === Simplification.shared.resolve(Model.self))
    }

    @MainActor
    func testObservableInjectionAndBinding() async {
        let container = Simplification()
        container.register(Model.self) { Model() }
        let wrapper = InjectedObject<Model>(container: container)
        XCTAssertTrue(wrapper.wrappedValue === container.resolve(Model.self))
        wrapper.projectedValue.value.wrappedValue = 42
        XCTAssertTrue(wrapper.wrappedValue.value == 42)
    }
    #endif
}
