/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 The view controller presenting the main view.
 */

import UIKit
import AVFoundation
import CoreAudioKit
import AUv3Support
import AudioUnitHost
import PresetDocumentManager
import TypedFullState

class MainViewController: UIViewController {

  static var instanceCount: Int = max(UserDefaults.standard.integer(forKey: "instanceCount"), 1) {
    didSet {
      UserDefaults.standard.set(instanceCount, forKey: "instanceCount")
    }
  }

  let audioUnitHost = AudioUnitHost(count: MainViewController.instanceCount)

  @IBOutlet weak var instanceCountStepper: UIStepper!
  @IBOutlet weak var instanceCountLabel: UILabel!
  @IBOutlet weak var playScale: UIButton!
  @IBOutlet weak var playNote: UIButton!
  @IBOutlet weak var deletePresetButton: UIButton!
  @IBOutlet weak var savePresetButton: UIButton!
  @IBOutlet weak var addPresetButton: UIButton!
  @IBOutlet weak var instancesTableView: UITableView!
  @IBOutlet weak var presetsTableView: UITableView!
  @IBOutlet weak var audioUnitViewContainer: UIView!

  var audioUnits = [AVAudioUnit]()
  var viewControllers = [AVAudioUnit: ViewController]()
  let presetDocumentManager = PresetDocumentManager.make()
  var activeAudioUnit: AVAudioUnit?
  var activeAudioUnitViewController: UIViewController?
  var activeAudioUnitView: UIView? { activeAudioUnitViewController?.view }
  var audioUnitNameObservers = [NSKeyValueObservation]()
  var isConnected = false
  var isLoaded = false

  override func viewDidLoad() {
    super.viewDidLoad()
    setInstanceCount(Self.instanceCount)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    isLoaded = true
    audioUnitHost.delegate = self
    startMonitoringAudioUnitNames()
    updatePresetButtons()
  }

  func selected(_ audioUnit: AVAudioUnit, controller: UIViewController?) {
    guard let controller = controller else { return }

    removeAUViewController()
    activeAudioUnit = audioUnit
    activeAudioUnitViewController = controller

    addChild(controller)
    controller.didMove(toParent:self)

    if let auView = controller.view {
      auView.frame = audioUnitViewContainer.bounds
      audioUnitViewContainer.addSubview(auView)
      auView.pinToSuperviewEdges()
    }

    view.setNeedsLayout()
    audioUnitViewContainer.setNeedsLayout()

    activeAudioUnitViewController = controller
  }

  func removeAUViewController() {
    guard let controller = activeAudioUnitViewController, let audioUnitView = activeAudioUnitView else { return }
    audioUnitView.removeFromSuperview()
    controller.willMove(toParent: nil)
    controller.removeFromParent()
    activeAudioUnit = nil
    activeAudioUnitViewController = nil
  }

  @IBAction func changeInstanceCount(_ sender: UIStepper) {
    setInstanceCount(Int(sender.value))
  }

  @IBAction func togglePlay(_ sender: UIButton) {
    let isPlaying = audioUnitHost.togglePlayback()
    playScale.isSelected = isPlaying
  }

  @IBAction func playNoteOnce(_ sender: UIButton) {
    if let audioUnit = activeAudioUnit {
      audioUnitHost.playNoteOnce(audioUnit)
    }
  }

  @IBAction func deletePreset(_ sender: UIButton) {
    if let indexPath = presetsTableView.indexPathForSelectedRow {
      deletePreset(indexPath: indexPath)
    }
  }

  @IBAction func savePreset(_ sender: UIButton) {
    if let indexPath = presetsTableView.indexPathForSelectedRow {
      let uuid = presetDocumentManager.uuid(at: indexPath.row)
      audioUnitHost.makeFullStateCollection(uuid: uuid)
    }
  }

  @IBAction func addPreset(_ sender: UIButton) {
    let index = presetDocumentManager.count
    askForName(title: "New Preset", name: "Preset \(index + 1)", activity: "Add") { name in
      self.presetsTableView.beginUpdates()
      let indexPath = IndexPath(row: self.presetDocumentManager.count, section: 0)
      let uuid = self.presetDocumentManager.makePreset(name: name)
      self.presetsTableView.insertRows(at: [indexPath], with: .automatic)
      self.presetsTableView.endUpdates()
      self.audioUnitHost.makeFullStateCollection(uuid: uuid)
      self.updatePresetButtons()
    }
  }

  private func deletePreset(indexPath: IndexPath) {
    presetsTableView.beginUpdates()
    presetsTableView.deleteRows(at: [indexPath], with: .automatic)
    presetDocumentManager.remove(at: indexPath.row)
    presetsTableView.endUpdates()
    updatePresetButtons()
  }

  private func updatePresetButtons() {
    let selected = presetsTableView.indexPathForSelectedRow != nil
    deletePresetButton.isEnabled = selected
    savePresetButton.isEnabled = selected
  }
}

extension MainViewController: AudioUnitHostDelegate {

  func connected(audioUnits: [AVAudioUnit], viewControllers: [AVAudioUnit: ViewController]) {
    stopMonitoringAudioUnitNames()
    removeAUViewController()
    self.audioUnits = audioUnits
    self.viewControllers = viewControllers
    isConnected = true
    startMonitoringAudioUnitNames()
    self.instancesTableView.reloadData()

    if !audioUnits.isEmpty {
      selected(audioUnits[0], controller: viewControllers[audioUnits[0]])
    }
  }

  func failed(error: AudioUnitHostError) {
    let message = "Unable to load the AUv3 component. \(error.description)"
    let controller = UIAlertController(title: "AUv3 Failure", message: message, preferredStyle: .alert)
    present(controller, animated: true)
  }

  func fullStateCollectionGenerated(uuid: UUID, fullStateCollection: FullStateCollection) {
    let typedFullStateCollection = try! fullStateCollection.asTypedAny()
    self.presetDocumentManager.setFullStateCollection(typedFullStateCollection, for: uuid)
  }
}

// MARK: - Table View DataSource
extension MainViewController: UITableViewDataSource {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch tableView {
    case instancesTableView: return audioUnits.count
    case presetsTableView: return presetDocumentManager.count
    default: return 0
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    switch tableView {
    case instancesTableView: cell.textLabel?.text = audioUnits[indexPath.row].auAudioUnit.audioUnitShortName ?? "???"
    case presetsTableView: cell.textLabel?.text = presetDocumentManager.name(at: indexPath.row)
    default: fatalError("Unknown table view")
    }
    return cell
  }
}

// MARK: - Table View Delegate
extension MainViewController: UITableViewDelegate {

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch tableView {
    case instancesTableView:
      let audioUnit = audioUnits[indexPath.row]
      let controller = viewControllers[audioUnit]
      selected(audioUnit, controller: controller)

    case presetsTableView:
      audioUnitHost.setFullStateCollection(presetDocumentManager.fullStateCollection(at: indexPath.row))
      updatePresetButtons()
      break

    default:
      fatalError("Unknown table view")
    }
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    guard tableView === presetsTableView else { return }
    if editingStyle == .delete {
      deletePreset(indexPath: indexPath)
    }
  }
}

private extension MainViewController {

  func startMonitoringAudioUnitNames() {
    guard isViewLoaded && isConnected else { return }
    for (index, entry) in audioUnits.enumerated() {
      audioUnitNameObservers.append(entry.observe(\.auAudioUnit.audioUnitShortName) { [weak self] _, _ in
        guard let self = self else { return }
        DispatchQueue.main.async {
          self.instancesTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
      })
    }
  }

  func stopMonitoringAudioUnitNames() {
    audioUnitNameObservers.removeAll()
  }

  func setInstanceCount(_ value: Int) {
    instanceCountLabel.text = "\(value)"
    let stepperValue = Double(value)
    if stepperValue != instanceCountStepper.value {
      instanceCountStepper.value = Double(value)
    }
    if value != Self.instanceCount {
      Self.instanceCount = value
      audioUnitHost.setInstanceCount(value)  
    }
  }

  func askForName(title: String, name: String, activity: String, _ closure: @escaping (String) -> Void) {
    let controller = UIAlertController(title: title, message: nil, preferredStyle: .alert)
    controller.addTextField { textField in
      textField.placeholder = "Preset Name"
      textField.text = name
    }

    controller.addAction(UIAlertAction(title: activity, style: .default) { _ in
      guard let name = controller.textFields?.first?.text?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
        return
      }
      closure(name)
    })
    controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(controller, animated: true)
  }
}

extension UIAlertController {

  class func okAlert(title: String, message: String) -> UIAlertController {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    controller.addAction(UIAlertAction(title: "OK", style: .default))
    return controller
  }
}
