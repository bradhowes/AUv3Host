// Copyright © 2025 Brad Howes. All rights reserved.

import AVFAudio
import Support

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
      bytes[1] = 72
      bytes[2] = 0
      block(AUEventSampleTimeImmediate, 0, 3, bytes)
      bytes.deallocate()
    }

    bytes[0] = 0x90
    bytes[1] = 72
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

private let log = Logger(category: "AUAudioUnit")
