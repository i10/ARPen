//
//  LoftPlugin.swift
//  ARPen
//
//  Created by Jan Benscheid on 16.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class LoftPlugin: ModelingPlugin {

    private var freePaths: [ARPPath] = [ARPPath]()
    private var loft: ARPLoft?
    private var busy: Bool = false
    
    override init() {

        super.init()
 
        curveDesigner.didCompletePath = self.didCompletePath
        
        self.pluginImage = UIImage.init(named: "ModelingLoftPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "ModelingLoftInstructions")
        self.pluginIdentifier = "Loft"
        self.pluginGroupName = "Modeling"
        self.needsBluetoothARPen = false
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager){
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)

        self.freePaths.removeAll()
        self.loft = nil
    }
    
    func didCompletePath(_ path: ARPPath) {
        
        if !(path.closed || path.points.count == 1) {
            return
        }
        
        path.flatten()
        freePaths.append(path)
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let l = self.loft {
               // let prevProfiles = l.profiles
                l.addProfile(path)
                self.freePaths.removeAll(where: { $0 === path })
                
               // path.usedInGeometry = true
                //let buildingAction = LoftExpandingAction(occtRef: l.occtReference!, scene: self.currentScene!, prevLoft: l, newLoft: l)
                
               // print(prevProfiles)
                
                //self.undoRedoManager?.actionDone(buildingAction)
                
            } else {
                if self.freePaths.count >= 2 {
                    let paths = [self.freePaths.removeFirst(), self.freePaths.removeFirst()]
                    if let l = try? ARPLoft(profiles: paths) {
                        self.loft = l
                        DispatchQueue.main.async {
                            self.currentScene?.drawingNode.addChildNode(l)
                        }
                        
                        for path in paths {
                            path.usedInGeometry = true
                        }
                        
                        let buildingAction = LoftBuildingAction(occtRef: l.occtReference!, scene: self.currentScene!, loft: l)
                        self.undoRedoManager?.actionDone(buildingAction)
                    }
                }
            }
        }
    }
}
