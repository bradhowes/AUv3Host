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

private class MIDINoteEmitter {

  private var _isPlaying = ManagedAtomic<Bool>(false)

  internal private(set) var isPlaying: Bool {
    get { _isPlaying.load(ordering: .acquiring) }
    set { _isPlaying.store(newValue, ordering: .sequentiallyConsistent) }
  }

  private let audioUnit: AVAudioUnit

  init(audioUnit: AVAudioUnit) {
    self.audioUnit = audioUnit
  }

  func start() {
    stop()
    scheduleInstrumentLoop()
  }

  func stop() {
    isPlaying = false
  }

  private func scheduleInstrumentLoop() {
    isPlaying = true
    let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)
    DispatchQueue.global(qos: .default).async {
      let duration = useconds_t(1e5)

      // The steps arrays define the musical intervals of a scale (w = whole step, h = half step).

      // C Major: w, w, h, w, w, w, h
      let steps = [2, 2, 1, 2, 2, 2, 1]

      // C Minor: w, h, w, w, w, h, w
      // let steps = [2, 1, 2, 2, 2, 1, 2]

      // C Lydian: w, w, w, h, w, w, h
      // let steps = [2, 2, 2, 1, 2, 2, 1]

      // All off
      bytes[0] = 0xB0
      bytes[1] = 60
      bytes[2] = 0
      self.audioUnit.auAudioUnit.scheduleMIDIEventBlock?(AUEventSampleTimeImmediate, 0, 3, bytes)
      usleep(duration)

      var note = 0
      var step = 0
      while self.isPlaying {
        bytes[0] = 0x90
        bytes[1] = UInt8(60 + note)
        bytes[2] = 64
        self.audioUnit.auAudioUnit.scheduleMIDIEventBlock?(AUEventSampleTimeImmediate, 0, 3, bytes)
        usleep(duration * 4)

        bytes[0] = 0x80
        bytes[1] = UInt8(60 + note)
        self.audioUnit.auAudioUnit.scheduleMIDIEventBlock?(AUEventSampleTimeImmediate, 0, 2, bytes)
        usleep(duration)

        note += steps[step]
        step += 1
        if step == steps.count { step = 0 }
        if note >= 24 { note = 0 }
      }

      // All off
      bytes[0] = 0xB0
      bytes[1] = 60
      bytes[2] = 0
      self.audioUnit.auAudioUnit.scheduleMIDIEventBlock?(AUEventSampleTimeImmediate, 0, 3, bytes)

      bytes.deallocate()
    }
  }
}

