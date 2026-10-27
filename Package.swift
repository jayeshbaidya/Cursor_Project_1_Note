// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Note",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Note", targets: ["Note"])
    ],
    targets: [
        .executableTarget(
            name: "Note"
        )
    ]
)
