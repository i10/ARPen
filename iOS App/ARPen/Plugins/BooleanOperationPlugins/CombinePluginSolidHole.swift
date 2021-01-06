//
//  CombinePluginSolidHole.swift
//  ARPen
//
//  Created by Jan Benscheid on 19.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//
import ARKit

class CombinePluginSolidHole: ModelingPlugin {

    private var buttonEvents: ButtonEvents
    private var arranger: Arranger
    
    override init() {
        arranger = Arranger()
        buttonEvents = ButtonEvents()
        
        super.init()
        
        self.pluginImage = UIImage.init(named: "Bool(Hole)")
        self.pluginInstructionsImage = UIImage.init(named: "ModelingCombineSolidHoleInstructions")
        self.pluginIdentifier = "Combine(Hole)"
        self.pluginGroupName = "Modeling"
        self.needsBluetoothARPen = false
        
        buttonEvents.didPressButton = self.didPressButton
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        // Forward activation to arranger
        self.arranger.activate(withScene: scene, andView: view, urManager: urManager)
        
        self.button1Label.text = "Select/Move"
        self.button2Label.text = "Solid ↔ Hole"
        self.button3Label.text = "Combine"
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
        case .Button2:
            for case let target as ARPGeomNode in arranger.selectedTargets {
                target.isHole = !target.isHole
            }
            if case let target as ARPGeomNode = arranger.hoverTarget, !arranger.selectedTargets.contains(target) {
                target.isHole = !target.isHole
            }
        case .Button3:
            if arranger.selectedTargets.count == 2 {
                guard let a = arranger.selectedTargets.removeFirst() as? ARPGeomNode,
                   let b = arranger.selectedTargets.removeFirst() as? ARPGeomNode else {
                        return
                }
                
                arranger.unselectTarget(a)
                arranger.unselectTarget(b)
                
                var target = a
                var tool = b
                var createHole = false
                var operation: BooleanOperation!
                if a.isHole == b.isHole {
                    operation = .join
                    if a.isHole {
                        /// Hole + hole = join, but new object is a hole
                        createHole = true
                    }
                } else {
                    operation = .cut
                    target = b.isHole ? a : b
                    tool = b.isHole ? b : a
                }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    if let res = try? ARPBoolNode(a: target, b: tool, operation: operation) {
                        
                        DispatchQueue.main.async {
                            self.currentScene?.drawingNode.addChildNode(res)
                            res.isHole = createHole
                        }
                        
                        let boolAction = BooleanAction(occtRef: res.occtReference!, scene: self.currentScene!, boolNode: res)
                        
                        self.undoRedoManager?.actionDone(boolAction)
                    }
                }
            }
        }
    }
}
