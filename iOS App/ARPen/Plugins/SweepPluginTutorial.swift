//
//  SweepPluginTutorial.swift
//  ARPen
//
//  Created by Jan Benscheid on 29.9.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
 This class should demonstrate the exemplary usage of the geometry manipulation code.
 */
class SweepPluginTutorial: Plugin {
    
    @IBOutlet weak var button1Label: UILabel!
    @IBOutlet weak var button2Label: UILabel!
    @IBOutlet weak var button3Label: UILabel!
    
    /// Paths, which are not yet used to create a sweep
    private var freePaths: [ARPPath] = [ARPPath]()

    /// The curve designer "sub-plugin", responsible for the interactive path creation
    private var curveDesigner: CurveDesigner

    override init() {
        // Initialize curve designer
        curveDesigner = CurveDesigner()
        
        super.init()
        
        self.pluginImage = UIImage.init(named: "PaintPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "PaintPluginInstructions")
        self.pluginIdentifier = "Sweep Plugin Tutorial"
        self.needsBluetoothARPen = false
        self.pluginDisabledImage = UIImage.init(named: "ARMenusPluginDisabled")
        
        // This UI contains buttons to represent the other two buttons on the pen and an undo button
        // Important: when using this xib-file, implement the IBActions shown below and the IBOutlets above
        nibNameOfCustomUIView = "AllButtonsAndUndo"
        
        // Listen to the `didCompletePath` event.
        curveDesigner.didCompletePath = self.didCompletePath
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        super.activatePlugin(withScene: scene, andView: view)
        
        self.button1Label.text = "Finish"
        self.button2Label.text = "Sharp Corner"
        self.button3Label.text = "Round Corner"
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        curveDesigner.update(scene: scene, buttons: buttons)
    }

    func didCompletePath(_ path: ARPPath) {
        // Add newly completed path to set of free paths.
        freePaths.append(path)
        
        // Look in the free paths for one that is closed and one which is open and has more than one point.
        // Use them to create a sweep.
        if let profile = freePaths.first(where: { $0.closed }),
            let spine = freePaths.first(where: { !$0.closed && $0.points.count > 1 }) {
            
            // Geometry creation may take time and should be done asynchronous.
            DispatchQueue.global(qos: .userInitiated).async {
                
                // Only planar paths can be used as profile for sweeping.
                profile.flatten()
                
                // Try to create a sweep
                if let sweep = try? ARPSweep(profile: profile, path: spine) {
                    // Attach the swept object to the scene synchronous.
                    DispatchQueue.main.async {
                        self.currentScene?.drawingNode.addChildNode(sweep)
                        // Remove the links to the used paths from the set of free paths.
                        // You don't need to (and must not) delete the paths themselves. When creating the sweep, they became children of the `ARPSweep` object in order to allow for hierarchical editing.
                        self.freePaths.removeAll(where: { $0 === profile || $0 === spine })
                    }
                }
            }
        }
    }
    
    @IBAction func softwarePenButtonPressed(_ sender: UIButton) {
        var buttonEventDict = [String: Any]()
        switch sender.tag {
        case 2:
            buttonEventDict = ["buttonPressed": Button.Button2, "buttonState" : true]
        case 3:
            buttonEventDict = ["buttonPressed": Button.Button3, "buttonState" : true]
        default:
            print("other button pressed")
        }
        NotificationCenter.default.post(name: .softwarePenButtonEvent, object: nil, userInfo: buttonEventDict)
    }
    
    @IBAction func softwarePenButtonReleased(_ sender: UIButton) {
        var buttonEventDict = [String: Any]()
        switch sender.tag {
        case 2:
            buttonEventDict = ["buttonPressed": Button.Button2, "buttonState" : false]
        case 3:
            buttonEventDict = ["buttonPressed": Button.Button3, "buttonState" : false]
        default:
            print("other button pressed")
        }
        NotificationCenter.default.post(name: .softwarePenButtonEvent, object: nil, userInfo: buttonEventDict)
    }
    @IBAction func undoButtonPressed(_ sender: Any) {
        curveDesigner.undo()
    }
    
}
