// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "Packages",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(name: "AudioUnitHost", targets: ["AudioUnitHost"]),
    .library(name: "PresetDocumentManager", targets: ["PresetDocumentManager"])
  ],
  dependencies: [
    .package(name: "AUv3SupportPackage", url: "https://github.com/bradhowes/AUv3Support", branch: "main"),
    .package(name: "TypedFullState", url: "https://github.com/bradhowes/typedfullstate", branch: "main"),
    .package(url: "https://github.com/apple/swift-atomics.git", .upToNextMajor(from: "1.0.0"))
  ],
  targets: [
    .target(name: "PresetDocumentManager",
            dependencies: [
              .product(name: "TypedFullState", package: "TypedFullState")
            ]
           ),
    .target(
      name: "AudioUnitHost",
      dependencies: [
        .product(name: "AUv3-Support", package: "AUv3SupportPackage"),
        .product(name: "TypedFullState", package: "TypedFullState"),
        .product(name: "Atomics", package: "swift-atomics")
      ]
    ),
    .testTarget(
      name: "AudioUnitHostTests"
    )
  ]
)
