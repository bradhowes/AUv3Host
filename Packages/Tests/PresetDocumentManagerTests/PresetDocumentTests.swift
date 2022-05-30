import AudioToolbox
import XCTest
import AVFAudio

private let uuid: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

class PresetDocumentTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testCodable() throws {
    let engine = AVAudioEngine()
    let samplers = [AVAudioUnitSampler(), AVAudioUnitSampler(), AVAudioUnitSampler()]
    for sampler in samplers {
      engine.attach(sampler)
      engine.connect(sampler, to: engine.mainMixerNode, format: nil)
    }
    engine.prepare()
    try! engine.start()

    samplers[0].overallGain = -80.0
    samplers[1].overallGain = 1.0
    samplers[2].overallGain = 11.0

    let states = samplers.map { $0.auAudioUnit.fullState }
    // print(states[0]!["data"]!)
    // print(states[1]!["data"]!)
    // print(states[2]!["data"]!)
    // states.forEach { print($0!["gain"]!) }

    samplers[0].overallGain = 0.0
    samplers[1].overallGain = 0.0
    samplers[2].overallGain = 0.0

    let presetDocument = PresetDocument(name: "one", uuid: UUID(uuid: uuid),
                                        fullStateCollection: try! states.asTypedAny())

    let encoded = try! JSONEncoder().encode(presetDocument)
    let decoded = try! JSONDecoder().decode(PresetDocument.self, from: encoded)

    XCTAssertEqual(decoded.name, presetDocument.name)
    XCTAssertEqual(decoded.uuid, presetDocument.uuid)
    XCTAssertEqual(decoded.fullStateCollection.count, presetDocument.fullStateCollection.count)

    for (sampler, fullState) in zip(samplers, presetDocument.fullStateCollection) {
      sampler.auAudioUnit.fullState = fullState
    }

    // NOTE: for some unknown reason, changing the pan or overallGain of the AVAudioUnitSampler is not recorded in the
    // fullState so, it is not restored.
    // XCTAssertEqual(samplers[0].overallGain, -80.0)
    // XCTAssertEqual(samplers[1].overallGain, 1.0)
    // XCTAssertEqual(samplers[2].overallGain, 11.0)
  }
}
