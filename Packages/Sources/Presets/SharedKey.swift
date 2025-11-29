// Copyright © 2025 Brad Howes. All rights reserved.

import Foundation
import Sharing

extension SharedKey where Self == AppStorageKey<UUID?>.Default {
  public static var activePreset: Self { Self[.appStorage("activePreset"), default: nil] }
}

extension SharedKey where Self == AppStorageKey<Int>.Default {
  public static var auv3InstanceCount: Self { Self[.appStorage("auv3InstanceCount"), default: 1] }
}
