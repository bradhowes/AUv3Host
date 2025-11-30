//
//  Component.swift
//  Packages
//
//  Created by Brad Howes on 11/30/25.
//

// Copyright © 2025 Brad Howes. All rights reserved.

import AudioToolbox
import Dependencies

extension DependencyValues {

  public var componentDescription: AudioComponentDescription {
    get { self[AudioComponentDescription.self] }
    set { self[AudioComponentDescription.self] = newValue }
  }
}
