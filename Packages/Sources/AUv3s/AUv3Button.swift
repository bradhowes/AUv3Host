// Copyright © 2025 Brad Howes. All rights reserved.

@preconcurrency import AudioToolbox
import ComposableArchitecture
import Foundation
import Support
import SwiftUI
import TypedFullState

@Reducer
public struct AUv3Button {

  @ObservableState
  public struct State: Equatable, Identifiable {
    public typealias ID = UUID
    public let id: ID
    public let instance: AUv3Instance
    public var name: String {
      didSet {
        log.info("name (set) - \(id.uuidString) name: \(name)")
      }
    }

    public var monitorCancelId: String { id.uuidString + ".monitor" }
    public var loopCancelId: String { id.uuidString + ".loop" }

    public init(id: UUID, instance: AUv3Instance) {
      self.id = id
      self.instance = instance
      self.name = instance.name
      log.info("init - \(id.uuidString) name: \(name)")
    }
  }

  @Shared(.activeAUv3) var activeAUv3

  public enum Action {
    case activateButtonTapped
    case delegate(Delegate)
    case deleteButtonTapped
    case nameChanged(id: UUID, value: String)
    case playNote
    case startLoop
    case startMonitoring
    case stopLoop
    case stopMonitoring

    @CasePathable
    public enum Delegate {
      case delete(id: State.ID)
    }
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .activateButtonTapped: return activateButtonTapped(&state)
      case .delegate: return .none
      case .deleteButtonTapped: return deleteButtonTapped(&state)
      case .nameChanged(id: let id, value: let value): return nameChanged(&state, id: id, value: value)
      case .playNote: return playNote(&state)
      case .startLoop: return startLoop(&state)
      case .startMonitoring: return startMonitoring(&state)
      case .stopLoop: return stopLoop(&state)
      case .stopMonitoring: return stopMonitoring(&state)
      }
    }
  }

}

extension AUv3Button {

  private func activateButtonTapped(_ state: inout State) -> Effect<Action> {
    log.info("activateButtonTapped - \(state.id.uuidString)")
    $activeAUv3.withLock { $0 = state.id }
    return .none
  }

  private func deleteButtonTapped(_ state: inout State) -> Effect<Action> {
    return .send(.delegate(.delete(id: state.id)))
  }

  private func nameChanged(_ state: inout State, id: UUID, value: String) -> Effect<Action> {
    log.info("nameChanged \(id.uuidString): \(value)")
    log.info("state.id: \(state.id.uuidString)")
    state.name = value
    return .none
  }

  private func playNote(_ state: inout State) -> Effect<Action> {
    log.info("playNote - \(state.id.uuidString)")
    state.instance.audioUnit.auAudioUnit.playNote()
    return .none
  }

  private func startLoop(_ state: inout State) -> Effect<Action> {
    .run { [audioUnit = state.instance.audioUnit.auAudioUnit] send in
      await audioUnit.playLoop()
    }.cancellable(id: state.loopCancelId)
  }

  private func startMonitoring(_ state: inout State) -> Effect<Action> {
    log.info("startMonitoring \(state.id.uuidString) - \(state.instance)")
    return .run { [audioUnit = state.instance.audioUnit.auAudioUnit, id = state.id] send in
      var lastValue = ""
      while Task.isCancelled == false {
        if let value = audioUnit.audioUnitShortName {
          if value != lastValue {
            lastValue = value
            await send(.nameChanged(id: id, value: value))
          }
        }
        try await Task.sleep(for: .seconds(1))
      }
      log.info("startMonitoring END - \(id.uuidString)")
    }.cancellable(id: state.monitorCancelId, cancelInFlight: true)
  }

  private func stopLoop(_ state: inout State) -> Effect<Action> {
    .cancel(id: state.loopCancelId)
  }

  private func stopMonitoring(_ state: inout State) -> Effect<Action> {
    log.info("stopMonitoring: \(state.id.uuidString)")
    return .cancel(id: state.monitorCancelId)
  }
}

public struct AUv3ButtonView: View {
  @State private var store: StoreOf<AUv3Button>
  @Shared(.activeAUv3) var activeAUv3

  public init(store: StoreOf<AUv3Button>) {
    self.store = store
  }

  public var body: some View {
    HStack {
      Button {
        store.send(.activateButtonTapped)
      } label: {
        Text(store.name)
      }
      Spacer()
      if store.id == activeAUv3 {
        Image(systemName: "checkmark")
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
    .task {
      await store.send(.startMonitoring).finish()
    }
  }
}

#if DEBUG

extension AUv3ButtonView {

  static var preview: some View {
    prepareDependencies {
      $0.uuid = .incrementing
      $0.componentDescription = .previewValue

      @Dependency(\.uuid) var uuid
      @Dependency(\.componentDescription) var componentDescription

      return VStack {
        List {
          AsyncModel { instance in
            AUv3ButtonView(
              store: Store(
                initialState: .init(
                  id: uuid(),
                  instance: instance
                )
              ) {
                AUv3Button()
              }
            )
          } model: {
            try await AUv3Instance.make(component: componentDescription)
          }
          AsyncModel { instance in
            AUv3ButtonView(
              store: Store(
                initialState: .init(
                  id: uuid(),
                  instance: instance
                )
              ) {
                AUv3Button()
              }
            )
          } model: {
            try await AUv3Instance.make(component: componentDescription)
          }
        }
      }
    }
  }
}

#Preview("AUv3Button") {
  AUv3ButtonView.preview
}

#endif // DEBUG

private let log = Logger(category: "AUv3Button")
