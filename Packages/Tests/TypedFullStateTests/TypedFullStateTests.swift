import AudioToolbox
import XCTest
import AVFAudio

class TypedFullStateTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testTypedAnyAUValue() throws {
    let a = AUValue(1.23)
    let b = try! TypedAny(rawValue: a)
    XCTAssertEqual(b.asAUValue, a)
    XCTAssertEqual(b.asString, TypedAny.formatted(a))
  }

  func testTypedAnyString() throws {
    let a = "hello"
    let b = try! TypedAny(rawValue: a)
    XCTAssertEqual(b.asAny as! String, a)
    XCTAssertEqual(b.asString, a)
  }

  func testTypedAnyInt() throws {
    let a = 123
    let b = try! TypedAny(rawValue: a)
    XCTAssertEqual(b.asInt, a)
    XCTAssertEqual(b.asString, "\(a)")
  }

  func testTypedAnyDouble() throws {
    let a = Double(1.2345)
    let b = try! TypedAny(rawValue: a)
    XCTAssertEqual(b.asDouble, a)
    XCTAssertEqual(b.asString, TypedAny.formatted(a))
  }

  func testTypedAnyDict() throws {
    let a: [String: Any] = ["int": Int(1), "double": Double(1.2345), "string": "string"]
    let b = (try! TypedAny(rawValue: a)).asDict!
    XCTAssertEqual(b["int"]!.asInt, a["int"]! as? Int)
    XCTAssertEqual(b["double"]!.asDouble, a["double"]! as? Double)
    XCTAssertEqual(b["string"]!.asString, a["string"]! as? String)
  }

  func testTypedAnyArray() throws {
    let a: [Any] = [Int(1), Double(1.2345), "string", [1, 2, 3]]
    let b = (try! TypedAny(rawValue: a)).asArray!
    XCTAssertEqual(b[0].asInt, a[0] as? Int)
    XCTAssertEqual(b[1].asDouble, a[1] as? Double)
    XCTAssertEqual(b[2].asString, a[2] as? String)
    XCTAssertEqual(b[3].asArray, try? TypedAny(rawValue: a[3]).asArray)
  }

  func testFullStateConversions() throws {
    let a: FullState = ["one": 1, "two": 2.3, "three": AUValue(3.14159), "four": "4"]
    let b = try a.asTypedAny()
    XCTAssertEqual(b["one"]?.asInt, 1)
    XCTAssertEqual(b["two"]?.asDouble, 2.3)
    XCTAssertEqual(b["three"]?.asAUValue, 3.14159)
    XCTAssertEqual(b["four"]?.asString, "4")

    let c = FullState.make(from: b)!
    XCTAssertEqual(c["one"] as? Int, 1)
    XCTAssertEqual(c["two"] as? Double, 2.3)
    XCTAssertEqual(c["three"] as? AUValue, 3.14159)
    XCTAssertEqual(c["four"] as? String, "4")
  }

  func testFullStateCollectionConversions() throws {
    let a: FullState = ["one": 1, "two": 2.3, "three": AUValue(3.14159), "four": "4"]
    let b: FullState = ["five": 5.5, "six": 6]
    let c = [a, nil, nil, b]
    let d = try c.asTypedAny()
    XCTAssertEqual(d.count, c.count)
    XCTAssertEqual(d[0], try c[0]?.asTypedAny())
    XCTAssertEqual(d[1], nil)
    XCTAssertEqual(d[2], nil)
    XCTAssertEqual(d[3], try c[3]?.asTypedAny())

    let e = FullStateCollection.make(from: d)
    XCTAssertEqual(e.count, d.count)
    XCTAssertEqual(e[0]?["one"] as? Int, 1)
    XCTAssertEqual(e[0]?["two"] as? Double, 2.3)
    XCTAssertEqual(e[0]?["three"] as? AUValue, 3.14159)
    XCTAssertEqual(e[0]?["four"] as? String, "4")
    XCTAssertNil(e[1])
    XCTAssertNil(e[2])
    XCTAssertEqual(e[3]?["five"] as? Double, 5.5)
    XCTAssertEqual(e[3]?["six"] as? Int, 6)
  }

  func testFullStateJSONEncodedDecoded() throws {
    let sampler = AVAudioUnitSampler()
    let state = sampler.auAudioUnit.fullState!
    let typedState = try! state.asTypedAny()
    let encoded = try! JSONEncoder().encode(typedState)
    let decoded = try! JSONDecoder().decode(TypedFullState.self, from: encoded)
    let fullState = FullState.make(from: decoded)!
    sampler.auAudioUnit.fullState = fullState
    XCTAssertEqual(state.count, fullState.count)
    XCTAssertEqual(state.keys.sorted(), fullState.keys.sorted())
  }
}
