// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Winkle",
    defaultLocalization: "fr",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Winkle",
            path: "Sources/Winkle"
        )
    ]
)
