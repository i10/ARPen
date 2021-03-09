//
//  CombinePluginFunction.swift
//  ARPen
//
//  Created by Jan Benscheid on 30.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class CombinePluginFunction: ModelingPlugin {

    private var buttonEvents: ButtonEvents
    private var arranger: Arranger
    

    override init() {
        arranger = Arranger()
        buttonEvents = ButtonEvents()

        super.init()

        self.pluginImage = UIImage.init(named: "Bool(Function)")
        self.pluginInstructionsImage = UIImage.init(named: "ModelingCombineFunctionInstructions")
        self.pluginIdentifier = "Combine(Function)"
        self.pluginGroupName = "Boolean Operations"
        self.needsBluetoothARPen = false
        
        buttonEvents.didPressButton = self.didPressButton
    }

    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        self.arranger.activate(withScene: scene, andView: view, urManager: urManager)
        
        self.button1Label.text = "Select/Move"
        self.button2Label.text = "Merge"
        self.button3Label.text = "Cut"
    }
    
    override func deactivatePlugin() {
        arranger.deactivate()
        
        super.deactivatePlugin()
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
        arranger.update(scene: scene, buttons: buttons)
    }
    
    func didPressButton(_ button: Button) {
        
        switch button {
        case .Button1:
            break
        case .Button2, .Button3:
            if arranger.selectedTargets.count == 2
            {
                guard let b = arranger.selectedTargets.removeFirst() as? ARPGeomNode,
                    let a = arranger.selectedTargets.removeFirst() as? ARPGeomNode
                
                else {
                        return
                }
            
                a.name = randomString(length: 10)
                b.name = randomString(length: 10)
                
                arranger.unselectTarget(a)
                arranger.unselectTarget(b)
                
                DispatchQueue.global(qos: .userInitiated).async {
                    if let diff = try? ARPBoolNode(a: a, b: b, operation: button == .Button2 ? .join : .cut) {
                        DispatchQueue.main.async {
                            self.currentScene?.drawingNode.addChildNode(diff)
                            

                        }
                        
                        let boolAction = BooleanAction(occtRef: diff.occtReference!, scene: self.currentScene!, boolNode: diff)
                        
                        self.undoRedoManager?.actionDone(boolAction)
                    }
                    
                }
            }
        }
    }
}
