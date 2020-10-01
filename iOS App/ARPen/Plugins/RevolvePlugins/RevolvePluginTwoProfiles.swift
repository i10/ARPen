//
//  RevolvePluginTwoProfiles.swift
//  ARPen
//
//  Created by Jan Benscheid on 15.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class RevolvePluginTwoProfiles: ModelingPlugin {
    
    private var freePaths: [ARPPath] = [ARPPath]()
    private var busy: Bool = false
    
    override init() {

        super.init()
        
        // Listen to the `didCompletePath` event.
        curveDesigner.didCompletePath = self.didCompletePath
        
        self.pluginImage = UIImage.init(named: "ModelingRevolve3Plugin")
        self.pluginInstructionsImage = UIImage.init(named: "PaintPluginInstructions")
        self.pluginIdentifier = "Revolve (Two Profiles)"
        self.pluginGroupName = "Modeling"
        self.needsBluetoothARPen = false
    }
    
    func didCompletePath(_ path: ARPPath) {
        freePaths.append(path)
        if let profile1 = freePaths.first(where: { !$0.closed && $0.points.count >= 2 }),
           let profile2 = freePaths.last(where: { !$0.closed && $0.points.count >= 2 }),
            profile1 !== profile2 {
            
            DispatchQueue.global(qos: .userInitiated).async {
                profile1.flatten()
                profile2.flatten()
                
                let profile1Start = profile1.points.first!.worldPosition
                let profile1End = profile1.points.last!.worldPosition
                let profile2Start = profile2.points.first!.worldPosition
                let profile2End = profile2.points.last!.worldPosition
                
                // The following lines determine which start- and endpoints of the profiles belong to each other, in case one profile was drawn e.g. top to bottom, and the other bottom to top.
                let centerStart, centerEnd: SCNVector3!
                let distanceParallel = profile1Start.distance(vector: profile2Start) + profile1End.distance(vector: profile2End)
                let distanceCross = profile1Start.distance(vector: profile2End) + profile1End.distance(vector: profile2Start)
                
                if distanceParallel < distanceCross {
                    centerStart = (profile1Start + profile2Start) / 2
                    centerEnd = (profile1End + profile2End) / 2
                } else {
                    centerStart = (profile1Start + profile2End) / 2
                    centerEnd = (profile1End + profile2Start) / 2
                }

                let axisPath = ARPPath(points: [
                    ARPPathNode(centerStart),
                    ARPPathNode(centerEnd)
                    ], closed: false);
                
                
                if let revolution = try? ARPRevolution(profile: profile1, axis: axisPath) {
                    
                    DispatchQueue.main.async {
                        self.currentScene?.drawingNode.addChildNode(revolution)
                        profile2.removeFromParentNode()
                        self.freePaths.removeAll(where: { $0 === profile1 || $0 == profile2 })
                    }
                }
            }
        }
    }
}
