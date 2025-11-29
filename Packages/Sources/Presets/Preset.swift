// Copyright © 2025 Brad Howes. All rights reserved.

import Foundation
import TypedFullState

public struct Preset: Codable, Equatable, Identifiable {
  public typealias ID = UUID
  public let id: ID
  public var name: String
  public var fullStateCollection: TypedFullStateCollection

  public init(name: String, id: UUID, fullStateCollection: TypedFullStateCollection) {
    self.name = name
    self.id = id
    self.fullStateCollection = fullStateCollection
  }
}
