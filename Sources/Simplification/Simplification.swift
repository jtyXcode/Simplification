//
//  Simplification.swift
//  Simplification
//
//  Created by 007 on 2026/9/22.
//

@MainActor
public final class Simplification {
    public static let shared = Simplification()

    private final class Registration {
        let lifeCycle: LifeCycle
        let factory: @MainActor () -> Any
        var strongValue: Any?
        var weakValue: WeakBox?
        var isResolving = false

        init(lifeCycle: LifeCycle, factory: @escaping @MainActor () -> Any) {
            self.lifeCycle = lifeCycle
            self.factory = factory
        }
    }

    private var registrations: [ObjectIdentifier: Registration] = [:]

    /// Creates an independent container, useful for tests and scoped dependencies.
    public init() {}

    public func register<T>(
        _ type: T.Type,
        lifeCycle: LifeCycle = .autoRelease,
        factory: @escaping @MainActor () -> T
    ) {
        let key = ObjectIdentifier(type)
        precondition(
            registrations[key]?.isResolving != true,
            "[Simplification] Cannot replace \(type) while its factory is executing"
        )
        registrations[key] = Registration(lifeCycle: lifeCycle, factory: factory)
        if lifeCycle == .singleton {
            let _: T = resolve(type)
        }
    }

    public func lazyPut<T>(
        _ factory: @escaping @MainActor () -> T,
        autoRelease: Bool = true
    ) {
        register(T.self, lifeCycle: autoRelease ? .autoRelease : .lazySingleton, factory: factory)
    }

    public func resolve<T>(_ type: T.Type = T.self) -> T {
        guard let registration = registrations[ObjectIdentifier(type)] else {
            preconditionFailure("[Simplification] Unregistered type: \(type)")
        }
        if let instance = registration.strongValue {
            return cast(instance, to: type)
        }
        if let instance = registration.weakValue?.value {
            return cast(instance, to: type)
        }
        precondition(!registration.isResolving, "[Simplification] Circular dependency resolving \(type)")
        registration.isResolving = true
        defer { registration.isResolving = false }

        let instance = registration.factory()
        switch registration.lifeCycle {
        case .singleton, .lazySingleton:
            registration.strongValue = instance
        case .autoRelease:
            // Inspect the dynamic type before bridging: every Swift value can bridge to AnyObject.
            if Swift.type(of: instance) is AnyClass {
                registration.weakValue = WeakBox(value: instance as AnyObject)
            } else {
                registration.strongValue = instance
            }
        case .transient:
            break
        }
        return cast(instance, to: type)
    }

    private func cast<T>(_ instance: Any, to type: T.Type) -> T {
        guard let value = instance as? T else {
            preconditionFailure("[Simplification] Invalid instance for \(type)")
        }
        return value
    }
}
