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
    guard let viewController = await audioUnit.auAudioUnit.requestViewController() else {
      log.info("failed to create view controller")
      throw AUv3InstanceError.noViewController
    }
    log.info("created view controller")
    @Dependency(\.uuid) var uuid
    return .init(id: uuid(), audioUnit: audioUnit, viewController: viewController)
  }
}

extension AUAudioUnit {

  public func playNote() {
    guard let block = scheduleMIDIEventBlock else {
      log.info("playNote END - no scheduleMIDIEventBlock")
      return
    }

    let duration = useconds_t(0.2 * 1e6)
    let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)

    defer {
      // All off
      log.info("playNote END (defer)")

      bytes[0] = 0xB0
      bytes[1] = 60
      bytes[2] = 0
      block(AUEventSampleTimeImmediate, 0, 3, bytes)
      bytes.deallocate()
    }

    bytes[0] = 0x90
    bytes[1] = UInt8(60)
    bytes[2] = 127
    block(AUEventSampleTimeImmediate, 0, 3, bytes)

    usleep(duration)

    bytes[2] = 0    // note off
    block(AUEventSampleTimeImmediate, 0, 3, bytes)

    log.info("playNote END")
  }

  public func playLoop() async {
    log.info("playLoop BEGIN")
    guard let block = scheduleMIDIEventBlock else {
      log.info("playLoop END - no scheduleMIDIEventBlock")
      return
    }

    // TODO: use sample time instead of this
    let duration = useconds_t(1e5)

    // The steps arrays define the musical intervals of a scale (w = whole step, h = half step).

    // C Major: w, w, h, w, w, w, h
    let steps = [2, 2, 1, 2, 2, 2, 1]

    // C Minor: w, h, w, w, w, h, w
    // let steps = [2, 1, 2, 2, 2, 1, 2]

    // C Lydian: w, w, w, h, w, w, h
    // let steps = [2, 2, 2, 1, 2, 2, 1]

    let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)
    defer {
      log.info("playLoop END (defer)")

      // Stop all notes
      bytes[0] = 0xB0
      bytes[1] = 0x7B
      bytes[2] = 0
      block(AUEventSampleTimeImmediate, 0, 3, bytes)
      bytes.deallocate()
    }

    // All notes off
    bytes[0] = 0xB0
    bytes[1] = 0x7B
    bytes[2] = 0
    block(AUEventSampleTimeImmediate, 0, 3, bytes)

    var note = 0
    var step = 0
    while !Task.isCancelled {
      bytes[0] = 0x90
      bytes[1] = UInt8(60 + note)
      bytes[2] = 127
      block(AUEventSampleTimeImmediate, 0, 3, bytes)
      usleep(duration * 4)
      if Task.isCancelled { break }

      bytes[0] = 0x80
      bytes[1] = UInt8(60 + note)
      block(AUEventSampleTimeImmediate, 0, 2, bytes)
      usleep(duration)
      if Task.isCancelled { break }

      note += steps[step]
      step += 1
      if step == steps.count { step = 0 }
      if note >= 24 { note = 0 }
    }

    log.info("playLoop END - cancelled")
  }
}

private let log = Logger(category: "AUv3Instance")
