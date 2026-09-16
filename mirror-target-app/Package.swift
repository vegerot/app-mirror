// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MirrorTarget",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MirrorTarget",
            path: "Sources/MirrorTarget"
        )
    ]
)
