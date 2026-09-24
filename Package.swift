// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "DeskCrow",
  platforms: [.macOS(.v14)],
  targets: [
    .executableTarget(
      name: "DeskCrow",
      path: "Sources/DeskCrow"
    ),
  ]
)
