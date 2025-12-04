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
    case delegate(Delegate)
    case initialize
    case rows(IdentifiedActionOf<AUv3Button>)
    case playNote
    case settingsButtonTapped
    case startLoops
    case stopLoops

    @CasePathable
    public enum Delegate {
      case added(instance: AUv3Instance)
      case removed(instance: AUv3Instance)
      case settings
    }
  }

  public init() {}

  @Dependency(\.uuid) var uuid

  public var body: some ReducerOf<Self> {

    Reduce { state, action in
      // log.info("reduce \(action)")
      switch action {

      case .add(instance: let instance):
        return add(&state, instance: instance)

      case .delegate:
        return .none

      case .initialize:
        return initialize(&state)

      case .playNote:
        return playNote(&state)

      case .rows(.element(id: let id, action: .delegate(let action))):
        return processRowAction(&state, id: id, action: action)

      case .rows:
        return .none

      case .settingsButtonTapped:
        return .send(.delegate(.settings))

      case .startLoops:
        return startLoops(&state)

      case .stopLoops:
        return stopLoops(&state)
      }
    }
    .forEach(\.rows, action: \.rows) {
      AUv3Button()
    }
  }
}

extension AUv3sList {

  private func add(_ state: inout State, instance: AUv3Instance) -> Effect<Action> {
    state.rows.append(.init(id: uuid(), instance: instance))
    return .send(.delegate(.added(instance: instance)))
  }

  private func initialize(_ state: inout State) -> Effect<Action> {
    @Shared(.auv3InstanceCount) var auv3InstanceCount
    log.info("initialize: \(auv3InstanceCount)")
    if state.rows.count < auv3InstanceCount {
      return .merge((0..<(auv3InstanceCount - state.rows.count)).map { _ in makeInstance(&state) })
    } else if state.rows.count > auv3InstanceCount {
      return .merge((0..<(auv3InstanceCount - state.rows.count)).map { _ in removeInstance(&state) })
    } else {
      return .none
    }
  }

  private func makeInstance(_ state: inout State) -> Effect<Action> {
    .run { send in
      @Dependency(\.componentDescription) var componentDescription
      let instance = try await AUv3Instance.make(component: componentDescription)
      await send(.add(instance: instance))
    }
  }

  private func removeInstance(_ state: inout State) -> Effect<Action> {
    guard let button = state.rows.popLast() else { return .none }
    return .send(.delegate(.removed(instance: button.instance)))
  }

  private func playNote(_ state: inout State) -> Effect<Action> {
    @Shared(.activeAUv3) var activeAUv3
    guard let activeAUv3 else { return .none }
    guard let button = state.rows[id: activeAUv3] else { return .none }
    button.instance.audioUnit.auAudioUnit.playNote()
    return .none
  }

  private func processRowAction(
    _ state: inout State,
    id: AUv3Button.State.ID,
    action: AUv3Button.Action.Delegate
  ) -> Effect<Action> {
    // log.info("reduce \(action)")
    if case .delete(id: let id) = action {
      guard let removed = state.rows.remove(id: id) else { return .none }
      @Shared(.activeAUv3) var activeAUv3
      if id == activeAUv3 {
        $activeAUv3.withLock { $0 = state.rows.last?.id }
      }
      return .send(.delegate(.removed(instance: removed.instance)))
    }
    return .none
  }

  private func startLoops(_ state: inout State) -> Effect<Action> {
    .merge(state.rows.map {
      reduce(into: &state, action: .rows(.element(id: $0.id, action: .startLoop)))
    })
  }

  private func stopLoops(_ state: inout State) -> Effect<Action> {
    .merge(state.rows.map {
      reduce(into: &state, action: .rows(.element(id: $0.id, action: .stopLoop)))
    })
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
          store.send(.settingsButtonTapped)
        } label: {
          Image(systemName: "gear")
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

#if DEBUG

extension AUv3sListView {

  static var preview: some View {
    prepareDependencies {
      $0.uuid = .incrementing

      @Shared(.auv3InstanceCount) var auv3InstanceCount
      $auv3InstanceCount.withLock { $0 = 3 }

      return VStack {
        AUv3sListView(store: Store(initialState: .init()) { AUv3sList() })
      }
    }
  }
}

#Preview("AUv3sList") {
  AUv3sListView.preview
    .padding()
}

#endif // DEBUG

private let log = Logger(category: "AUv3sList")
