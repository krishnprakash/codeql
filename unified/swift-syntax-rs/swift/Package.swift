// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SwiftSyntaxFFI",
    products: [
        // Dynamic library so the produced .so records its dependency on the
        // Swift runtime libraries, keeping the Rust link step simple.
        .library(
            name: "SwiftSyntaxFFI",
            type: .dynamic,
            targets: ["SwiftSyntaxFFI"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            exact: "602.0.0"
        )
    ],
    targets: [
        .target(
            name: "SwiftSyntaxFFI",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        )
    ]
)
