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

class ViewController: UIViewController, ARSCNViewDelegate, PluginManagerDelegate {

    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var arPenLabel: UILabel!
    @IBOutlet weak var arPenActivity: UIActivityIndicatorView!
    @IBOutlet weak var arKitLabel: UILabel!
    @IBOutlet weak var arKitActivity: UIActivityIndicatorView!
    
    
    @IBOutlet var arSceneView: ARSCNView!
    
    var pluginManager: PluginManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        // arSceneView.delegate = arManager
        
        // Show statistics such as fps and timing information
        // arSceneView.showsStatistics = true
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        arSceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        arSceneView.session.pause()
    }
    
    func share() {
        let filePath = (self.arSceneView.scene as! PenScene).share()
        let view = UIActivityViewController(activityItems: [filePath], applicationActivities: nil)
        self.present(view, animated: true, completion: nil)
    }
    
    func arKitInitialiazed() {
        self.arKitActivity.isHidden = true
        checkVisualEffectView()
    }
    
    func penConnected() {
        self.arPenActivity.isHidden = true
        checkVisualEffectView()
    }
    
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
    
    /*
     if (self.btIndicatior.isHidden && self.arkitIndicator.isHidden) {
     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
     [UIView animateWithDuration:0.5 animations:^{
     self.visualEffectView.alpha = 0.0;
     } completion:^(BOOL finished) {
     [self.visualEffectView removeFromSuperview];
     }];
     });
     }
 */
    
}
