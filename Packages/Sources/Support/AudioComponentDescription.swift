// Copyright © 2020 Apple. All rights reserved.

import AudioToolbox

extension AudioComponentDescription {
  public var description: String {
    "type: \(componentType.stringValue), subtype: \(componentSubType.stringValue), manufacturer: \(componentManufacturer.stringValue)"
  }
}
