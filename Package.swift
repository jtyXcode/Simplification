// swift-tools-version: 5.7

import PackageDescription

// Swift 5 toolchains select Swift 5; Swift 6 toolchains select strict Swift 6.
#if compiler(>=6.0)
let supportedSwiftVersions: [SwiftVersion] = [.v5, .version("6")]
#else
let supportedSwiftVersions: [SwiftVersion] = [.v5]
#endif

let package = Package(
    name: "Simplification",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [.library(name: "Simplification", targets: ["Simplification"])],
    targets: [
        .target(name: "Simplification"),
        .testTarget(name: "SimplificationTests", dependencies: ["Simplification"])
    ],
    swiftLanguageVersions: supportedSwiftVersions
)
