// Copyright © 2021 Apple. All rights reserved.

import AudioToolbox
import Foundation
import TypedFullState

public struct PresetDocument: Codable {
  public let name: String
  public let uuid: UUID
  public fileprivate(set) var fullStateCollection: TypedFullStateCollection

  public init(name: String, uuid: UUID, fullStateCollection: TypedFullStateCollection) {
    self.name = name
    self.uuid = uuid
    self.fullStateCollection = fullStateCollection
  }
}

public typealias PresetDocumentCollection = [PresetDocument]

/// Provider of UUID values. Used for testing with predictable values.
public typealias UUIDGenerator = () -> UUID

/// Protocol for entities that manage the data storage of a PresetDocumentManager
public protocol PresetDocumentManagerStore {
  func save(data: Data)
  func restore() -> Data?
  func clear()
}

/// Default manager of the PresetDocumentManager state storage. Uses UserDefaults.
public struct PresetDocumentManagerStoreDefault: PresetDocumentManagerStore {
  private let userDefaultsKey = "PresetDocumentManagerStoreKey"

  public func save(data: Data) { UserDefaults.standard.set(data, forKey: userDefaultsKey) }
  public func restore() -> Data? { UserDefaults.standard.data(forKey: userDefaultsKey) }
  public func clear() { UserDefaults.standard.removeObject(forKey: userDefaultsKey) }
}

public class PresetDocumentManager: Codable {
  static var uuidGenerator: UUIDGenerator = { UUID() }
  static var dataStore: PresetDocumentManagerStore = PresetDocumentManagerStoreDefault()

  private var presetDocs = PresetDocumentCollection()

  public class func make(_ uuidGenerator: @escaping UUIDGenerator = { UUID() }) -> PresetDocumentManager {
    if let data = dataStore.restore(),
       let presetDocManager = try? JSONDecoder().decode(PresetDocumentManager.self, from: data) {
      return presetDocManager
    }
    return .init()
  }

  public func makePreset(name: String) -> UUID {
    let uuid = Self.uuidGenerator()
    let doc = PresetDocument(name: name, uuid: uuid, fullStateCollection: [])
    presetDocs.append(doc)
    return uuid
  }

  public var count: Int { presetDocs.count }

  public func name(at index: Int) -> String { presetDocs[index].name }

  public func uuid(at index: Int) -> UUID { presetDocs[index].uuid }

  public func fullStateCollection(at index: Int) -> FullStateCollection {
    FullStateCollection.make(from: presetDocs[index].fullStateCollection)
  }

  public func setFullStateCollection(_ fullStateCollection: TypedFullStateCollection, for uuid: UUID) {
    guard let index = presetDocs.firstIndex(where: { $0.uuid == uuid }) else { return }
    presetDocs[index].fullStateCollection = fullStateCollection
    save()
  }

  public func remove(at index: Int) {
    presetDocs.remove(at: index)
    save()
  }
}

private extension PresetDocumentManager {

  func save() {
    if let data = try? JSONEncoder().encode(self) {
      Self.dataStore.save(data: data)
    } else {
      Self.dataStore.clear()
    }
  }
}
