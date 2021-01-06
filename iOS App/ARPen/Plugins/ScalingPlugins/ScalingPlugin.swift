//
//  ScalingPlugin.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 04.01.21.
//  Copyright © 2021 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class ScalingPlugin: Plugin {
    
    var scaler: PenRayScaler
    var buttonEvents: ButtonEvents

    @IBOutlet weak var button1Label: UILabel!
    @IBOutlet weak var button2Label: UILabel!
    @IBOutlet weak var button3Label: UILabel!
    
    override init() {
   
        buttonEvents = ButtonEvents()
        scaler = PenRayScaler()
        super.init()
        
        buttonEvents.didPressButton = self.didPressButton
        
        // This UI contains buttons to represent the other two buttons on the pen and an undo button
        // Important: when using this xib-file, implement the IBActions shown below and the IBOutlets above
        nibNameOfCustomUIView = "ThreeButtons"
 
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        self.scaler.activate(withScene: scene, andView: view, urManager: urManager)
        
        self.button1Label.text = "Select/Deselect Model"
        self.button2Label.text = "Corner Scaling"
        self.button3Label.text = "Center Scaling"

    }
    
    override func deactivatePlugin() {
        scaler.deactivate()
        
        super.deactivatePlugin()
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
        scaler.update(scene: scene, buttons: buttons)
    }
    
    func didPressButton(_ button: Button) {
        
        switch button {
        case .Button1:
            break
            
        case .Button2:
            break
            
        case .Button3:
            break
        
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
}
