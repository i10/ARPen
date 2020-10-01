//
//  RevolvePluginProfileAndCircle.swift
//  ARPen
//
//  Created by Jan Benscheid on 15.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class RevolvePluginProfileAndCircle: ModelingPlugin {
    
    private var freePaths: [ARPPath] = [ARPPath]()
    private var busy: Bool = false
    
    override init() {

        super.init()
        
        // Listen to the `didCompletePath` event.
        curveDesigner.didCompletePath = self.didCompletePath
        
        self.pluginImage = UIImage.init(named: "Revolve(Profile+Circle)")
        self.pluginInstructionsImage = UIImage.init(named: "PaintPluginInstructions")
        self.pluginIdentifier = "Revolve (Profile + Circle"
        self.pluginGroupName = "Modeling"
        self.needsBluetoothARPen = false
    }
    
    func didCompletePath(_ path: ARPPath) {
        freePaths.append(path)
        if let profile = freePaths.first(where: { !$0.closed && $0.points.count >= 2 }),
            let circle = freePaths.first(where: { $0.closed }) {
            
            DispatchQueue.global(qos: .userInitiated).async {
                profile.flatten()
                circle.flatten()
                
                let axisDir = circle.getPC1()
                let axisPos = OCCTAPI.shared.circleCenter(circle.getPointsAsVectors())
                let axisPath = ARPPath(points: [
                    ARPPathNode(axisPos),
                    ARPPathNode(axisPos + axisDir)
                    ], closed: false);
                
                if let revolution = try? ARPRevolution(profile: profile, axis: axisPath) {
                    
                    DispatchQueue.main.async {
                        self.currentScene?.drawingNode.addChildNode(revolution)
                        circle.removeFromParentNode()
                        self.freePaths.removeAll(where: { $0 === profile || $0 == circle })
                    }
                }
            }
        }
    }
}
