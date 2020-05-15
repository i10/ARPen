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

/**
 The "Main" ViewController. This ViewController holds the instance of the PluginManager.
 Furthermore it holds the ARKitView.
 */
class ViewController: UIViewController, ARSCNViewDelegate, PluginManagerDelegate {

    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var arPenLabel: UILabel!
    @IBOutlet weak var arPenActivity: UIActivityIndicatorView!
    @IBOutlet weak var arPenImage: UIImageView!
    @IBOutlet weak var arKitLabel: UILabel!
    @IBOutlet weak var arKitActivity: UIActivityIndicatorView!
    @IBOutlet weak var arKitImage: UIImageView!
    @IBOutlet var arSceneView: ARSCNView!
    @IBOutlet weak var pluginMenuScrollView: UIScrollView!
    @IBOutlet weak var imageForPluginInstructions: UIImageView!
    @IBOutlet weak var pluginInstructionsLookupButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    
    // Persistence: Saving and loading current model
    @IBOutlet weak var saveModelButton: UIButton!
    @IBOutlet weak var loadModelButton: UIButton!
    
    @IBOutlet weak var snapshotThumbnail: UIImageView! // Screenshot thumbnail to help the user find feature points in the World
    @IBOutlet weak var persistenceStateLabel: UILabel! // Text label used to provide feedback about saving and loading models
    
    // This ARAnchor acts as the point of reference for all model
    var persistenceSavePointAnchor: ARAnchor?
    var persistenceSavePointAnchorName: String = "persistenceSavePointAnchor"
    
    var saveIsSuccessful: Bool = false
    
    var placeholderNode: SCNReferenceNode? = nil // A reference node used to pre-load the models and render later
    
    let menuButtonHeight = 70
    let menuButtonPadding = 5
    var currentActivePluginID = 1
    var bluetoothARPenConnected: Bool = false
    
    var pluginManager: PluginManager!
    
    let userStudyRecordManager = UserStudyRecordManager() // Manager for storing data from user studies
  
    
    //A standard viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        // Make the corners of UI buttons rounded
        self.makeRoundedCorners(button: self.pluginInstructionsLookupButton)
        self.makeRoundedCorners(button: self.settingsButton)
        self.makeRoundedCorners(button: self.undoButton)
        self.makeRoundedCorners(button: self.saveModelButton)
        self.makeRoundedCorners(button: self.loadModelButton)
        
        self.undoButton.isHidden = false
        self.undoButton.isEnabled = true
        
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
        
        arSceneView.scene = scene // Set the scene to the view
        
        // Setup tap gesture recognizer for plugin instructions
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:  #selector(ViewController.imageForPluginInstructionsTapped(_:)))
        self.imageForPluginInstructions.isUserInteractionEnabled = true
        self.imageForPluginInstructions.addGestureRecognizer(tapGestureRecognizer)
        
        // Hide plugin instructions
        self.imageForPluginInstructions.isHidden = true
        self.displayPluginInstructions(forPluginID: currentActivePluginID)
        
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
    }
    

    // viewWillAppear. Init the ARSession
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        arSceneView.session.run(configuration)
        
        // Hide navigation bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
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
    
    func setupPluginMenu(){
        // Define target height and width for the scrollview to hold all buttons
        let targetWidth = Int(self.pluginMenuScrollView.frame.width)
        let experimentalPluginLabelHeight: Int = 40
        
        let targetHeight = self.pluginManager.plugins.count * (menuButtonHeight+2*menuButtonPadding) + experimentalPluginLabelHeight
        self.pluginMenuScrollView.contentSize = CGSize(width: targetWidth, height: targetHeight)
        
        //iterate over plugin array from plugin manager and create a button for each in the scrollview
        for (index,plugin) in self.pluginManager.plugins.enumerated() {
            // calculate position inside the scrollview for current button
            
            let frameForCurrentButton: CGRect
            if (index + 2 <= self.pluginManager.experimentalPluginsStartAtIndex) {
                frameForCurrentButton = CGRect(x: 0, y: index*(menuButtonHeight+2*menuButtonPadding), width: targetWidth, height: menuButtonHeight+2*menuButtonPadding)
            } else {
                frameForCurrentButton = CGRect(x: 0, y: index*(menuButtonHeight+2*menuButtonPadding) + experimentalPluginLabelHeight, width: targetWidth, height: menuButtonHeight+2*menuButtonPadding)
            }
            let buttonForCurrentPlugin = UIButton(frame: frameForCurrentButton)
            
            // Define properties of the button: tag for identification & action when pressed
            buttonForCurrentPlugin.tag = index + 1 //+1 needed since finding a view with tag 0 does not work
            buttonForCurrentPlugin.addTarget(self, action: #selector(pluginButtonPressed), for: .touchUpInside)
            
            buttonForCurrentPlugin.imageEdgeInsets = UIEdgeInsets(top: CGFloat(menuButtonPadding), left: CGFloat(menuButtonPadding), bottom: CGFloat(menuButtonPadding+menuButtonHeight/3), right: CGFloat(menuButtonPadding))
            buttonForCurrentPlugin.imageView?.contentMode = .scaleAspectFit
            
            var titleLabelFrame : CGRect
            if let _ = buttonForCurrentPlugin.imageView?.frame {
                titleLabelFrame = CGRect(x: CGFloat(menuButtonPadding/2) , y: CGFloat(menuButtonPadding+menuButtonHeight*2/3), width: CGFloat(targetWidth - menuButtonPadding), height: CGFloat(menuButtonHeight/3))
            } else {
                titleLabelFrame = CGRect(x: CGFloat(menuButtonPadding/2) , y: CGFloat(menuButtonPadding), width: CGFloat(targetWidth - menuButtonPadding), height: CGFloat(menuButtonHeight))
            }
            
            let titleLabel = UILabel(frame: titleLabelFrame)
            titleLabel.text = plugin.pluginIdentifier
            titleLabel.font = UIFont.init(name: "Helvetica", size: 14)
            titleLabel.textAlignment = .center
            titleLabel.baselineAdjustment = .alignCenters
            
            // If plugin needs bluetooth ARPen, but it is not found, then disable the button, use a different image, and grey out the plugin label.
            if (plugin.needsBluetoothARPen && !self.bluetoothARPenConnected) {
                //                buttonForCurrentPlugin.isEnabled = false
                buttonForCurrentPlugin.setImage(plugin.pluginDisabledImage, for: .normal)
                titleLabel.textColor = UIColor.init(white: 0.4, alpha: 1)
            } else {
                buttonForCurrentPlugin.setImage(plugin.pluginImage, for: .normal)
            }
            
            buttonForCurrentPlugin.addSubview(titleLabel)
            buttonForCurrentPlugin.backgroundColor = UIColor(white: 0.5, alpha: 0.35)
            
            self.pluginMenuScrollView.addSubview(buttonForCurrentPlugin)
            
            // Add experimental plugins header
            if (self.pluginManager.experimentalPluginsStartAtIndex == index + 2) {
                let baseHeight = index*(menuButtonHeight+2*menuButtonPadding)
                let textOffset = 5

                let yPosition = menuButtonPadding+menuButtonHeight*2/3 + baseHeight + experimentalPluginLabelHeight + textOffset
                
                let headerLabelFrame: CGRect = CGRect(x: CGFloat(menuButtonPadding/2) , y: CGFloat(yPosition), width: CGFloat(targetWidth - menuButtonPadding), height: CGFloat(menuButtonHeight/3))
                let headerLabel = UILabel(frame: headerLabelFrame)
                
                headerLabel.text = "Experimental"
                headerLabel.font = UIFont.init(name: "Helvetica", size: 12)
                headerLabel.textColor = UIColor.init(red: 0.73, green: 0.12157, blue: 0.8, alpha: 1)
                headerLabel.textAlignment = .center
                headerLabel.baselineAdjustment = .alignCenters
                
                self.pluginMenuScrollView.addSubview(headerLabel)
            }
        }
    }
     
    @objc func pluginButtonPressed(sender: UIButton!){
        let pluginID = sender.tag
        activatePlugin(withID: pluginID)
        
        if (!self.pluginManager.pluginInstructionsCanBeHidden[pluginID-1]) {
            displayPluginInstructions(forPluginID: pluginID)
        } else {
            self.imageForPluginInstructions.isHidden = true
            self.pluginInstructionsLookupButton.isHidden = false
        }
        
    }
    
    func activatePlugin(withID pluginID:Int) {
        //deactivate highlighting of the button from the currently active plugin
        if let currentActivePluginButton = self.pluginMenuScrollView.viewWithTag(currentActivePluginID) as? UIButton {
            currentActivePluginButton.layer.borderColor = UIColor.clear.cgColor
            currentActivePluginButton.layer.borderWidth = 0
        }
        
        //find the button for the new active plugin and set the highlighted color
        guard let newActivePluginButton = self.pluginMenuScrollView.viewWithTag(pluginID) as? UIButton else {
            print("Button for new plugin not found")
            return
        }
        
        newActivePluginButton.layer.borderColor = UIColor.init(red: 0.73, green: 0.12157, blue: 0.8, alpha: 0.75).cgColor
        newActivePluginButton.layer.borderWidth = 1
        
        if let currentActivePlugin = self.pluginManager.activePlugin {
            currentActivePlugin.deactivatePlugin()
        }
        //activate plugin in plugin manager and update currently active plugin property
        let newActivePlugin = self.pluginManager.plugins[pluginID-1] //-1 needed since the tag is one larger than index of plugin in the array (to avoid tag 0)
        self.pluginManager.activePlugin = newActivePlugin
        //if the new plugin conforms to the user study record plugin protocol, then pass a reference to the record manager (allowing to save data to it)
        if var pluginConformingToUserStudyProtocol = newActivePlugin as? UserStudyRecordPluginProtocol {
            pluginConformingToUserStudyProtocol.recordManager = self.userStudyRecordManager
        }
        if let currentScene = self.pluginManager.arManager.scene {
            if !(newActivePlugin.needsBluetoothARPen && !self.bluetoothARPenConnected) {
                newActivePlugin.activatePlugin(withScene: currentScene, andView: self.arSceneView)
            }
        }
        currentActivePluginID = pluginID
        
        // Enable/disable undo button based on current plugin
        self.undoButton.isHidden = currentActivePluginID == 1 ? false : true
    }
    
    // Display the instructions for plugin by setting imageForPluginInstructions
    func displayPluginInstructions(forPluginID pluginID: Int) {
        let plugin = self.pluginManager.plugins[pluginID-1]
        
        if (plugin.needsBluetoothARPen && !self.bluetoothARPenConnected) {
            self.imageForPluginInstructions.image = UIImage.init(named: "BluetoothARPenMissingInstructions")
            self.imageForPluginInstructions.isUserInteractionEnabled = false
        } else
        {
            self.imageForPluginInstructions.image = plugin.pluginInstructionsImage
            self.imageForPluginInstructions.isUserInteractionEnabled = true
        }
        
        self.imageForPluginInstructions.alpha = 0.75
        self.imageForPluginInstructions.isHidden = false
        
        self.pluginInstructionsLookupButton.isHidden = true
    }
    
    @objc func imageForPluginInstructionsTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        self.pluginManager.pluginInstructionsCanBeHidden[self.currentActivePluginID-1] = true
        
        tappedImage.isHidden = true
        self.pluginInstructionsLookupButton.isHidden = false
    }
    
    @IBAction func showPluginInstructions(_ sender: Any) {
        self.displayPluginInstructions(forPluginID: self.currentActivePluginID)        
    }
    
    // MARK: - ARManager delegate
    
    // Callback from the ARManager
    func arKitInitialiazed() {
        guard let arKitActivity = self.arKitActivity else {
            return
        }
        arKitActivity.isHidden = true
        self.arKitImage.isHidden = false
        checkVisualEffectView()
    }
    
    // MARK: - PenManager delegate
    
    // Callback from PenManager
    func penConnected() {
        guard let arPenActivity = self.arPenActivity else {
            return
        }
        arPenActivity.isHidden = true
        self.arPenImage.isHidden = false
        self.bluetoothARPenConnected = true
        self.setupPluginMenu()
        activatePlugin(withID: currentActivePluginID)
        checkVisualEffectView()
    }
    
    func penFailed() {
        guard let arPenActivity = self.arPenActivity else {
            return
        }
        arPenActivity.isHidden = true
        self.arPenImage.image = UIImage(named: "Cross")
        self.arPenImage.isHidden = false
        self.bluetoothARPenConnected = false
        self.setupPluginMenu()
        activatePlugin(withID: currentActivePluginID)
        checkVisualEffectView()
    }
    
    // This method will be called after `penConnected` and `arKitInitialized` to hide the blurry overlay
    func checkVisualEffectView() {
        if self.arPenActivity.isHidden && self.arKitActivity.isHidden {
//            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1), execute: {
//                UIView.animate(withDuration: 0.5, animations: {
//                    self.visualEffectView.alpha = 0.0
//                }, completion: { (completion) in
//                    self.visualEffectView.removeFromSuperview()
//                })
//            })
            self.visualEffectView.removeFromSuperview()
        }
    }
    
    // Software Pen Button Actions
    @IBAction func softwarePenButtonPressed(_ sender: Any) {
        self.pluginManager.button(.Button1, pressed: true)
    }
    
    @IBAction func softwarePenButtonReleased(_ sender: Any) {
        self.pluginManager.button(.Button1, pressed: false)
    }
    
    @IBAction func undoButtonPressed(_ sender: Any) {
        self.pluginManager.undoPreviousStep()
    }
    
    // MARK: - Persistence
    
    // Receives notification on when session or camera tracking state changes and updates label
    @objc func handleStateChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            print("notification.userInfo is empty")
            return
        }
        switch notification.name {
        case .sessionDidUpdate:
            updatePersistenceStateLabel(for: userInfo["frame"] as! ARFrame, trackingState: userInfo["trackingState"] as! ARCamera.TrackingState)
            
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
            updatePersistenceStateLabel(for: userInfo["currentFrame"] as! ARFrame, trackingState: userInfo["trackingState"] as! ARCamera.TrackingState)
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
                    self.showAlert(title: "Can't get current world map", message: error!.localizedDescription);
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
                    
                    if savedNode!.isLoaded == false {
                        print("No prior save found, saving current PenScene.")
                        scene.pencilPoint.removeFromParentNode() // Remove pencilPoint before saving
                        if scene.write(to: self.sceneSaveURL, options: nil, delegate: nil, progressHandler: nil) {
                            // Handle save if needed
                            scene.reinitializePencilPoint()
                            self.saveIsSuccessful = true
                        } else {
                            scene.reinitializePencilPoint()
                            return
                        }
                    }
                }
                self.persistenceStateLabel.text = "Write successful!"
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
    func updatePersistenceStateLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        var message: String = ""
        self.snapshotThumbnail.isHidden = true
        
        switch (trackingState) {
        case (.limited(.relocalizing)) where isRelocalizingMap:
            message = "Move your device to the location shown in the image."
            self.snapshotThumbnail.isHidden = false
        case .limited, .normal, .notAvailable:
            if (self.saveIsSuccessful) {
                message = "Save successful"
            }
            else {
                message = ""
            }
        }
        
        persistenceStateLabel.text = message
    }
    
    // Remove snapshot thumbnail
    @objc func removeSnapshotThumbnail(_ notification: Notification) {
        self.snapshotThumbnail.isHidden = true
    }
    
    // MARK: - ARSCNViewDelegate
    
    // Add nodes to the scene when a new anchor has been added
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("renderer()")
        guard anchor.name! == persistenceSavePointAnchorName
            else { return }

        // Save the reference to the virtual object anchor when the anchor is added from relocalizing
        if persistenceSavePointAnchor == nil {
            persistenceSavePointAnchor = anchor
        }
        
        // Perform rendering operations asynchronously
        DispatchQueue.main.async {
            self.placeholderNode = SCNReferenceNode(url: self.sceneSaveURL) // Fetch models saved earlier
            self.placeholderNode!.load()
            let scene = self.arSceneView.scene as! PenScene
            scene.drawingNode.addChildNode(self.placeholderNode!)
//            node.addChildNode(self.placeholderNode!)
        }
    }
}

