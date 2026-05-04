// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "OpenRouterSwift",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
  ],
  products: [
    .library(
      name: "OpenRouter",
      targets: ["OpenRouter"]
    )
  ],
  targets: [
    .target(
      name: "OpenRouter"
    ),
    .executableTarget(
      name: "OpenRouterExamples",
      dependencies: ["OpenRouter"]
    ),
    .testTarget(
      name: "OpenRouterTests",
      dependencies: ["OpenRouter"],
      resources: [
        .process("Fixtures")
      ]
    ),
  ]
)
