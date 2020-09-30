//
//  ViewController.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
//import MultipeerConnectivity

/**
 The "Main" ViewController. This ViewController holds the instance of the PluginManager.
 Furthermore it holds the ARKitView.
 */
class ViewController: UIViewController, ARSCNViewDelegate, PluginManagerDelegate, UITableViewDelegate {

    

    
    @IBOutlet var arSceneView: ARSCNView!
    @IBOutlet weak var imageForPluginInstructions: UIImageView!
    @IBOutlet weak var pluginInstructionsLookupButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var viewForCustomPluginView: UIView!
    
    // Persistence: Saving and loading current model
    @IBOutlet weak var saveModelButton: UIButton!
    @IBOutlet weak var loadModelButton: UIButton!
    @IBOutlet weak var shareModelButton: UIButton!
    
    @IBOutlet weak var snapshotThumbnail: UIImageView! // Screenshot thumbnail to help the user find feature points in the World
    @IBOutlet weak var statusLabel: UILabel!
    
    // This ARAnchor acts as the point of reference for all models when storing/loading
    var persistenceSavePointAnchor: ARAnchor?
    var persistenceSavePointAnchorName: String = "persistenceSavePointAnchor"
    
//    // This ARAnchor acts as the point of reference for all models when sharing
//    var sharePointAnchor: ARAnchor?
//    var sharePointAnchorName: String = "sharePointAnchor"
    
    var saveIsSuccessful: Bool = false
    
    var storedNode: SCNReferenceNode? = nil // A reference node used to pre-load the models and render later
    var sharedNode: SCNNode? = nil
    
    @IBOutlet weak var menuToggleButton: UIButton!
    @IBOutlet weak var menuView: UIView!
    var menuViewNavigationController : UINavigationController?
    var menuTableViewController = UITableViewController(style: .grouped)
    var tableViewDataSource : UITableViewDiffableDataSource<Int, Plugin>? = nil
    var menuGroupingInfo : [(String, [Plugin])]? = nil
    
    var bluetoothARPenConnected: Bool = false
    /**
     The PluginManager instance
     */
    var pluginManager: PluginManager!
    
    let userStudyRecordManager = UserStudyRecordManager() // Manager for storing data from user studies
    
    //var multipeerSession: MultipeerSession!
    
    //A standard viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        // Make the corners of UI buttons rounded
        self.makeRoundedCorners(button: self.pluginInstructionsLookupButton)
        self.makeRoundedCorners(button: self.settingsButton)
        self.makeRoundedCorners(button: self.undoButton)
        self.makeRoundedCorners(button: self.saveModelButton)
        self.makeRoundedCorners(button: self.loadModelButton)
        self.makeRoundedCorners(button: self.shareModelButton)
        
        self.undoButton.isHidden = false
        self.undoButton.isEnabled = true
        
        self.shareModelButton.isHidden = true
        
        // Create a new scene
        let scene = PenScene(named: "art.scnassets/ship.scn")!
        scene.markerBox = MarkerBox()
        self.arSceneView.pointOfView?.addChildNode(scene.markerBox)
        
        self.pluginManager = PluginManager(scene: scene)
        self.pluginManager.delegate = self
        self.arSceneView.session.delegate = self.pluginManager.arManager
        self.arSceneView.delegate = self
        
        self.arSceneView.autoenablesDefaultLighting = true
        self.arSceneView.pointOfView?.name = "iDevice Camera"
        
        // Set the scene to the view
        arSceneView.scene = scene
        
        // Setup tap gesture recognizer for plugin instructions
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:  #selector(ViewController.imageForPluginInstructionsTapped(_:)))
        self.imageForPluginInstructions.isUserInteractionEnabled = true
        self.imageForPluginInstructions.addGestureRecognizer(tapGestureRecognizer)
        
        // Hide plugin instructions
        self.imageForPluginInstructions.isHidden = true
        //self.displayPluginInstructions(forPluginID: currentActivePluginID)
        
        // Set the user study record manager reference in the app delegate (for saving state when leaving the app)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.userStudyRecordManager = self.userStudyRecordManager
        } else {
            print("Record manager was not set up in App Delegate")
        }
        
        // Read in any already saved map to see if we can load one
        if mapDataFromFile != nil {
            self.loadModelButton.isHidden = false
        }
        
        // Observe camera's tracking state and session information
        NotificationCenter.default.addObserver(self, selector: #selector(handleStateChange(_:)), name: Notification.Name.cameraDidChangeTrackingState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleStateChange(_:)), name: Notification.Name.sessionDidUpdate, object: nil)
        
        // Remove snapshot thumbnail when model has been loaded
        NotificationCenter.default.addObserver(self, selector: #selector(removeSnapshotThumbnail(_:)), name: Notification.Name.virtualObjectDidRenderAtAnchor, object: nil)
        
//        // Enable host-guest sharing to share ARWorldMap
//        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
        
        
        self.menuViewNavigationController = UINavigationController(rootViewController: menuTableViewController)
        self.menuViewNavigationController?.view.frame = CGRect(x: 0, y: 0, width: self.menuView.frame.width, height: self.menuView.frame.height)
        self.menuViewNavigationController?.setNavigationBarHidden(true, animated: false)
        self.setupPluginMenuFrom(PluginArray: self.pluginManager.plugins)
        self.menuTableViewController.tableView.rowHeight = UITableView.automaticDimension
        self.menuTableViewController.tableView.estimatedRowHeight = 40
        self.menuTableViewController.tableView.backgroundColor = UIColor(white: 0.5, alpha: 0.35)
        
        self.menuView.addSubview(self.menuViewNavigationController!.view)
    }
    
    /**
     viewWillAppear. Init the ARSession
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        arSceneView.session.run(configuration)
        
        // Hide navigation bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //if no plugin is currently selected, select the base plugin
        if self.pluginManager.activePlugin == nil {
            let indexPath = IndexPath(row: 0, section: 0)
            self.menuTableViewController.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            self.tableView(self.menuTableViewController.tableView, didSelectRowAt: indexPath)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        arSceneView.session.pause()
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // Prepare the SettingsViewController by passing the scene
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else { return }
        
        if segueIdentifier == "ShowSettingsSegue" {
            let destinationVC = segue.destination as! UINavigationController
            guard let destinationSettingsController = destinationVC.viewControllers.first as? SettingsTableViewController else {
                return
                
            }
            destinationSettingsController.scene = self.arSceneView.scene as? PenScene
            //pass reference to the record manager (to show active user ID and export data)
            destinationSettingsController.userStudyRecordManager = self.userStudyRecordManager
            destinationSettingsController.bluetoothARPenConnected = self.bluetoothARPenConnected
        }
        
    }
    
    // MARK: - Plugins
    
    func setupPluginMenuFrom(PluginArray pluginArray : [Plugin]) {
        menuTableViewController.tableView.register(UINib(nibName: "ARPenPluginTableViewCell", bundle: nil), forCellReuseIdentifier: "arpenplugincell")
        tableViewDataSource = UITableViewDiffableDataSource<Int, Plugin>(tableView: menuTableViewController.tableView){
            (tableView: UITableView, indexPath: IndexPath, item: Plugin) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "arpenplugincell", for: indexPath)
            if let cell = cell as? ARPenPluginTableViewCell {
                // If plugin needs bluetooth ARPen, but it is not found, then disable the button, use a different image, and grey out the plugin label.
                var pluginImage : UIImage?
                if (item.needsBluetoothARPen && !self.bluetoothARPenConnected) {
                    pluginImage = item.pluginDisabledImage
                    cell.cellLabel.textColor = UIColor.init(white: 0.4, alpha: 1)
                    cell.selectionStyle = .none
                } else {
                    pluginImage = item.pluginImage
                    cell.selectionStyle = .default
                    cell.cellLabel.textColor = .label
                }
                cell.updateCellWithImage(pluginImage, andText:item.pluginIdentifier)
                cell.backgroundColor = .clear
                return cell
            } else {
                return cell
            }
        }
        
        menuTableViewController.tableView.delegate = self
        
        self.menuGroupingInfo = self.createMenuGroupingInfo(fromPluginArray: pluginArray)
        
        var pluginMenuSnap = NSDiffableDataSourceSnapshot<Int, Plugin>()
        for (index, element) in self.menuGroupingInfo!.enumerated() {
            pluginMenuSnap.appendSections([index])
            pluginMenuSnap.appendItems(element.1, toSection: index)
        }
//        pluginMenuSnap.appendSections([0])
//        pluginMenuSnap.appendItems(pluginArray, toSection: 0)
        tableViewDataSource?.apply(pluginMenuSnap)
            
    }
    
    func createMenuGroupingInfo(fromPluginArray plugins: [Plugin]) -> [(String, [Plugin])] {
        var groupingInfo = [(String, [Plugin])]()
        var sectionTitles = [String]()
        for currentPlugin in plugins {
            if let index = sectionTitles.firstIndex(of: currentPlugin.pluginGroupName) {
                groupingInfo[index].1.append(currentPlugin)
            } else {
                groupingInfo.append((currentPlugin.pluginGroupName, [currentPlugin]))
                sectionTitles.append(currentPlugin.pluginGroupName)
            }
        }
        return groupingInfo
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let currentActivePlugin = self.pluginManager.activePlugin {
            //remove custom view elements from view
            currentActivePlugin.customPluginUI?.removeFromSuperview()
            currentActivePlugin.deactivatePlugin()
        }
        //activate plugin in plugin manager and update currently active plugin property
        guard let newActivePlugin = self.menuGroupingInfo?[indexPath.section].1[indexPath.row] else {return}
        self.pluginManager.activePlugin = newActivePlugin
        //if the new plugin conforms to the user study record plugin protocol, then pass a reference to the record manager (allowing to save data to it)
        if var pluginConformingToUserStudyProtocol = newActivePlugin as? UserStudyRecordPluginProtocol {
            pluginConformingToUserStudyProtocol.recordManager = self.userStudyRecordManager
        }
        if let currentScene = self.pluginManager.arManager.scene {
            if !(newActivePlugin.needsBluetoothARPen && !self.bluetoothARPenConnected) {
                newActivePlugin.activatePlugin(withScene: currentScene, andView: self.arSceneView)
                if let customPluginUI = newActivePlugin.customPluginUI {
                    customPluginUI.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: viewForCustomPluginView.frame.size)
                    viewForCustomPluginView.addSubview(customPluginUI)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let selectedPlugin = self.menuGroupingInfo?[indexPath.section].1[indexPath.row] else {return indexPath}
        
        if (selectedPlugin.needsBluetoothARPen && !self.bluetoothARPenConnected) {
            self.displayPluginInstructions(withBluetoothErrorMessage: true)
            return nil
        } else {
            self.imageForPluginInstructions.isHidden = true
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let sectionTitleName = self.menuGroupingInfo?[section].0 {
            let sectionTitle = UILabel()
            sectionTitle.text = sectionTitleName
            sectionTitle.backgroundColor = UIColor(white: 1, alpha: 0.5)
            sectionTitle.font = .boldSystemFont(ofSize: 20)
            
            return sectionTitle
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    @IBAction func toggleMenuPosition(_ sender: Any) {
        if self.menuView.frame.minX >= 0 {
            UIView.animate(withDuration: 0.1){
                self.menuView.transform = CGAffineTransform(translationX: self.menuView.frame.width * -1, y: 0)
                self.menuView.alpha = 0.0
            }
            self.menuToggleButton.setTitle("Show Plugins", for: .normal)
        } else {
            UIView.animate(withDuration: 0.1) {
                self.menuView.transform = .identity
                self.menuView.alpha = 1.0
            }
            self.menuToggleButton.setTitle("Hide Plugins", for: .normal)
        }
    }
    
    
    // Display the instructions for plugin by setting imageForPluginInstructions
    func displayPluginInstructions(withBluetoothErrorMessage showBluetoothMissingInstruction : Bool) {
        if  showBluetoothMissingInstruction {
            self.imageForPluginInstructions.image = UIImage.init(named: "BluetoothARPenMissingInstructions")
        } else if let plugin = self.pluginManager.activePlugin {
            self.imageForPluginInstructions.image = plugin.pluginInstructionsImage
        }
        
        self.imageForPluginInstructions.isUserInteractionEnabled = true
        self.imageForPluginInstructions.alpha = 0.75
        self.imageForPluginInstructions.isHidden = false
        
    }
    
    @objc func imageForPluginInstructionsTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        
        tappedImage.isHidden = true
        self.pluginInstructionsLookupButton.isHidden = false
    }
    
    @IBAction func showPluginInstructions(_ sender: Any) {
        self.displayPluginInstructions(withBluetoothErrorMessage: false)
    }
    
    // MARK: - ARManager delegate
    
    // Mark: - PenManager delegate
    /**
     Callback from PenManager
     */
    func penConnected() {
        self.bluetoothARPenConnected = true
    }
    
    func penFailed() {

        self.bluetoothARPenConnected = false
    }
    
    
    //Software Pen Button Actions
    @IBAction func softwarePenButtonPressed(_ sender: Any) {
        //next line is the direct way possible here, but we'll show the way how the button states can be send from everywhere in the map
        //self.pluginManager.button(.Button1, pressed: true)
        //sent notification of button press to the pluginManager
        let buttonEventDict:[String: Any] = ["buttonPressed": Button.Button1, "buttonState" : true]
        NotificationCenter.default.post(name: .softwarePenButtonEvent, object: nil, userInfo: buttonEventDict)
    }
    
    @IBAction func softwarePenButtonReleased(_ sender: Any) {
        //next line is the direct way possible here, but we'll show the way how the button states can be send from everywhere in the map
        //self.pluginManager.button(.Button1, pressed: false)
        //sent notification of button release to the pluginManager
        let buttonEventDict:[String: Any] = ["buttonPressed": Button.Button1, "buttonState" : false]
        NotificationCenter.default.post(name: .softwarePenButtonEvent, object: nil, userInfo: buttonEventDict)
    }
    
    @IBAction func undoButtonPressed(_ sender: Any) {
        self.pluginManager.undoPreviousStep()
    }
    
    // MARK: - ARSCNViewDelegate
        
    // Invoked when new anchors are added to the scene
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchorName = anchor.name else {
            return
        }
        
        if (anchorName == persistenceSavePointAnchorName) {
            // Save the reference to the virtual object anchor when the anchor is added from relocalizing
            if persistenceSavePointAnchor == nil {
                persistenceSavePointAnchor = anchor
            }
            
            DispatchQueue.main.async {
                self.storedNode = SCNReferenceNode(url: self.sceneSaveURL) // Fetch models saved earlier
                self.storedNode!.load()
                
                let scene = self.arSceneView.scene as! PenScene
                for child in self.storedNode!.childNodes {
                    scene.drawingNode.addChildNode(child)
                }
            }
        } //else if (anchorName == sharePointAnchorName) {
//            // Perform rendering operations asynchronously
//            DispatchQueue.main.async {
//                guard let sharedNode = self.sharedNode else {
//                    return
//                }
//
//                let scene = self.arSceneView.scene as! PenScene
//                scene.drawingNode.addChildNode(sharedNode)
//                print("Adding storedNode to sharePointAnchor")
//            }
//        }
        else {
            print("An unknown ARAnchor has been added!")
            return
        }
    }
    
    // MARK: - Persistence: Save and load ARWorldMap
    
    // Receives notification on when session or camera tracking state changes and updates label
    @objc func handleStateChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            print("notification.userInfo is empty")
            return
        }
        switch notification.name {
        case .sessionDidUpdate:
            updateStatusLabel(for: userInfo["frame"] as! ARFrame, trackingState: userInfo["trackingState"] as! ARCamera.TrackingState)
            
            // Enable Save button only when the mapping status is good and
            // drawingNode has at least one object
            let frame = userInfo["frame"] as! ARFrame
            switch frame.worldMappingStatus {
                case .extending, .mapped:
                    let scene = self.arSceneView.scene as! PenScene
                    saveModelButton.isEnabled = scene.drawingNode.childNodes.count > 0
                default:
                    saveModelButton.isEnabled = false
            }
            break
        case .cameraDidChangeTrackingState:
            updateStatusLabel(for: userInfo["currentFrame"] as! ARFrame, trackingState: userInfo["trackingState"] as! ARCamera.TrackingState)
            break
        default:
            print("Received unknown notification: \(notification.name)")
        }
    }
    
    // Setup ARAnchor that serves as the point of reference for all drawings
    func setupPersistenceAnchor() {
        // Remove existing anchor if it exists
        if let existingPersistenceAnchor = persistenceSavePointAnchor {
            self.arSceneView.session.remove(anchor: existingPersistenceAnchor)
        }
        
        // Add ARAnchor for save point
        persistenceSavePointAnchor = ARAnchor(name: persistenceSavePointAnchorName, transform: matrix_identity_float4x4)
    }
    
    // Create URL for storing WorldMap in a lazy manner
    lazy var mapSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    
    // Create URL for storing all models in the current AR scence in a lazy manner
    lazy var sceneSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("scene.scn")
        } catch {
            fatalError("Can't get scene save URL: \(error.localizedDescription)")
        
        }
    }()
    
    // Save the world map and models
    @IBAction func saveCurrentScene(_ sender: Any) {
        self.setupPersistenceAnchor()
        
        self.arSceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else {
                    self.showAlert(title: "Can't get current world map", message: error!.localizedDescription)
                    return
                }
            
            // Add a snapshot image indicating where the map was captured.
            guard let snapshotAnchor = SnapshotAnchor(capturing: self.arSceneView)
                else { fatalError("Can't take snapshot") }
            map.anchors.append(snapshotAnchor)
            map.anchors.append(self.persistenceSavePointAnchor!)
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: self.mapSaveURL, options: [.atomic])

                DispatchQueue.main.async {
                    self.loadModelButton.isHidden = false
                    self.loadModelButton.isEnabled = true
                    
                    // Save the current PenScene to sceneSaveURL
                    let scene = self.arSceneView.scene as! PenScene
                    let savedNode = SCNReferenceNode(url: self.sceneSaveURL)
                    var nodesCreatedWithOpenCascade: [SCNNode] = []
                    
                    if savedNode!.isLoaded == false {
                        print("No prior save found, saving current PenScene.")
                        scene.pencilPoint.removeFromParentNode() // Remove pencilPoint before saving
                        
                        // Remove all geometries created via Open Cascade
                        scene.drawingNode.childNodes(passingTest: { (node, stop) -> Bool in
                            let geometryType = type(of: node)
                            
                            // If the geometry created by Open Cascade, remove before sharing (but store them locally for retrieval).
                            if ((geometryType == ARPSphere.self) || (geometryType == ARPGeomNode.self) || (geometryType == ARPRevolution.self) ||
                                (geometryType == ARPBox.self) || (geometryType == ARPNode.self) || (geometryType == ARPSweep.self) ||
                                (geometryType == ARPCylinder.self) || (geometryType == ARPLoft.self) || (geometryType == ARPPath.self) ||
                                (geometryType == ARPBoolNode.self) || (geometryType == ARPPathNode.self)) {
                                
                                nodesCreatedWithOpenCascade.append(node)
                                node.removeFromParentNode()
                                return false
                            } else {
                                return true
                            }
                        })                       
                        
                        if scene.write(to: self.sceneSaveURL, options: nil, delegate: nil, progressHandler: nil) {
                            // Handle save if needed
                            scene.reinitializePencilPoint()
                            nodesCreatedWithOpenCascade.forEach({ scene.drawingNode.addChildNode($0) })
                            
                            self.saveIsSuccessful = true
                            
                            // Reset the value after two seconds so that the label disappears
                            _ = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { timer in
                                self.saveIsSuccessful = false
                            } // Todo: See if there is a more elegant way to do this
                        } else {
                            scene.reinitializePencilPoint()
                            nodesCreatedWithOpenCascade.forEach({ scene.drawingNode.addChildNode($0) })
                            
                            return
                        }
                    }
                }
                self.statusLabel.text = "Write successful!"
            } catch {
                fatalError("Can't save map: \(error.localizedDescription)")
            }
        }
    }
    
    
    // Called opportunistically to verify that map data can be loaded from filesystem
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: mapSaveURL)
    }
    
    // Called opportunistically to verify that scene data can be loaded from filesystem
    var sceneDataFromFile: Data? {
        return try? Data(contentsOf: sceneSaveURL)
    }
    
    // Load the world map and models
    @IBAction func loadScene(_ sender: Any) {
        /// - Tag: ReadWorldMap
        let worldMap: ARWorldMap = {
            guard let data = mapDataFromFile
                else { fatalError("Map data should already be verified to exist before Load button is enabled.") }
            do {
                guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                    else { fatalError("No ARWorldMap in archive.") }
                return worldMap
            } catch {
                fatalError("Can't unarchive ARWorldMap from file data: \(error)")
            }
        }()
        
        // Display the snapshot image stored in the world map to aid user in relocalizing.
        if let snapshotData = worldMap.snapshotAnchor?.imageData,
            let snapshot = UIImage(data: snapshotData) {
            snapshotThumbnail.isHidden = false
            snapshotThumbnail.image = snapshot

        } else {
            print("No snapshot image in world map")
        }
        
        // Remove the snapshot anchor from the world map since we do not need it in the scene.
        worldMap.anchors.removeAll(where: { $0 is SnapshotAnchor })
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.initialWorldMap = worldMap
        self.arSceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        isRelocalizingMap = true
        persistenceSavePointAnchor = nil
        
        self.setupPersistenceAnchor()
        self.arSceneView.session.add(anchor: persistenceSavePointAnchor!) // Add anchor to the current scene
    }
    
    var isRelocalizingMap = false
    
    // Provide feedback and instructions to the user about saving and loading the map and models respectively
    // TODO: This needs to be updated for sharing 
    func updateStatusLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        var message: String = ""
        self.snapshotThumbnail.isHidden = true
        
        switch (trackingState) {
        case (.limited(.relocalizing)) where isRelocalizingMap:
            message = "Move your device to the location shown in the image."
            self.snapshotThumbnail.isHidden = false
        case .normal, .notAvailable:
//            if !multipeerSession.connectedPeers.isEmpty && mapProvider == nil {
//                let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
//                message = "Connected with \(peerNames)."
//
//                let scene = self.arSceneView.scene as! PenScene
//                if (scene.drawingNode.childNodes.count > 0) {
//                    self.shareModelButton.isHidden = false
//                }
//            }
//            else
            if (self.saveIsSuccessful) {
                message = "Save successful"
            }
            else {
                message = ""
            }
//            case .limited(.initializing) where mapProvider != nil,
//             .limited(.relocalizing) where mapProvider != nil:
//                message = "Received map from \(mapProvider!.displayName)."
            default:
                message = ""
        }
        
        statusLabel.text = message
    }
    
    // Remove snapshot thumbnail
    @objc func removeSnapshotThumbnail(_ notification: Notification) {
        self.snapshotThumbnail.isHidden = true
    }
    
    
    // MARK: - Share ARWorldMap with other users
   
    func setupAndShareAnchor() {
//        // Place an anchor for a virtual character. The model appears in renderer(_:didAdd:for:).
//       let transform = self.arSceneView.scene.rootNode.simdTransform
//       let anchor = ARAnchor(name: sharePointAnchorName, transform: transform)
//       self.arSceneView.session.add(anchor: anchor)
//
//       // Send the anchor info to peers, so they can place the same content.
//       guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
//           else { fatalError("can't encode anchor") }
//       self.multipeerSession.sendToAllPeers(data)
    }
    
    
    @IBAction func shareModelButtonPressed(_ sender: Any) {
//        self.arSceneView.session.getCurrentWorldMap { worldMap, error in
//            guard let map = worldMap
//                else {
//                    print("Error: \(error!.localizedDescription)")
//                    return
//                }
//
//            DispatchQueue.main.async {
//                let scene = self.arSceneView.scene as! PenScene
//                scene.pencilPoint.removeFromParentNode() // Remove pencilPoint before sharing
//                var nodesCreatedWithOpenCascade: [SCNNode] = []
//
//                // Remove all geometries created via Open Cascade
//                scene.drawingNode.childNodes(passingTest: { (node, stop) -> Bool in
//                    let geometryType = type(of: node)
//                    print("geometryType:\(geometryType)")
//
//                    if ((geometryType == ARPSphere.self) || (geometryType == ARPGeomNode.self) || (geometryType == ARPRevolution.self) ||
//                        (geometryType == ARPBox.self) || (geometryType == ARPNode.self) || (geometryType == ARPSweep.self) ||
//                        (geometryType == ARPCylinder.self) || (geometryType == ARPLoft.self) || (geometryType == ARPPath.self) ||
//                        (geometryType == ARPBoolNode.self) || (geometryType == ARPPathNode.self)) {
//                        print("Detected geometry created via Open Cascade.\n")
//
//                        nodesCreatedWithOpenCascade.append(node)
//                        node.removeFromParentNode()
//                        return false
//                    } else {
//                        print("Detected geometry *not* created via Open Cascade.\n")
//                        return true
//                    }
//                })
//
//                // Share content first so that the content is not duplicated for this device
//                guard let sceneData = try? NSKeyedArchiver.archivedData(withRootObject: scene.drawingNode, requiringSecureCoding: true)
//                    else { fatalError("can't encode scene data") }
//                self.multipeerSession.sendToAllPeers(sceneData)
//                scene.reinitializePencilPoint()
//                nodesCreatedWithOpenCascade.forEach({ scene.drawingNode.addChildNode($0) })
//
//                self.setupAndShareAnchor()
//
//                // Send the WorldMap to all peers
//                guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
//                    else { fatalError("can't encode map") }
//                self.multipeerSession.sendToAllPeers(data)
//            }
//        }
    }
    
//    var mapProvider: MCPeerID?
//
//    /// - Tag: ReceiveData
//    func receivedData(_ data: Data, from peer: MCPeerID) {
//
//        if let unarchivedData = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data){
//
//            if unarchivedData is ARWorldMap, let worldMap = unarchivedData as? ARWorldMap {
//                // Run the session with the received world map.
//                let configuration = ARWorldTrackingConfiguration()
//                configuration.planeDetection = .horizontal
//                configuration.initialWorldMap = worldMap
//                self.arSceneView.session.run(configuration, options: [.resetTracking])
//
//                // Remember who provided the map for showing UI feedback.
//                mapProvider = peer
//            } else if unarchivedData is ARAnchor, let anchor = unarchivedData as? ARAnchor {
//                self.arSceneView.session.add(anchor: anchor)
//                print("added the anchor (\(anchor.name ?? "(can't parse)")) received from peer: \(peer)")
//            } else if unarchivedData is SCNNode, let sceneData = unarchivedData as? SCNNode {
////                scene.write(to: self.sceneStoreURL, options: nil, delegate: nil, progressHandler: nil)
//                self.sharedNode = sceneData
//                print("saved scene data into sharedNode")
//            }
//            else {
//              print("Unknown Data Recieved From = \(peer)")
//            }
//        } else {
//            print("can't decode data received from \(peer)")
//        }
//    }
}

enum Section {
    case main
}
