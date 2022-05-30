/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller managing the presentation of the audio unit user interface.
*/

import Cocoa

class ComponentViewController: NSViewController {

    @IBOutlet weak var containerView: NSView!
    @IBOutlet weak var feedbackLabel: NSTextField!

    func presentUserInterface(_ subview: NSView?, labelText: String) {
        containerView.subviews.filter { $0 !== feedbackLabel } .forEach {
            $0.removeFromSuperview()
        }

        if let subview = subview {
            containerView.addSubview(subview)
            subview.pinToSuperview()
        }

        feedbackLabel.stringValue = labelText
        feedbackLabel.isHidden = subview != nil
    }
}
