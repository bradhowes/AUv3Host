/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller presenting the main view.
*/

import Cocoa

protocol Coordinator: AnyObject {
    
    // User Preset Management
    func didSelectPreset(_ preset: Preset)
    func saveUserPreset(_ preset: Preset)
    func deleteUserPreset(_ preset: Preset)

    // Audio Unit component selection
    func didSelectComponent(at index: Int)
    func didChangeAudioUnitType(to type: AudioUnitType)
}

extension MainViewController: Coordinator {
    
    func didSelectPreset(_ preset: Preset) {
        audioUnitManager.currentPreset = preset
    }
    
    func saveUserPreset(_ preset: Preset) {
        do {
            try audioUnitManager.savePreset(preset)
        } catch {
            print(error.localizedDescription)
            showError(with: "Unable to save preset.")
        }
    }
    
    func deleteUserPreset(_ preset: Preset) {
        do {
            try audioUnitManager.deletePreset(preset)
        } catch {
            print(error.localizedDescription)
            showError(with: "Unable to delete preset.")
        }
    }

    func showError(with message: String) {
        NSAlert.showError(with: message)
    }
    
    func didChangeAudioUnitType(to type: AudioUnitType) {
        loadAudioUnits(ofType: type)
    }
    
    func didSelectComponent(at index: Int) {
        selectedIndex = index
        audioUnitManager.selectComponent(at: index) { result in
            switch result {
            case .success:
                self.loadViewController()
                self.loadPresets()
                self.presetsViewController.supportsUserPresets = self.audioUnitManager.supportsUserPresets
                self.hideToggleViewButton = !self.audioUnitManager.providesAlterativeViews
            case .failure(let error):
                print("Unable to select audio unit: \(error)")
            }
        }
    }
}

class MainViewController: NSSplitViewController {

    var selectedIndex = 0
    var audioUnitType = AudioUnitType.effect

    let audioUnitManager = AudioUnitManager()
    
    var hideToggleViewButton = false

    unowned var listViewController: ListViewController!
    unowned var componentViewController: ComponentViewController!
    unowned var presetsViewController: PresetsViewController!

    override var splitViewItems: [NSSplitViewItem] {
        didSet {
            splitViewItems.forEach {
                switch $0.viewController {
                case let viewController as ListViewController:
                    listViewController = viewController
                    listViewController.coordinator = self
                case let viewController as ComponentViewController:
                    componentViewController = viewController
                case let viewController as PresetsViewController:
                    presetsViewController = viewController
                    presetsViewController.coordinator = self
                default:
                    fatalError("Unsupported view controller type found")
                }
            }
        }
    }
    
    @IBAction func togglePane(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            toggleAudioUnits()
        case 1:
            togglePresets()
        default:
            print("Unknown segment selected: \(sender.selectedSegment)")
        }
    }
    
    @IBAction func togglePlayback(_ sender: NSButton) {
        audioUnitManager.togglePlayback()
    }

    @IBAction func toggleView(_ sender: NSButton) {
        audioUnitManager.toggleViewMode()
        componentViewController.view.layoutSubtreeIfNeeded()
    }

    func toggleAudioUnits() {
        guard let item = splitViewItem(for: listViewController) else { return }
        toggle(item: item)
    }
    
    func togglePresets() {
        guard let item = splitViewItem(for: presetsViewController) else { return }
        toggle(item: item)
    }
    
    func toggle(item: NSSplitViewItem) {
        item.animator().isCollapsed = !item.isCollapsed
        //splitView.layoutSubtreeIfNeeded()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        splitView.translatesAutoresizingMaskIntoConstraints = false
        loadAudioUnits()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.delegate = self
    }
    
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        guard item is ToggleToolbarItem else { return super.validateUserInterfaceItem(item) }
        return hideToggleViewButton
    }
    
    func loadAudioUnits(ofType type: AudioUnitType = .effect) {
        audioUnitType = type

        // Ensure audio playback is stopped before loading.
        audioUnitManager.stopPlayback()

        // Load audio units.
        audioUnitManager.loadAudioUnits(ofType: type) { [weak self] audioUnits in
            guard let self = self else { return }
            self.listViewController.audioUnitComponents = audioUnits
        }
    }
    
    @IBAction func toggleLoadInProcessOption(sender: NSMenuItem) {
        switch sender.state {
        case .on:
            sender.state = .off
            audioUnitManager.instantiationType = .outOfProcess
        default:
            sender.state = .on
            audioUnitManager.instantiationType = .inProcess
        }
    }

    func loadPresets() {
        presetsViewController.factoryPresets = audioUnitManager.factoryPresets
        presetsViewController.userPresets = audioUnitManager.userPresets
    }

    func loadViewController() {
        audioUnitManager.loadAudioUnitViewController() { viewController in
            // Determine if the user selected the "No Effect" row
            let isNoEffect = self.audioUnitType == .effect && self.selectedIndex == 0
            let labelText = isNoEffect ? "Please select an audio unit" :
                                         "No user interface"
            self.componentViewController.presentUserInterface(viewController?.view,
                                                              labelText: labelText)
        }
    }
}

// MARK: - NSWindowDelegate
extension MainViewController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        audioUnitManager.stopPlayback()
    }
}

// MARK: - Custom Views
class SplitView: NSSplitView {
    override var dividerThickness: CGFloat { return 0.5 }
}

class BarView: NSView {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.setFillColor(NSColor.windowBackgroundColor.cgColor)
        context.fill(dirtyRect)
    }
}

class ToggleToolbarItem: NSToolbarItem {
    override func validate() {
        if let control = self.view as? NSControl, let action = self.action,
            let validator = NSApp.target(forAction: action, to: self.target, from: self) as? NSUserInterfaceValidations {
            control.isHidden = validator.validateUserInterfaceItem(self)
        } else {
            super.validate()
        }
    }
}
