/*
See LICENSE folder for this sample’s licensing information.

Abstract:
NSAlert extensions to simplify showing alert messages in the app.
*/
import Cocoa

extension NSAlert {

    class func showError(with message: String) {
        let alert = self.init()
        alert.messageText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    class func showConfirmDeletePreset(named name: String, completion: @escaping (Bool) -> Void) {
        guard let window = NSApplication.shared.mainWindow else { return }
        let alert = self.init()
        alert.messageText = "Are you sure you want to delete this preset?"
        alert.informativeText = "Deleting '\(name)' cannot be undone."
        
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        alert.beginSheetModal(for: window) { response in
            completion(response == .alertFirstButtonReturn)
        }
    }
}
