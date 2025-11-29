// Copyright © 2025 Brad Howes. All rights reserved.

import Dependencies
import DependenciesMacros
import Foundation
import IdentifiedCollections

@DependencyClient
public struct PresetsStore: Sendable {
  static let userDefaultsKey = "Presets"

  public let save: @Sendable (Data) -> Void
  public let restore: @Sendable () -> Data?
  public let clear: @Sendable () -> Void
}

extension PresetsStore: DependencyKey {

  public static var liveValue: PresetsStore {
    .init(
      save: { UserDefaults.standard.set($0, forKey: Self.userDefaultsKey) },
      restore: { UserDefaults.standard.data(forKey: Self.userDefaultsKey) },
      clear: { UserDefaults.standard.removeObject(forKey: Self.userDefaultsKey) }
    )
  }

  public static var previewValue: PresetsStore {
    .init(
      save: {_ in
      },
      restore: {
        @Dependency(\.uuid) var uuid
        let mockData: IdentifiedArrayOf<Preset> = [
          .init(
            name: "First",
            id: uuid(),
            fullStateCollection: [["a": .int(value: 1), "b": .double(value: 0.3)],
                                  ["a": .int(value: 2), "b": .double(value: 0.4)],
                                  ["a": .int(value: 3), "b": .double(value: 0.5)]]
          ),
          .init(
            name: "Second",
            id: uuid(),
            fullStateCollection: [["a": .int(value: 4), "b": .double(value: 0.6)],
                                  ["a": .int(value: 5), "b": .double(value: 0.7)],
                                  ["a": .int(value: 6), "b": .double(value: 0.8)]]
          ),
          .init(
            name: "Third",
            id: uuid(),
            fullStateCollection: [["a": .int(value: 7), "b": .double(value: 0.9)],
                                  ["a": .int(value: 8), "b": .double(value: 1.0)],
                                  ["a": .int(value: 9), "b": .double(value: 1.1)]]
          ),
          .init(
            name: "Fourth",
            id: uuid(),
            fullStateCollection: [["a": .int(value: 7), "b": .double(value: 0.9)],
                                  ["a": .int(value: 8), "b": .double(value: 1.0)],
                                  ["a": .int(value: 9), "b": .double(value: 1.1)]]
          ),
        ]
        return try? JSONEncoder().encode(mockData)
      },
      clear: {}
    )
  }

  public static var testValue: PresetsStore {
    .init(
      save: { _ in unimplemented("save") },
      restore: { unimplemented("save", placeholder: nil) },
      clear: { unimplemented("clear") }
    )
  }
}

extension DependencyValues {
  public var presetsStore: PresetsStore {
    get { self[PresetsStore.self] }
    set { self[PresetsStore.self] = newValue }
  }
}

private let log = Logger(category: "PresetsStore")
