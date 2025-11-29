// Copyright © 2025 Brad Howes. All rights reserved.

import AudioUnit
import AVFoundation
import Foundation
import TypedFullState
import UIKit

public struct AudioUnitInstance: Identifiable {
  public typealias ID = UUID
  public let id: ID
  public let audioUnit: AVAudioUnit
  public let viewController: UIViewController
  public var fullState: TypedFullState? {
    get { try? audioUnit.auAudioUnit.fullState?.asTypedAny() }
    set { audioUnit.auAudioUnit.fullState = FullState.make(from: newValue) }
  }

  public init(id: UUID, audioUnit: AVAudioUnit, viewController: UIViewController) {
    self.id = id
    self.audioUnit = audioUnit
    self.viewController = viewController
  }
}
