// Copyright © 2025 Brad Howes. All rights reserved.

import OSLog

private class BundleTag {}

public struct Logger: Sendable {

  /// The top-level identifier for the app.
  public static let subsystem = Bundle(for: BundleTag.self).bundleIdentifier?.lowercased() ?? "?"

  public let category: String
  public let logger: os.Logger

  public init(category: String) {
    self.category = category
    self.logger = os.Logger(subsystem: Self.subsystem, category: category)
  }

#if DEBUG

  public func log(level: OSLogType = .default, _ string: @autoclosure () -> String) {
    let string = string()
    if isRunningForPreviews {
      print("\(category) - \(string)")
    } else {
      if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
        self.logger.log(level: level, "\(string)")
      }
    }
  }

#else

  @inlinable @inline(__always)
  public func log(level: OSLogType = .default, _ string: @autoclosure () -> String) {}

#endif

  @inlinable @inline(__always)
  public func debug(_ string: @autoclosure () -> String) { self.log(level: .debug, string()) }

  @inlinable @inline(__always)
  public func info(_ string: @autoclosure () -> String) { self.log(level: .info, string()) }

  @inlinable @inline(__always)
  public func error(_ string: @autoclosure () -> String) { self.log(level: .error, string()) }

  @inlinable @inline(__always)
  public func fault(_ string: @autoclosure () -> String) { self.log(level: .fault, string()) }

}

private let isRunningForPreviews = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
