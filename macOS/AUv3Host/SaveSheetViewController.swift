/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller managing the "Save Preset" sheet.
*/

import Cocoa

class SaveSheetViewController: NSViewController {

    @IBOutlet weak var presetNameField: NSTextField!

    var presetName: String? {
        let name = presetNameField.stringValue
        return !name.isEmpty ? name : nil
    }

    @IBAction func save(_ sender: Any) {
        presentingViewController?.dismiss(self)
    }

    @IBAction func cancel(_ sender: Any) {
        presetNameField.objectValue = nil
        presentingViewController?.dismiss(self)
    }

}
