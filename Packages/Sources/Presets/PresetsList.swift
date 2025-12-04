// Copyright © 2025 Brad Howes. All rights reserved.

import AudioToolbox
import ComposableArchitecture
import Dependencies
import DependenciesMacros
import Support
import SwiftUI
import TypedFullState

@Reducer
public struct PresetsList {

  @Reducer
  public enum Destination {
    case presetEditor(PresetEditor)
  }

  @ObservableState
  public struct State: Equatable {
    @Presents public var destination: Destination.State?
    public var rows: IdentifiedArrayOf<PresetButton.State>

    public init(rows: IdentifiedArrayOf<PresetButton.State> = []) {
      self.rows = rows
    }
  }

  public enum Action {
    case addButtonTapped
    case destination(PresentationAction<Destination.Action>)
    case initialize
    case rows(IdentifiedActionOf<PresetButton>)
  }

  public init() {}

  @Dependency(\.uuid) var uuid
  @Dependency(\.presetsStore) var presetsStore

  public var body: some ReducerOf<Self> {

    Reduce { state, action in
      log.info("reduct \(action)")
      switch action {

      case .addButtonTapped:
        return addButtonTapped(&state)

      case .destination(.presented(.presetEditor(.delegate(.accepted(let name))))):
        let id = state.destination?.presetEditor?.id
        let index = state.rows.firstIndex(where: {$0.preset.id == id})
        log.info("state.destination?.presetEditor?.id: \(String(describing: id))")
        log.info("\(String(describing: index))")
        if let index {
          state.rows[index].preset.name = name
        }
        return .none

      case .destination:
        return .none

      case .initialize:
        return initialize(&state)

      case .rows(.element(id: let id, action: .delegate(let action))):
        return processRowAction(&state, id: id, action: action)

      case .rows:
        return .none
      }
    }
    .forEach(\.rows, action: \.rows) {
      PresetButton()
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

extension PresetsList {

  private func addButtonTapped(_ state: inout State) -> Effect<Action> {
    state.rows.append(PresetButton.State(preset: .init(name: "New Preset", id: uuid(), fullStateCollection: .init())))
    return .none
  }

  private func initialize(_ state: inout State) -> Effect<Action> {
    guard let data = presetsStore.restore() else {
      state.rows = []
      save(state)
      return .none
    }

    if let presets = try? JSONDecoder().decode(Array<Preset>.self, from: data) {
      state.rows = .init(uniqueElements: presets.map { .init(preset: $0) })
    }

    return .none
  }

  private func processRowAction(
    _ state: inout State,
    id: PresetButton.State.ID,
    action: PresetButton.Action.Delegate
  ) -> Effect<Action> {
    log.info("reduce \(action)")
    switch action {

    case .activate(fullStates: let fullStates):
      log.info("activate: \(fullStates)")
      break

    case .delete(id: let id):
      state.rows.remove(id: id)
      break

    case .edit(id: let id, name: let name):
      state.destination = .presetEditor(.init(id: id, name: name))
      break
    }
    return .none
  }

  private func save(_ state: State) {
    if let data = try? JSONEncoder().encode(state.rows.map(\.preset)) {
      presetsStore.save(data)
    }
  }
}

extension PresetsList.Destination.State: Equatable {}

public struct PresetsListView: View {
  @Bindable private var store: StoreOf<PresetsList>

  public init(store: StoreOf<PresetsList>) {
    self.store = store
  }

  public var body: some View {
    VStack {
      HStack {
        Text("Presets")
        Spacer()
        Button {
          store.send(.addButtonTapped)
        } label: {
          Text("Add")
        }
      }
      List {
        ForEach(store.scope(state: \.rows, action: \.rows)) { store in
          PresetButtonView(store: store)
        }
      }
    }
    .task {
      await store.send(.initialize).finish()
    }
    .sheet(item: $store.scope(state: \.destination?.presetEditor, action: \.destination.presetEditor)) {
      PresetEditorView(store: $0)
    }
  }
}

#if DEBUG

extension PresetsListView {

  static var preview: some View {
    prepareDependencies {
      $0.uuid = .incrementing
      $0.presetsStore = .previewValue
      return VStack {
        PresetsListView(store: Store(initialState: .init()) { PresetsList() })
      }
    }
  }
}

#Preview("PresetsList") {
  PresetsListView.preview
    .padding()
}

#endif // DEBUG

private let log = Logger(category: "PresetsList")
