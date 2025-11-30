// Copyright © 2020 Apple. All rights reserved.

import AudioToolbox
import Dependencies

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
    .init(
      componentType: FourCharCode("aumu"),
      componentSubType: FourCharCode("Sf2P"),
      componentManufacturer: FourCharCode("BRay"),
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
      componentSubType: FourCharCode("dls "),
      componentManufacturer: FourCharCode("appl"),
      componentFlags: 0,
      componentFlagsMask: 0
    )
  }
}
