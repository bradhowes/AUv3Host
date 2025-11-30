// Copyright © 2025 Brad Howes. All rights reserved.

import AUv3s
import ComposableArchitecture
import Presets
import Support
import SwiftUI

@Reducer
public struct Root {

  @ObservableState
  public struct State: Equatable {
    public var instances: AUv3sList.State
    public var presets: PresetsList.State

    public init(instances: AUv3sList.State, presets: PresetsList.State) {
      self.instances = instances
      self.presets = presets
    }
  }

  public enum Action {
    case initialize
    case instances(AUv3sList.Action)
    case noteButtonTapped
    case playButtonTapped
    case presets(PresetsList.Action)
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Scope(state: \.instances, action: \.instances) { AUv3sList() }
    Scope(state: \.presets, action: \.presets) { PresetsList() }

    Reduce { state, action in
      log.info("reduce \(action)")
      switch action {

      case .initialize:
        return initialize(&state)

      case .instances:
        return .none

      case .noteButtonTapped:
        return .none

      case .playButtonTapped:
        return .none

      case .presets:
        return .none
      }
    }
  }
}

extension Root {

  private func playButtonTapped(_ state: inout State) -> Effect<Action> {
    return .none
  }

  private func initialize(_ state: inout State) -> Effect<Action> {
    return .merge(
      reduce(into: &state, action: .instances(.initialize)),
      reduce(into: &state, action: .presets(.initialize))
    )
  }
}

public struct RootView: View {
  private var store: StoreOf<Root>

  public init(store: StoreOf<Root>) {
    self.store = store
  }

  public var body: some View {
    VStack {
      HStack {
        AUv3sListView(store: store.scope(state: \.instances, action: \.instances))
        PresetsListView(store: store.scope(state: \.presets, action: \.presets))
      }
      HStack {
        Button {
          store.send(.playButtonTapped)
        } label: {
          Text("Play")
        }
        Button {
          store.send(.noteButtonTapped)
        } label: {
          Text("Note")
        }
      }
    }
    .task {
      await store.send(.initialize).finish()
    }
  }
}

extension RootView {

  static var preview: some View {
    prepareDependencies {
      $0.uuid = .incrementing
      $0.presetsStore = .previewValue
    }
    return VStack {
      RootView(store: Store(initialState: .init(instances: AUv3sList.State(), presets: PresetsList.State())) { Root() })
    }
  }
}

private let log = Logger(category: "Root")

#Preview {
  RootView.preview
}
