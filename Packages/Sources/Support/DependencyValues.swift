//
//  Component.swift
//  Packages
//
//  Created by Brad Howes on 11/30/25.
//

// Copyright © 2025 Brad Howes. All rights reserved.

import AudioToolbox
import Dependencies

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

extension DependencyValues {

  public var componentDescription: AudioComponentDescription {
    get { self[AudioComponentDescription.self] }
    set { self[AudioComponentDescription.self] = newValue }
  }
}
