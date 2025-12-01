// Copyright © 2025 Brad Howes. All rights reserved.

import Root
import SwiftUI

@main
struct AUv3HostApp: App {

  init() {
    Root.prepareDependencies(subtype: "samp", manufacturer: "appl")
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
