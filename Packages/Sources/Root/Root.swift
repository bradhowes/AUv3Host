// Copyright © 2025 Brad Howes. All rights reserved.

import AVFAudio
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

    @ObservationStateIgnored
    public let engine = AVAudioEngine()
    public var songPlaying: Bool

    public init(instances: AUv3sList.State, presets: PresetsList.State) {
      self.instances = instances
      self.presets = presets
      self.songPlaying = false
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
      switch action {

      case .initialize:
        return initialize(&state)

      case .instances:
        return .none

      case .noteButtonTapped:
        return .none

      case .playButtonTapped:
        state.songPlaying.toggle()
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
    .none
  }
}

public struct RootView: View {
  private var store: StoreOf<Root>
  @Shared(.activeAUv3) var activeAUv3

  public init(store: StoreOf<Root>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 16) {
      HStack(spacing: 16) {
        AUv3sListView(store: store.scope(state: \.instances, action: \.instances))
        PresetsListView(store: store.scope(state: \.presets, action: \.presets))
      }
      Grid(horizontalSpacing: 16.0) {
        GridRow {
          Button {
            store.send(.playButtonTapped)
          } label: {
            Text(store.songPlaying ? "Stop Song" : "Start Song")
          }.disabled(store.instances.rows.isEmpty)

          Button {
            store.send(.noteButtonTapped)
          } label: {
            Text("Instance Note")
          }.disabled(activeAUv3 == nil)
        }.frame(maxWidth: .infinity)
      }
      Group {
        if let activeAUv3,
           let index = store.instances.rows.index(id: activeAUv3) {
          let row = store.instances.rows[index]
          AUv3View(instance: row.instance)
            .id(row.instance.id)
        } else {
          Text("No AUv3 instance selected")
            .frame(maxHeight: .infinity)
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
    .safeAreaPadding(16)
  }
}

private let log = Logger(category: "Root")

#Preview {
  RootView.preview
}
