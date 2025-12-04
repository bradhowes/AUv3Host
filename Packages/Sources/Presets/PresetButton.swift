// Copyright © 2025 Brad Howes. All rights reserved.

import ComposableArchitecture
import Foundation
import Sharing
import Support
import SwiftUI
import TypedFullState


@Reducer
public struct PresetButton {

  @ObservableState
  public struct State: Equatable, Identifiable {
    public typealias ID = Preset.ID
    public var preset: Preset
    public var id: ID { preset.id }

    public init(preset: Preset) {
      self.preset = preset
    }
  }

  @Shared(.activePreset) var activePreset

  public enum Action {
    case activateButtonTapped
    case delegate(Delegate)
    case deleteButtonTapped
    case editButtonTapped

    @CasePathable
    public enum Delegate {
      case activate(fullStates: TypedFullStateCollection)
      case delete(id: State.ID)
      case edit(id: State.ID, name: String)
    }
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      log.info("reduce \(action)")
      switch action {
      case .activateButtonTapped: return activateButtonTapped(&state)
      case .delegate: return .none
      case .deleteButtonTapped: return deleteButtonTapped(&state)
      case .editButtonTapped: return editButtonTapped(&state)
      }
    }
  }
}

extension PresetButton {

  private func activateButtonTapped(_ state: inout State) -> Effect<Action> {
    $activePreset.withLock { $0 = state.id }
    return .send(.delegate(.activate(fullStates: state.preset.fullStateCollection)))
  }

  private func deleteButtonTapped(_ state: inout State) -> Effect<Action> {
    return .send(.delegate(.delete(id: state.id)))
  }

  private func editButtonTapped(_ state: inout State) -> Effect<Action> {
    return .send(.delegate(.edit(id: state.id, name: state.preset.name)))
  }
}

public struct PresetButtonView: View {
  @State private var store: StoreOf<PresetButton>
  @Shared(.activePreset) var activePreset

  public init(store: StoreOf<PresetButton>) {
    self.store = store
  }

  public var body: some View {
    HStack {
      Button {
        store.send(.activateButtonTapped)
      } label: {
        Text(store.preset.name)
      }
      Spacer()
      if store.id == activePreset {
        Image(systemName: "checkmark")
      }
    }
    .swipeActions(edge: .leading, allowsFullSwipe: false) {
      Button {
        store.send(.editButtonTapped)
      } label: {
        Image(systemName: "pencil")
          .tint(.cyan)
      }
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      Button {
        store.send(.deleteButtonTapped, animation: .default)
      } label: {
        Image(systemName: "trash")
          .tint(.red)
      }
    }
  }
}

#if DEBUG

extension PresetButtonView {

  static var preview: some View {
    prepareDependencies {
      $0.uuid = .incrementing
      @Dependency(\.uuid) var uuid
      return VStack {
        List {
          PresetButtonView(
            store: Store(
              initialState: .init(
                preset: .init(
                  name: "First",
                  id: uuid(),
                  fullStateCollection: .init()
                )
              )
            ) {
              PresetButton()
            }
          )
          PresetButtonView(
            store: Store(
              initialState: .init(
                preset: .init(
                  name: "Second",
                  id: uuid(),
                  fullStateCollection: .init()
                )
              )
            ) {
              PresetButton()
            }
          )
          PresetButtonView(
            store: Store(
              initialState: .init(
                preset: .init(
                  name: "Third",
                  id: uuid(),
                  fullStateCollection: .init()
                )
              )
            ) {
              PresetButton()
            }
          )
        }
      }
    }
  }
}

#Preview("PresetButtons") {
  PresetButtonView.preview
}

#endif // DEBUG

private let log = Logger(category: "PresetButton")
