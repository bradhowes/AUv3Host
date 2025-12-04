// Copyright © 2025 Brad Howes. All rights reserved.

import AUv3s
import Support
import SwiftUI

public struct AUv3View: UIViewControllerRepresentable {
  private let id: UUID
  private let instance: AUv3Instance

  public init(id: UUID, instance: AUv3Instance) {
    self.id = id
    self.instance = instance
    log.info("AUv3View - init \(id) \(instance)")
  }

  public func makeUIViewController(context: Context) -> UIViewController {
    log.info("makeUIViewController - \(instance)")
    return instance.viewController
  }

  public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    log.info("updateUIViewController - \(instance)")
  }
}

private let log = Logger(category: "AUv3View")
