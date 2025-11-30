// Copyright © 2025 Brad Howes. All rights reserved.

import AudioToolbox
import ComposableArchitecture
import Foundation
import Support
import SwiftUI
import TypedFullState


@Reducer
public struct AUv3Button {

  @ObservableState
  public struct State: Equatable, Identifiable {
    public typealias ID = AUv3Instance.ID
    public var instance: AUv3Instance
    public var id: ID { instance.id }

    public init(instance: AUv3Instance) {
      self.instance = instance
    }
  }

  @Shared(.activeAUv3) var activeAUv3

  public enum Action {
    case activateButtonTapped
    case delegate(Delegate)
    case deleteButtonTapped

    @CasePathable
    public enum Delegate {
      case activate(instance: AUv3Instance)
      case delete(id: State.ID)
    }
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      log.info("reduce \(action)")
      switch action {
      case .activateButtonTapped: return activateButtonTapped(&state)
      case .delegate: return .none
      case .deleteButtonTapped: return deleteButtonTapped(&state)
      }
    }
  }
}

extension AUv3Button {

  private func activateButtonTapped(_ state: inout State) -> Effect<Action> {
    $activeAUv3.withLock { $0 = state.id }
    return .send(.delegate(.activate(instance: state.instance)))
  }

  private func deleteButtonTapped(_ state: inout State) -> Effect<Action> {
    return .send(.delegate(.delete(id: state.id)))
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
        Text(store.instance.name)
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
  }
}

extension AUv3ButtonView {

  static var preview: some View {
    prepareDependencies {
      $0.uuid = .incrementing
      $0.componentDescription = .previewValue
    }

    @Dependency(\.uuid) var uuid
    @Dependency(\.componentDescription) var componentDescription

    return VStack {
      List {
        AsyncModel { instance in
          AUv3ButtonView(
            store: Store(
              initialState: .init(
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

private let log = Logger(category: "AUv3Button")

#Preview {
  AUv3ButtonView.preview
}
