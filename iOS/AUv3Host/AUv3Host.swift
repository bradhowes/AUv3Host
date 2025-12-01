// Copyright © 2025 Brad Howes. All rights reserved.

import Root
import ComposableArchitecture
import SwiftUI

@main
struct AUv3Host: App {

  init() {
    Root.prepareDependencies(subtype: "samp", manufacturer: "appl")
  }

  var body: some Scene {
    WindowGroup {
      if !isTesting {
        ContentView()
      }
    }
  }
}

struct ContentView: View {
  var body: some View {
    RootView(store: Store(initialState: .init()) { Root() })
  }
}
