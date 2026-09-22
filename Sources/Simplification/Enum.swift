//
//  Enum.swift
//  Simplification
//
//  Created by 007 on 2026/9/22.
//


/// Controls when an instance is created and how long the container retains it.
public enum LifeCycle: Sendable {
    /// Create immediately and retain until registration is replaced.
    case singleton
    /// Create on first resolution and retain until registration is replaced.
    case lazySingleton
    /// Reuse a reference instance while another owner retains it; otherwise rebuild.
    /// Value types are retained like lazy singletons.
    case autoRelease
    /// Create a new instance on every resolution.
    case transient
}
