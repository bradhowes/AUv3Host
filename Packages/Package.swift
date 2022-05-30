// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "Packages",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(name: "TypedFullState", targets: ["TypedFullState"]),
    .library(name: "AudioUnitHost", targets: ["AudioUnitHost"]),
    .library(name: "PresetDocumentManager", targets: ["PresetDocumentManager"])
  ],
  dependencies: [
    .package(name: "AUv3SupportPackage", url: "https://github.com/bradhowes/AUv3Support", branch: "main"),
    .package(url: "https://github.com/apple/swift-atomics.git", .upToNextMajor(from: "1.0.0"))
  ],
  targets: [
    .target(name: "TypedFullState"),
    .target(
      name: "PresetDocumentManager",
      dependencies: [.targetItem(name: "TypedFullState", condition: nil)]
    ),
    .target(
      name: "AudioUnitHost",
      dependencies: [
        .product(name: "AUv3-Support", package: "AUv3SupportPackage"),
        .product(name: "Atomics", package: "swift-atomics"),
        .targetItem(name: "TypedFullState", condition: nil)
      ]
    ),
    .testTarget(
      name: "AudioUnitHostTests"
    )
  ]
)
