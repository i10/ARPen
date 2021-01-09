//
//  PathEditorPlugin.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 08.01.21.
//  Copyright © 2021 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class PathEditorPlugin: Plugin {

    private var buttonEvents: ButtonEvents
    private var manipulator: PathManipulator
    
    @IBOutlet weak var button1Label: UILabel!
    @IBOutlet weak var button2Label: UILabel!
    @IBOutlet weak var button3Label: UILabel!


    override init() {
        manipulator = PathManipulator()
        buttonEvents = ButtonEvents()
        
        super.init()

        self.pluginImage = UIImage.init(named: "ModelingPathPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "ModelingCombineFunctionInstructions")
        self.pluginIdentifier = "Path Editor"
        self.pluginGroupName = "Editor"
        self.needsBluetoothARPen = false
        
        nibNameOfCustomUIView = "ThreeButtons"
        buttonEvents.didPressButton = self.didPressButton
    }

    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        
        self.manipulator.activate(withScene: scene, andView: view, urManager: urManager)
            
        self.button1Label.text = "Select and Deselect Geometry"
        self.button2Label.text = "Change Style / Move Node"
        self.button3Label.text = "Insert Node"
    }
    
    override func deactivatePlugin() {
        manipulator.deactivate()
        
        super.deactivatePlugin()
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
        manipulator.update(scene: scene, buttons: buttons)
    }
    
    func didPressButton(_ button: Button) {
        
        switch button {
        case .Button1, .Button2, .Button3:
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
