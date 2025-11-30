// Changes: Copyright © 2020 Brad Howes. All rights reserved.

import AVFoundation
import Atomics

final class SoundEngine {
  private lazy var bundle = Bundle(for: type(of: self))
  private lazy var bundleIdentifier = bundle.bundleIdentifier!
  private lazy var stateChangeQueue = DispatchQueue(label: bundleIdentifier + ".StateChangeQueue")

  private let engine = AVAudioEngine()
  public var isPlaying: Bool { midiNoteEmitters.first?.isPlaying ?? false }
  private var audioUnits = [AVAudioUnit]()
  private var midiNoteEmitters = [MIDINoteEmitter]()
}

extension SoundEngine {

  public func connect(audioUnit: AVAudioUnit, completion: @escaping (() -> Void) = {}) {
    defer { completion() }

    pauseWhile {
      let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
      engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)

      audioUnits.append(audioUnit)
      midiNoteEmitters.append(MIDINoteEmitter(audioUnit: audioUnit))
      engine.attach(audioUnit)

      let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareFormat.sampleRate, channels: 2)
      engine.connect(audioUnit, to: engine.mainMixerNode, format: stereoFormat)
    }
  }

  func disconnect(audioUnit: AVAudioUnit) {
    pauseWhile {
      engine.disconnectNodeInput(audioUnit)
      engine.disconnectNodeOutput(audioUnit)
      engine.detach(audioUnit)
      if let index = audioUnits.firstIndex(where: {$0 == audioUnit}) {
        audioUnits.remove(at: index)
        midiNoteEmitters.remove(at: index)
      }
    }
  }

  public func start() {
    stop()
    stateChangeQueue.sync {
      updateAudioSession(active: true)

      let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
      engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)

      do {
        try engine.start()
      } catch {
        fatalError("failed to start AVAudioEngine")
      }

      midiNoteEmitters.forEach { $0.start() }
    }
  }

  public func stop() {
    guard isPlaying else { return }
    stateChangeQueue.sync {
      midiNoteEmitters.forEach{ $0.stop() }
    }
  }

  public func startStop() -> Bool {
    if isPlaying { stop() } else { start() }
    return isPlaying
  }
}

private extension SoundEngine {
  /**
   If player is currently playing audio pause it the execution of the given block and then resume it after the block
   is done.

   - parameter block: closure to execute while player is paused
   */
  private func pauseWhile(_ block: () -> Void) {
    let wasPlaying = isPlaying
    if wasPlaying { stop() }
    block()
    if wasPlaying { start() }
  }

  private func updateAudioSession(active: Bool) {
#if os(iOS)
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playback, mode: .default)
      try session.setActive(active)
    } catch {
      fatalError("Could not set Audio Session active \(active). error: \(error).")
    }
#endif
  }
}


