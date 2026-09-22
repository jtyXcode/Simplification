//
//  Wrapper.swift
//  Simplification
//
//  Created by 007 on 2026/9/22.
//

/// Resolves on each access, preserving the registered lifecycle.
@MainActor
@propertyWrapper
public struct Injected<T> {

    private let container: Simplification

    public init() {
        self.container = .shared
    }

    public init(container: Simplification) {
        self.container = container
    }

    public var wrappedValue: T { container.resolve() }
}

#if canImport(SwiftUI)
import SwiftUI

/// Observes the resolved object. Its lifetime follows the owning SwiftUI view.
@MainActor
@propertyWrapper
public struct InjectedObject<T: ObservableObject>: DynamicProperty {
    @ObservedObject private var object: T

    public init() {
        self._object = ObservedObject(wrappedValue: Simplification.shared.resolve())
    }

    public init(container: Simplification) {
        self._object = ObservedObject(wrappedValue: container.resolve())
    }
    
    public var wrappedValue: T { object }

    public var projectedValue: ObservedObject<T>.Wrapper { $object }
}
#endif
