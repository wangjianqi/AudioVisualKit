// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AudioVisualKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AudioVisualKit", targets: ["AudioVisualKit"])],
    targets: [
        .target(name: "AudioVisualKit"),
        .testTarget(name: "AudioVisualKitTests", dependencies: ["AudioVisualKit"])
    ]
)
