// Copyright © 2025 Brad Howes. All rights reserved.

import Foundation

extension Character {
  var isPrintableASCII: Bool {
    guard let ascii = asciiValue else { return false }
    return 32..<127 ~= ascii
  }
}

extension FourCharCode {

  static var invalidFourCharCode: Self { 0x3F3F3F3F } // "????"

  public init(stringLiteral value: StringLiteralType) {
    self = FourCharCode.validate(value: value)
  }

  public init(_ value: String) {
    self = FourCharCode.validate(value: value)
  }

  private static func validate(value: StringLiteralType) -> Self {
    guard value.count == 4,
          value.utf8.count == 4,
          value.allSatisfy(\.isPrintableASCII)
    else {
      return invalidFourCharCode
    }
    return value.utf8.reduce(into: 0) { $0 = $0 << 8 + FourCharCode($1) }
  }
}

extension FourCharCode {

  private static let bytesSizeForStringValue = MemoryLayout<Self>.size

  /// Obtain a 4-character string from our value - based on https://stackoverflow.com/a/60367676/629836
  public var stringValue: String {
    unsafe withUnsafePointer(to: bigEndian) { pointer in
      unsafe pointer.withMemoryRebound(to: UInt8.self, capacity: Self.bytesSizeForStringValue) { bytes in
        // swiftlint:disable:next force_unwrapping
        unsafe String(bytes: UnsafeBufferPointer(start: bytes, count: Self.bytesSizeForStringValue), encoding: .utf8)!
      }
    }
  }
}

extension FourCharCode: @retroactive ExpressibleByStringLiteral {}
