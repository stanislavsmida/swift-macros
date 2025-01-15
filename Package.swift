// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-macros",
    platforms: [.macOS(.v14), .iOS(.v15), .tvOS(.v15), .watchOS(.v8), .macCatalyst(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftMacros",
            targets: ["SwiftMacros"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/stansmida/swift-extras.git", from: "0.7.5"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/stansmida/swift-syntax-extras.git", from: "0.6.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "MacrosImplementation",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftExtras", package: "swift-extras"),
                .product(name: "SwiftSyntaxExtras", package: "swift-syntax-extras"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(
            name: "SwiftMacros",
            dependencies: [
                "MacrosImplementation",
                .product(name: "SwiftSyntaxExtras", package: "swift-syntax-extras"),
            ],
            path: "Sources/Macros"
        ),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "MacrosTests",
            dependencies: [
                "SwiftMacros",
                "MacrosImplementation",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
