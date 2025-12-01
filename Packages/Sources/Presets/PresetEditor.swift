// Copyright © 2025 Brad Howes. All rights reserved.

import ComposableArchitecture
import SwiftUI

@Reducer
public struct PresetEditor {

  @ObservableState
  public struct State: Equatable {
    public let id: Preset.ID
    public var name: String

    public init(id: Preset.ID, name: String) {
      self.id = id
      self.name = name
    }
  }

  @CasePathable
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case delegate(Delegate)
    case cancelButtonTapped
    case acceptButtonTapped

    @CasePathable
    public enum Delegate {
      case accepted(String)
      case cancelled
    }
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {

      case .cancelButtonTapped:
        return cancelled(&state)

      case .delegate:
        return .none

      case .acceptButtonTapped:
        return accepted(&state)

      default:
        return .none
      }
    }
  }
}

extension PresetEditor {

  private func accepted(_ state: inout State) -> Effect<Action> {
    return .run { [name = state.name] send in
      @Dependency(\.dismiss) var dismiss
      await send(.delegate(.accepted(name)))
      await dismiss()
    }
  }

  private func cancelled(_ state: inout State) -> Effect<Action> {
    return .run { send in
      @Dependency(\.dismiss) var dismiss
      await send(.delegate(.cancelled))
      await dismiss()
    }
  }
}

public struct PresetEditorView: View {
  @Bindable private var store: StoreOf<PresetEditor>

  public init(store: StoreOf<PresetEditor>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack {
      Form {
        HStack {
          Text("Name")
          TextField("", text: $store.name)
            .textFieldStyle(.roundedBorder)
        }
      }
      .navigationTitle("Preset")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            store.send(.cancelButtonTapped, animation: .default)
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Accept") {
            store.send(.acceptButtonTapped, animation: .default)
          }
        }
      }
    }
  }
}

#if DEBUG

extension PresetEditorView {
  static var preview: some View {
    PresetEditorView(store: Store(initialState: .init(id: UUID(), name: "Testing")) { PresetEditor() })
  }
}

#Preview {
  PresetEditorView.preview
}

#endif // DEBUG
