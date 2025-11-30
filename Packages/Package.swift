// swift-tools-version:6.0

import PackageDescription

let package = Package(
  name: "Packages",
  platforms: [.iOS(.v18), .macOS(.v15)],
  products: [
    .library(name: "AudioUnitHost", targets: ["AudioUnitHost"]),
    .library(name: "AUv3s", targets: ["AUv3s"]),
    .library(name: "Presets", targets: ["Presets"]),
    .library(name: "Root", targets: ["Root"]),
    .library(name: "Support", targets: ["Support"])
  ],
  dependencies: [
    .package(url: "https://github.com/bradhowes/auv3-support", branch: "main"),
    .package(url: "https://github.com/bradhowes/typedfullstate", branch: "main"),
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.22.3"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.10.0"),
    .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.7.4"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.7"),
  ],
  targets: [
    .target(name: "AUv3s",
            dependencies: [
              "Support",
              .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
              .product(name: "TypedFullState", package: "TypedFullState")
            ]
           ),
    .target(name: "Presets",
            dependencies: [
              "Support",
              .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
              .product(name: "TypedFullState", package: "TypedFullState")
            ]
           ),
    .target(name: "Root",
            dependencies: [
              "AUv3s",
              "Presets",
              "Support",
              .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
              .product(name: "TypedFullState", package: "TypedFullState")
            ]
           ),
    .target(name: "Support",
            dependencies: [
              .product(name: "Dependencies", package: "swift-dependencies"),
              .product(name: "Sharing", package: "swift-sharing"),
            ]
           ),
    .target(
      name: "AudioUnitHost",
      dependencies: [
        .product(name: "AUv3Host", package: "auv3-support"),
        .product(name: "AUv3Shared", package: "auv3-support"),
        .product(name: "AUv3Component", package: "auv3-support"),
        .product(name: "TypedFullState", package: "TypedFullState"),
      ]
    ),
    .testTarget(
      name: "AudioUnitHostTests"
    )
  ]
)
