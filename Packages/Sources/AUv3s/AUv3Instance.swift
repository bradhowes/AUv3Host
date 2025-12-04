// Copyright © 2025 Brad Howes. All rights reserved.

import AudioUnit
import AVFAudio
import CoreAudioKit
import Dependencies
import Foundation
import Support
import SwiftUI
import TypedFullState
import UIKit

public enum AUv3InstanceError: Error {
  case noViewController
}

public struct AUv3Instance: Equatable {
  public let audioUnit: AVAudioUnit
  public let viewController: UIViewController

  public var fullState: TypedFullState? {
    get { try? audioUnit.auAudioUnit.fullState?.asTypedAny() }
    set { audioUnit.auAudioUnit.fullState = FullState.make(from: newValue) }
  }

  public var name: String {
    audioUnit.auAudioUnit.audioUnitShortName ?? "n/a"
  }

  public static func make(component: AudioComponentDescription) async throws -> AUv3Instance {
    log.info("make BEGIN - \(component.description)")
    let audioUnit = try await AVAudioUnit.instantiate(with: component)
    log.info("make - created audio unit")

    guard let viewController = await audioUnit.auAudioUnit.requestViewController() else {
      log.info("make - failed to create view controller")
      throw AUv3InstanceError.noViewController
    }
    log.info("make END")
    return .init(audioUnit: audioUnit, viewController: viewController)
  }

  private init(audioUnit: AVAudioUnit, viewController: UIViewController) {
    self.audioUnit = audioUnit
    self.viewController = viewController
    log.info("init - audioUnit: \(audioUnit) / viewController: \(viewController)")
  }
}

extension String.StringInterpolation {
  public mutating func appendInterpolation(_ value: AUv3Instance) {
    appendLiteral("""
<AUv3Instance: \(Unmanaged.passUnretained(value.audioUnit).toOpaque()), \
\(Unmanaged.passUnretained(value.viewController).toOpaque())>
""")
  }
}

private let log = Logger(category: "AUv3Instance")

extension AVAudioUnit: @retroactive @unchecked Sendable {}
