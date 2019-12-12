//
//  CurvePlugin.swift
//  ARPen
//
//  Created by Jan Benscheid on 30.06.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class CurvePlugin: Plugin {
    

    @IBOutlet weak var button1Label: UILabel!
    @IBOutlet weak var button2Label: UILabel!
    @IBOutlet weak var button3Label: UILabel!
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    
    private var curveDesigner: CurveDesigner
    
    override init() {
        curveDesigner = CurveDesigner()
        
        super.init()
        
        self.pluginImage = UIImage.init(named: "PaintPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "PaintPluginInstructions")
        self.pluginIdentifier = "Paint Curves"
        self.needsBluetoothARPen = false
        self.pluginDisabledImage = UIImage.init(named: "ARMenusPluginDisabled")
        
        nibNameOfCustomUIView = "AllButtonsAndUndo"
 
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
