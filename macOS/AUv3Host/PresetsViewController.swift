/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller presenting the list of factory and user presets.
*/

import Cocoa

class PresetsViewController: NSViewController {

    weak var coordinator: Coordinator!

    @IBOutlet weak var presetTypeSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var presetsTableView: NSTableView!

    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!

    @IBOutlet weak var topBarView: BarView!
    var topConstraint: NSLayoutConstraint?

    var isFactoryPresetsSelected: Bool {
        return presetTypeSegmentedControl.selectedSegment == PresetType.factory.rawValue
    }

    var isUserPresetsSelected: Bool {
        return presetTypeSegmentedControl.selectedSegment == PresetType.user.rawValue
    }

    var userPresets = [Preset]() {
        didSet {
            if isUserPresetsSelected { visiblePresets = userPresets }
        }
    }

    var factoryPresets = [Preset]() {
        didSet {
            if isFactoryPresetsSelected { visiblePresets = factoryPresets }
        }
    }

    var visiblePresets = [Preset]() {
        didSet {
            presetsTableView.reloadData()
        }
    }

    var supportsUserPresets = false {
        didSet {
            updateButtonState(isUserPresetsSelected && supportsUserPresets)
        }
    }

    @IBAction func selectPresetType(_ sender: NSSegmentedControl) {
        updateButtonState(isUserPresetsSelected && supportsUserPresets)
        visiblePresets = isUserPresetsSelected ? userPresets : factoryPresets
        deleteButton.isEnabled = supportsUserPresets && isUserPresetsSelected && !visiblePresets.isEmpty
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(userPresetsChanged), name: .userPresetsChanged, object: nil)
        presetTypeSegmentedControl.selectedSegment = PresetType.factory.rawValue
        updateButtonState(false)
        [addButton, deleteButton].forEach { $0.isEnabled = false }
        selectPresetType(presetTypeSegmentedControl)
    }

    @objc
    func userPresetsChanged(notification: Notification) {
        guard let change = notification.object as? UserPresetsChange else { return }

        let selectedRow = presetsTableView.selectedRow
        var rowIndexes: IndexSet?

        switch change.type {
        case .save:
            // This app appends new user presets to the end of the list.
            // Select the *new* last row after the reload occurs.
            rowIndexes = IndexSet(integer: change.userPresets.count - 1)
        case .delete:
            // If the user deleted a preset, select the preceding row.
            rowIndexes = IndexSet(integer: selectedRow == 0 ? 0 : selectedRow - 1)
        case .external:
            // If an external change occurred (For example, on macOS a user can
            // manually add or remove a preset from the AUPreset folder), determine
            // if the user's selection can be preserved after the reload.
            if selectedRow >= 0 {
                let selectedName = userPresets[selectedRow].name
                let result = change.userPresets.enumerated().first(where: { $0.element.name == selectedName })
                // The selection still exists in the list. Capture the row index.
                if let result = result, result.offset >= 0 {
                    rowIndexes = IndexSet(integer: result.offset)
                }
                // The selected row no longer exists in the new userPresets. Select the preceding row.
                else {
                    rowIndexes = IndexSet(integer: selectedRow == 0 ? 0 : selectedRow - 1)
                }
            }
        default: ()
        }

        // Setting this property will cause a table reload
        userPresets = change.userPresets

        // Select the row based on the given use case above.
        if let rows = rowIndexes {
            presetsTableView.selectRowIndexes(rows, byExtendingSelection: false)
        }

        // Update the delete button state based on if there are presets to delete
        deleteButton.isEnabled = !visiblePresets.isEmpty
    }

    func updateButtonState(_ state: Bool) {
        [addButton, deleteButton].forEach { $0.isEnabled = state }
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
    
    override func dismiss(_ viewController: NSViewController) {
        defer {
            super.dismiss(viewController)
        }
        guard let sheet = viewController as? SaveSheetViewController, let presetName = sheet.presetName else {
            print("Canceled saving preset")
            return
        }
        coordinator.saveUserPreset(Preset(name: presetName))
    }
    
    @IBAction func deletePreset(_ sender: Any) {
        let preset = userPresets[presetsTableView.selectedRow]
        NSAlert.showConfirmDeletePreset(named: preset.name) { shouldDelete in
            if shouldDelete {
                self.coordinator.deleteUserPreset(preset)
            }
        }
    }
}

extension PresetsViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return visiblePresets.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn,
            let result = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? NSTableCellView else { return nil }
        
        result.textField?.stringValue = visiblePresets[row].name
        
        return result
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }
        coordinator.didSelectPreset(visiblePresets[tableView.selectedRow])
    }
}
