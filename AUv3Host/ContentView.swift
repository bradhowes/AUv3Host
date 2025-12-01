// Copyright © 2025 Brad Howes. All rights reserved.

import ComposableArchitecture
import Root
import SwiftUI

struct ContentView: View {
  var body: some View {
    RootView(store: Store(initialState: .init()) { Root() })
      .padding()
  }
}

#Preview {
  ContentView()
}
