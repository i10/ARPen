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
        self.pluginInstructionsImage = UIImage.init(named: "PathEditorInstructions")
        self.pluginIdentifier = "Path Editor"
        self.pluginGroupName = "Editor"
        self.needsBluetoothARPen = false
        
        nibNameOfCustomUIView = "ThreeButtons"
        buttonEvents.didPressButton = self.didPressButton
    }

    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        
        self.manipulator.activate(withScene: scene, andView: view, urManager: urManager)
            
        self.button1Label.text = "Select Geometry"
        self.button2Label.text = "Change Style / Move"
        self.button3Label.text = "0/2 chosen to insert betw."
    }
    
    override func deactivatePlugin() {
        manipulator.deactivate()
        
        super.deactivatePlugin()
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
        manipulator.update(scene: scene, buttons: buttons)
        
        DispatchQueue.main.async
        {
           /* if self.manipulator.pathPartSelector.count == 1
            {
                self.button3Label.text = "1/2 chosen to insert betw."
            }
            
            if self.manipulator.pathPartSelector.count == 2
            {
                self.button3Label.text = "0/2 chosen to insert betw."
            }*/
            
            self.button3Label.text = "\(self.manipulator.pathPartSelector.count)/2 chosen to insert betw."
        }
        
       
    }
    
    func didPressButton(_ button: Button) {
        
        switch button {
        case .Button1:
            if manipulator.selectedTargets.count == 1{
                DispatchQueue.main.async
                {
                    self.button1Label.text = "Select Geometry"
                }
            }
                
            if manipulator.selectedTargets.count == 0{
                DispatchQueue.main.async
                {
                    self.button1Label.text = "Deselect Geometry"
                }
            }
             
        case .Button2, .Button3:
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
