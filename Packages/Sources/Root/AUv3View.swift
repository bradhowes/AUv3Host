// Copyright © 2025 Brad Howes. All rights reserved.

import AUv3s
import SwiftUI

public struct AUv3View: UIViewControllerRepresentable {
  private let instance: AUv3Instance

  public init(instance: AUv3Instance) {
    self.instance = instance
  }

  public func makeUIViewController(context: Context) -> UIViewController {
    instance.viewController
  }

  public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {

  }
}
