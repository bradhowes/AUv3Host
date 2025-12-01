// Copyright © 2020 Apple. All rights reserved.

import AudioToolbox
import Dependencies
import Sharing

extension AudioComponentDescription {
  public var description: String {
    """
type: \(componentType.stringValue), \
subtype: \(componentSubType.stringValue), \
manufacturer: \(componentManufacturer.stringValue)
"""
  }
}

extension AudioComponentDescription: @retroactive TestDependencyKey {
  public static var liveValue: AudioComponentDescription {
    @Shared(.componentSubtype) var componentSubtype
    @Shared(.componentManufacturer) var componentManufacturer
    return .init(
      componentType: FourCharCode("aumu"),
      componentSubType: FourCharCode(componentSubtype),
      componentManufacturer: FourCharCode(componentManufacturer),
      componentFlags: 0,
      componentFlagsMask: 0
    )
  }
  public static var previewValue: AudioComponentDescription {
    .init(
      componentType: FourCharCode("aumu"),
      componentSubType: FourCharCode("samp"),
      componentManufacturer: FourCharCode("appl"),
      componentFlags: 0,
      componentFlagsMask: 0
    )
  }
  public static var testValue: AudioComponentDescription {
    .init(
      componentType: FourCharCode("aumu"),
      componentSubType: FourCharCode("samp"),
      componentManufacturer: FourCharCode("appl"),
      componentFlags: 0,
      componentFlagsMask: 0
    )
  }
}
