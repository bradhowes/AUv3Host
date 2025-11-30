// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

/**
 Provide for async running of a task for generating model data.

 Lifted from https://stackoverflow.com/a/77920319/629836
 */
public struct AsyncModel<VisualContent: View, ModelData>: View {
  var viewBuilder: (ModelData) -> VisualContent
  var model: () async throws -> ModelData?

  @State private var modelData: ModelData?
  @State private var error: Error?

  public init(
    viewBuilder: @escaping (ModelData) -> VisualContent,
    model: @escaping () async throws -> ModelData?
  ) {
    self.viewBuilder = viewBuilder
    self.model = model
  }

  public var body: some View {
    safeView
      .task {
        do {
          self.modelData = try await model()
        } catch {
          self.error = error
          print(error)
        }
      }
  }

  @ViewBuilder
  private var safeView: some View {
    if let modelData {
      viewBuilder(modelData)
    }
    else if let error {
      Text(error.localizedDescription)
        .foregroundStyle(Color.red)
    } else {
      Text("Generating async data…")
    }
  }
}

