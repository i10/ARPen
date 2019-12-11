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
    @IBOutlet weak var viewForCustomPluginView: UIView!
    
    let menuButtonHeight = 70
    let menuButtonPadding = 5
    var currentActivePluginID = 1
    
    var bluetoothARPenConnected: Bool = false
    /**
     The PluginManager instance
     */
    var pluginManager: PluginManager!
    
    //Manager for user study data
    let userStudyRecordManager = UserStudyRecordManager()
    
    
    /**
     A quite standard viewDidLoad
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pluginInstructionsLookupButton.layer.masksToBounds = true
        self.pluginInstructionsLookupButton.layer.cornerRadius = self.pluginInstructionsLookupButton.frame.width/2
        
        self.settingsButton.layer.masksToBounds = true
        self.settingsButton.layer.cornerRadius = self.settingsButton.frame.width/2
        
        self.undoButton.layer.masksToBounds = true
        self.undoButton.layer.cornerRadius = self.undoButton.frame.width/2
        
        self.undoButton.isHidden = false
        self.undoButton.isEnabled = true
        
        // Create a new scene
        let scene = PenScene(named: "art.scnassets/ship.scn")!
        scene.markerBox = MarkerBox()
        self.arSceneView.pointOfView?.addChildNode(scene.markerBox)
        
        self.pluginManager = PluginManager(scene: scene)
        self.pluginManager.delegate = self
        self.arSceneView.session.delegate = self.pluginManager.arManager
        
        self.arSceneView.autoenablesDefaultLighting = true
        self.arSceneView.pointOfView?.name = "iDevice Camera"
        
        // Set the scene to the view
        arSceneView.scene = scene
        
        // Setup tap gesture recognizer for imageForPluginInstructions
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:  #selector(ViewController.imageForPluginInstructionsTapped(_:)))
        self.imageForPluginInstructions.isUserInteractionEnabled = true
        self.imageForPluginInstructions.addGestureRecognizer(tapGestureRecognizer)
        
        // Hide the imageForPluginInstructions
        self.imageForPluginInstructions.isHidden = true
        //self.displayPluginInstructions(forPluginID: currentActivePluginID)
        
        // set user study record manager reference in the app delegate (for saving state when leaving the app)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.userStudyRecordManager = self.userStudyRecordManager
        } else {
            print("Record manager was not set up in App Delegate")
        }
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        arSceneView.session.pause()
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func setupPluginMenu(){
        //define target height and width for the scrollview to hold all buttons
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
            //remove custom view elements from view
            currentActivePlugin.customPluginUI?.removeFromSuperview()
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
                if let customPluginUI = newActivePlugin.customPluginUI {
                    viewForCustomPluginView.addSubview(customPluginUI)
                }
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
    
    /**
     Prepare the SettingsViewController by passing the scene
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else { return }
        
        if segueIdentifier == "ShowSettingsSegue" {
            let destinationVC = segue.destination as! UINavigationController
            guard let destinationSettingsController = destinationVC.viewControllers.first as? SettingsTableViewController else {
                return
                
            }
            destinationSettingsController.scene = self.arSceneView.scene as! PenScene
            //pass reference to the record manager (to show active user ID and export data)
            destinationSettingsController.userStudyRecordManager = self.userStudyRecordManager
            destinationSettingsController.bluetoothARPenConnected = self.bluetoothARPenConnected
        }
        
    }
    
    
    // Mark: - ARManager Delegate
    /**
     Callback from the ARManager
     */
    func arKitInitialiazed() {
        guard let arKitActivity = self.arKitActivity else {
            return
        }
        arKitActivity.isHidden = true
        self.arKitImage.isHidden = false
        checkVisualEffectView()
    }
    
    // Mark: - PenManager delegate
    /**
     Callback from PenManager
     */
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
    
    /**
     This method will be called after `penConnected` and `arKitInitialized` to may hide the blurry overlay
     */
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
}
