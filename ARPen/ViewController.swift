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
    
    /**
     The PluginManager instance
     */
    var pluginManager: PluginManager!
    
    /**
     A quite standard viewDidLoad
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        checkVisualEffectView()
    }
    
    func penFailed() {
        guard let arPenActivity = self.arPenActivity else {
            return
        }
        arPenActivity.isHidden = true
        self.arPenImage.image = UIImage(named: "Cross")
        self.arPenImage.isHidden = false
        checkVisualEffectView()
    }
    
    /**
     This method will be called after `penConnected` and `arKitInitialized` to may hide the blurry overlay
     */
    func checkVisualEffectView() {
        if self.arPenActivity.isHidden && self.arKitActivity.isHidden {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1), execute: {
                UIView.animate(withDuration: 0.5, animations: {
                    self.visualEffectView.alpha = 0.0
                }, completion: { (completion) in
                    self.visualEffectView.removeFromSuperview()
                })
            })
        }
    }
}
