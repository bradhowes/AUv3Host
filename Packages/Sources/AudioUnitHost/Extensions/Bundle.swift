// Copyright © 2020 Apple. All rights reserved.

import Foundation

public extension Bundle {

  /// Obtain the bundle identifier or "" if there is not one
  static var bundleID: String { Bundle.main.bundleIdentifier ?? "" }
}
