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

public struct AUv3Instance: Equatable, Identifiable {
  public typealias ID = UUID
  public let id: ID
  public let audioUnit: AVAudioUnit
  public let viewController: UIViewController

  public var fullState: TypedFullState? {
    get { try? audioUnit.auAudioUnit.fullState?.asTypedAny() }
    set { audioUnit.auAudioUnit.fullState = FullState.make(from: newValue) }
  }

  public var name: String {
    audioUnit.auAudioUnit.audioUnitShortName ?? "???"
  }

  public init(id: UUID, audioUnit: AVAudioUnit, viewController: UIViewController) {
    self.id = id
    self.audioUnit = audioUnit
    self.viewController = viewController
  }

  public static func make(component: AudioComponentDescription) async throws -> AUv3Instance {
    log.info("make: \(component.description)")
    let audioUnit = try await AVAudioUnit.instantiate(with: component)
    log.info("created audio unit")

    let viewController = try await makeUI(audioUnit: audioUnit)
    log.info("created view controller")
    @Dependency(\.uuid) var uuid
    return .init(id: uuid(), audioUnit: audioUnit, viewController: viewController)
  }

  @MainActor
  public static func makeUI(audioUnit: AVAudioUnit) async throws -> UIViewController {
    guard let viewController = await audioUnit.auAudioUnit.requestViewController() else {
      log.info("failed to create view controller")
      throw AUv3InstanceError.noViewController
    }
    log.info("created view controller")
    return viewController
  }
}

private let log = Logger(category: "AUv3Instance")

extension AVAudioUnit: @retroactive @unchecked Sendable {}
