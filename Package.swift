// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AppMirror",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "AppMirror",
            path: "Sources/AppMirror"
        ),
        .testTarget(name: "AppMirrorTests", dependencies: ["AppMirror"])
    ]
)
