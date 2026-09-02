// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RokidLink",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "RokidLink", targets: ["RokidLink"])
    ],
    targets: [
        .target(name: "RokidLink"),
        .testTarget(name: "RokidLinkTests", dependencies: ["RokidLink"])
    ]
)
