/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller managing the list of audio units.
*/

import Cocoa

class ListViewController: NSViewController {

    // Automatically set by HostViewController
    weak var coordinator: Coordinator!
    
    var audioUnitComponents = [Component]() {
        didSet {
            audioUnitTable.reloadData()
        }
    }

    @IBOutlet weak var topBarView: BarView!
    @IBOutlet weak var auTypeSegmentedControl: NSSegmentedControl!

    var topConstraint: NSLayoutConstraint?
    @IBOutlet weak var audioUnitTable: NSTableView!

    @IBAction func selectAudioUnitType(_ sender: NSSegmentedControl) {
        let isEffect = auTypeSegmentedControl.selectedSegment == 0
        coordinator.didChangeAudioUnitType(to: isEffect ? .effect : .instrument)
    }

    override func updateViewConstraints() {
        // Always call superclass implementation
        defer {
            super.updateViewConstraints()
        }

        guard topConstraint == nil else { return }

        // Position the segmented control below the title/toolbar area.
        // The segmented control's top constraint is set to be removed at build time
        // to prevent a conflict with this constraint.
        let layoutGuide = view.window?.contentLayoutGuide as AnyObject
        if let contentAnchor = layoutGuide.topAnchor {
            topConstraint = topBarView.topAnchor.constraint(equalTo: contentAnchor, constant: 4.0)
            topConstraint?.isActive = true
        }
    }
}

extension ListViewController: NSTableViewDataSource, NSTableViewDelegate {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return audioUnitComponents.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn,
            let result = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? NSTableCellView else { return nil }

        result.textField?.stringValue = audioUnitComponents[row].name

        return result
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }
        coordinator.didSelectComponent(at: tableView.selectedRow)
    }
}
