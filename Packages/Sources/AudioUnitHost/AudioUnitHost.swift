// Copyright © 2020 Brad Howes. All rights reserved.

import os.log
import Atomics
import AVFoundation
import CoreAudioKit
import AUv3Support
import TypedFullState

/// Component description that matches the AudioUnit to load. The values must match those found in the Info.plist
let componentToLoad: AudioComponentDescription = .init(
  componentType: FourCharCode(stringLiteral: "aumu"),
  componentSubType: FourCharCode(stringLiteral: "sfnt"),
  componentManufacturer: FourCharCode(stringLiteral: "bray"),
  componentFlags: 0,
  componentFlagsMask: 0
)

/**
 Errors that can come from AudioUnitHost.
 */
public enum AudioUnitHostError: Error {
  /// Unexpected nil AUAudioUnit (most likely never can happen)
  case nilAudioUnit
  /// Unexpected nil ViewController from AUAudioUnit request
  case nilViewController
  /// Failed to locate component matching given AudioComponentDescription
  case componentNotFound
  /// Error from Apple framework (CoreAudio, AVFoundation, etc.)
  case framework(error: Error)
  /// String describing the error case.
  public var description: String {
    switch self {
    case .nilAudioUnit: return "Failed to obtain a usable audio unit instance."
    case .nilViewController: return "Failed to obtain a usable view controller from the instantiated audio unit."
    case .componentNotFound: return "Failed to locate the right AUv3 component to instantiate."
    case .framework(let err): return "Framework error: \(err.localizedDescription)"
    }
  }
}

/**
 Delegation protocol for AudioUnitHost class.
 */
public protocol AudioUnitHostDelegate: AnyObject {

  /**
   Notification that the UIViewController in the AudioUnitHost has finished allocating all

   - parameter audioUnits the collection of AVAudioUnit instances that have been created
   - parameter viewControllers the collection of ViewController instances for the audio units
   */
  func connected(audioUnits: [AVAudioUnit], viewControllers: [AVAudioUnit: ViewController])

  /**
   Notification that a collection of fullState values is available for saving

   - parameter uuid the UUID of the preset that the collection belongs to
   - parameter fullStateCollection the collection that was generated
   */
  func fullStateCollectionGenerated(uuid: UUID, fullStateCollection: FullStateCollection)

  /**
   Notification that there was a problem instantiating the audio unit or its view controller

   - parameter error: the error that was encountered
   */
  func failed(error: AudioUnitHostError)
}

/**
 Simple hosting container for the FilterAudioUnit when used in an application. Loads the view controller for the
 AudioUnit and then instantiates the audio unit itself. Finally, it wires the AudioUnit with SimplePlayEngine to
 send audio samples to the AudioUnit. Note that this class has no knowledge of any classes other than what Apple
 provides.
 */
public final class AudioUnitHost {
  private let log = Shared.logger("AudioUnitHost")

  private let fifo = DispatchQueue(label: "AudioUnitHostFIFO", qos: .userInitiated, attributes: [],
                                   autoreleaseFrequency: .inherit, target: .main)

  private var audioUnits = [AVAudioUnit]()
  private var viewControllers = [AVAudioUnit: ViewController]()

  /// True if the audio engine is currently playing
  public var isPlaying: Bool { playEngine.isPlaying }

  /// Delegate to signal when everything is wired up.
  public weak var delegate: AudioUnitHostDelegate? { didSet { notifyDelegate() } }

  private let lastStateKey = "lastStateKey"
  private let lastPresetNumberKey = "lastPresetNumberKey"

  private let playEngine = SoundEngine()
  private let locateQueue = DispatchQueue(label: Bundle.bundleID + ".LocateQueue", qos: .userInitiated)
  private let componentDescription: AudioComponentDescription

  private var notificationObserverToken: NSObjectProtocol?
  private let instanceCount: ManagedAtomic<Int>

  private var creationError: AudioUnitHostError? { didSet { notifyDelegate() } }
  private var detectionTimer: Timer?

  /**
   Create a new instance that will hopefully create a new AUAudioUnit and a view controller for its control view.

   - parameter componentDescription: the definition of the AUAudioUnit to create
   */
  public init(count: Int) {
    self.componentDescription = componentToLoad
    self.instanceCount = .init(count)
    componentDescription.log(log, type: .info)
    locate()
  }

  public func setInstanceCount(_ instanceCount: Int) {
    self.instanceCount.store(instanceCount, ordering: .sequentiallyConsistent)
    if audioUnits.count < instanceCount {
      self.fifo.async {
        self.createAudioUnit(componentDescription: self.componentDescription)
      }
    } else {
      self.fifo.async {
        self.prune()
      }
    }
  }

  public func makeFullStateCollection(uuid: UUID) {
    fifo.async {
      let docs = self.audioUnits.map { $0.auAudioUnit.fullState }
      self.delegate?.fullStateCollectionGenerated(uuid: uuid, fullStateCollection: docs)
    }
  }

  public func setFullStateCollection(_ fullStateCollection: FullStateCollection) {
    fifo.async {
      for (audioUnit, fullState) in zip(self.audioUnits, fullStateCollection) {
        audioUnit.auAudioUnit.fullState = fullState
      }
    }
  }

  /**
   Use AVAudioUnitComponentManager to locate the AUv3 component we want. This is done asynchronously in the background.
   If the component we want is not found, start listening for notifications from the AVAudioUnitComponentManager for
   updates and try again.
   */
  private func locate() {
    os_log(.info, log: log, "locate - %d", instanceCount.load(ordering: .sequentiallyConsistent))
    locateQueue.async { [weak self] in
      guard let self = self else { return }

      let description = AudioComponentDescription(componentType: self.componentDescription.componentType,
                                                  componentSubType: 0,
                                                  componentManufacturer: 0,
                                                  componentFlags: 0,
                                                  componentFlagsMask: 0)

      let components = AVAudioUnitComponentManager.shared().components(matching: description)
      os_log(.info, log: self.log, "locate: found %d", components.count)

      for each in components {
        each.audioComponentDescription.log(self.log, type: .info)
        if each.audioComponentDescription.componentManufacturer == self.componentDescription.componentManufacturer,
           each.audioComponentDescription.componentType == self.componentDescription.componentType,
           each.audioComponentDescription.componentSubType == self.componentDescription.componentSubType {
          os_log(.info, log: self.log, "found match")
          self.fifo.async {
            self.createAudioUnit(componentDescription: each.audioComponentDescription)
          }
          return
        }
      }

      DispatchQueue.main.async {
        self.checkAgain()
      }
    }
  }

  /**
   Begin listening for updates from the AVAudioUnitComponentManager. When we get one, stop listening and attempt to
   locate the AUv3 component we want.
   */
  private func checkAgain() {
    os_log(.info, log: log, "checkAgain")
    let center = NotificationCenter.default

    detectionTimer?.invalidate()
    detectionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
      self.creationError = AudioUnitHostError.componentNotFound
    }

    notificationObserverToken = center.addObserver(
      forName: AVAudioUnitComponentManager.registrationsChangedNotification, object: nil, queue: nil
    ) { [weak self] _ in
      guard let self = self else { return }
      os_log(.info, log: self.log, "checkAgain: notification")
      let token = self.notificationObserverToken!
      self.notificationObserverToken = nil
      center.removeObserver(token)
      self.detectionTimer?.invalidate()
      self.locate()
    }
  }

  /**
   Create the desired component using the AUv3 API
   */
  private func createAudioUnit(componentDescription: AudioComponentDescription) {
    os_log(.info, log: log, "createAudioUnit - %d", instanceCount.load(ordering: .sequentiallyConsistent))

#if os(macOS)
    let options: AudioComponentInstantiationOptions = .loadInProcess
#else
    let options: AudioComponentInstantiationOptions = .loadOutOfProcess
#endif

    AVAudioUnit.instantiate(with: componentDescription, options: options) { [weak self] audioUnit, error in
      guard let self = self else { return }
      if let error = error {
        os_log(.error, log: self.log, "createAudioUnit: error - %{public}s", error.localizedDescription)
        self.creationError = .framework(error: error)
        return
      }

      guard let audioUnit = audioUnit else {
        os_log(.error, log: self.log, "createAudioUnit: nil audioUnit")
        self.creationError = AudioUnitHostError.nilAudioUnit
        return
      }

      os_log(.info, log: self.log, "audioUnit: %{public}s", String.pointer(audioUnit))

      self.audioUnits.append(audioUnit)
      audioUnit.auAudioUnit.contextName = "Track \(self.audioUnits.count)"
      self.fifo.async {
        self.createViewController(audioUnit: audioUnit)
      }
    }
  }

  /**
   Create the component's view controller to embed in the host view. NOTE: this is run on the main thread.

   - parameter avAudioUnit: the AVAudioUnit that was instantiated
   */
  private func createViewController(audioUnit: AVAudioUnit) {
    os_log(.info, log: log, "createViewController - %d", instanceCount.load(ordering: .sequentiallyConsistent))
    audioUnit.auAudioUnit.requestViewController { [weak self] controller in
      guard let self = self else { return }

      guard let controller = controller else {
        os_log(.error, log: self.log, "createViewController: nil controller")
        self.creationError = AudioUnitHostError.nilViewController
        return
      }

      os_log(.info, log: self.log, "viewController - %{public}s", String.pointer(controller))
      self.viewControllers[audioUnit] = controller
      self.playEngine.connect(audioUnit: audioUnit)

      if self.audioUnits.count < self.instanceCount.load(ordering: .sequentiallyConsistent) {
        self.fifo.async {
          self.createAudioUnit(componentDescription: audioUnit.audioComponentDescription)
        }
      } else {
        self.fifo.async {
          self.prune()
        }
      }
    }
  }

  private func prune() {
    let toRemove = audioUnits.count - instanceCount.load(ordering: .sequentiallyConsistent)
    if toRemove > 0 {
      let audioUnits = audioUnits.dropLast(toRemove)
      for audioUnit in audioUnits {
        playEngine.disconnect(audioUnit: audioUnit)
      }
      _ = viewControllers.dropLast(toRemove)
    }
    notifyDelegate()
  }

  private func notifyDelegate() {
    os_log(.info, log: log, "notifyDelegate")
    if let creationError = creationError {
      os_log(.info, log: log, "error: %{public}s", creationError.localizedDescription)
      DispatchQueue.main.async { self.delegate?.failed(error: creationError) }
    } else {
      os_log(.info, log: log, "success")
      DispatchQueue.main.async {
        self.delegate?.connected(audioUnits: self.audioUnits, viewControllers: self.viewControllers)
      }
    }
  }
}

public extension AudioUnitHost {

  /**
   Save the current state of the AUv3 component to UserDefaults for future restoration. Saves the value from
   `fullStateForDocument` and the number of the preset that is in `currentPreset` if non-nil.
   */
  func save() {
//    guard let audioUnit = audioUnit else { return }
//    locateQueue.async { [weak self] in self?.doSave(audioUnit) }
  }

  private func doSave(_ audioUnit: AUAudioUnit) {

    // Theoretically, we only need to save the full state if `currentPreset` is nil. However, it is possible that the
    // preset is a user preset and is removed some time in the future by another application. So we always safe the
    // full state here (if available).
    //
    if let lastState = audioUnit.fullStateForDocument {
      UserDefaults.standard.set(lastState, forKey: lastStateKey)
    } else {
      UserDefaults.standard.removeObject(forKey: lastStateKey)
    }

    // Save the number of the current preset.
    if let lastPresetNumber = audioUnit.currentPreset?.number {
      UserDefaults.standard.set(lastPresetNumber, forKey: lastPresetNumberKey)
    } else {
      UserDefaults.standard.removeObject(forKey: lastPresetNumberKey)
    }
  }
}

public extension AudioUnitHost {

  /**
   Start/stop audio engine

   - returns: true if playing
   */
  @discardableResult
  func togglePlayback() -> Bool { playEngine.startStop() }

  /**
   The world is being torn apart. Stop any asynchronous eventing from happening in the future.
   */
  func cleanup() {
    playEngine.stop()
  }

  func playNoteOnce(_ audioUnit: AVAudioUnit) {
    let duration = useconds_t(0.2 * 1e6)
    let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)

    bytes[0] = 0x90
    bytes[1] = UInt8(60)
    bytes[2] = 64
    audioUnit.auAudioUnit.scheduleMIDIEventBlock?(AUEventSampleTimeImmediate, 0, 3, bytes)

    usleep(duration)

    bytes[2] = 0    // note off
    audioUnit.auAudioUnit.scheduleMIDIEventBlock?(AUEventSampleTimeImmediate, 0, 3, bytes)
    bytes.deallocate()
  }
}
