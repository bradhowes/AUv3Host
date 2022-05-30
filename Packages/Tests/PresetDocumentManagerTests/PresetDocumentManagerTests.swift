import AudioToolbox
import XCTest
import AVFAudio

private let uuid: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
private let uuidGenerator: UUIDGenerator = { UUID(uuid: uuid) }

class PresetDocumentManagerTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }
}
