// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SmartEMIOptimizer",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(
            name: "SmartEMIOptimizer",
            targets: ["SmartEMIOptimizer"]
        ),
    ],
    targets: [
        .target(
            name: "SmartEMIOptimizer",
            path: "Sources/SmartEMIOptimizer"
        ),
        .testTarget(
            name: "SmartEMIOptimizerTests",
            dependencies: ["SmartEMIOptimizer"],
            path: "Tests/SmartEMIOptimizerTests"
        ),
    ]
)
