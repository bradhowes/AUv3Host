// Copyright © 2025 Brad Howes. All rights reserved.

import AudioToolbox
import ComposableArchitecture
import Sharing
import Support
import SwiftUI
import TypedFullState

@Reducer
public struct AUv3sList {

  @ObservableState
  public struct State: Equatable {
    public var rows: IdentifiedArrayOf<AUv3Button.State>

    public init(rows: IdentifiedArrayOf<AUv3Button.State> = []) {
      self.rows = rows
    }
  }

  public enum Action {
    case add(instance: AUv3Instance)
    case addButtonTapped
    case initialize
    case rows(IdentifiedActionOf<AUv3Button>)
  }

  public init() {}

  @Dependency(\.uuid) var uuid

  public var body: some ReducerOf<Self> {

    Reduce { state, action in
      log.info("reduce \(action)")
      switch action {

      case .add(instance: let instance):
        return add(&state, instance: instance)

      case .addButtonTapped:
        return addButtonTapped(&state)

      case .initialize:
        return initialize(&state)

      case .rows(.element(id: let id, action: .delegate(let action))):
        return processRowAction(&state, id: id, action: action)

      case .rows:
        return .none
      }
    }
    .forEach(\.rows, action: \.rows) {
      AUv3Button()
    }
  }
}

extension AUv3sList {

  private func add(_ state: inout State, instance: AUv3Instance) -> Effect<Action> {
    state.rows.append(.init(instance: instance))
    return .none
  }

  private func addButtonTapped(_ state: inout State) -> Effect<Action> {
    .run { send in
      @Dependency(\.componentDescription) var componentDescription
      let instance = try await AUv3Instance.make(component: componentDescription)
      await send(.add(instance: instance))
    }
  }

  private func initialize(_ state: inout State) -> Effect<Action> {
    @Shared(.auv3InstanceCount) var auv3InstanceCount
    log.info("initialize: \(auv3InstanceCount)")
    return .merge((0..<min(1, auv3InstanceCount)).map { _ in addButtonTapped(&state) })
  }

  private func processRowAction(
    _ state: inout State,
    id: AUv3Button.State.ID,
    action: AUv3Button.Action.Delegate
  ) -> Effect<Action> {
    log.info("reduce \(action)")
    switch action {

    case .activate(instance: let instance):
      log.info("activate: \(instance)")
      break

    case .delete(id: let id):
      state.rows.remove(id: id)
      @Shared(.activeAUv3) var activeAUv3
      if id == activeAUv3 {
        $activeAUv3.withLock { $0 = state.rows.last?.id }
      }
      break
    }

    return .none
  }
}

public struct AUv3sListView: View {
  private var store: StoreOf<AUv3sList>

  public init(store: StoreOf<AUv3sList>) {
    self.store = store
  }

  public var body: some View {
    VStack {
      HStack {
        Text("AUv3 Instances")
        Spacer()
        Button {
          store.send(.addButtonTapped)
        } label: {
          Text("Add")
        }
      }
      List {
        ForEach(store.scope(state: \.rows, action: \.rows)) { store in
          AUv3ButtonView(store: store)
        }
      }
    }
    .task {
      await store.send(.initialize).finish()
    }
  }
}

extension AUv3sListView {

  static var preview: some View {
    prepareDependencies {
      $0.uuid = .incrementing
    }
    return VStack {
      AUv3sListView(store: Store(initialState: .init()) { AUv3sList() })
    }
  }
}

private let log = Logger(category: "AUv3sList")

#Preview {
  AUv3sListView.preview
}
