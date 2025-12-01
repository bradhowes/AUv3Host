// Copyright © 2025 Brad Howes. All rights reserved.

import AudioToolbox
import Foundation
import Sharing

extension SharedKey where Self == AppStorageKey<String>.Default {
  public static var componentSubtype: Self { Self[.appStorage("componentSubtype"), default: "samp"] }
  public static var componentManufacturer: Self { Self[.appStorage("componentManufacturer"), default: "appl"] }
}

extension SharedKey where Self == AppStorageKey<UUID?>.Default {
  public static var activeAUv3: Self { Self[.appStorage("activeAUv3"), default: nil] }
  public static var activePreset: Self { Self[.appStorage("activePreset"), default: nil] }
}

extension SharedKey where Self == AppStorageKey<Int>.Default {
  public static var auv3InstanceCount: Self { Self[.appStorage("auv3InstanceCount"), default: 1] }
}
