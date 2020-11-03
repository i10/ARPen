//
//  SweepPluginProfileAndPath.swift
//  ARPen
//
//  Created by Jan Benscheid on 04.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class SweepPluginProfileAndPath: ModelingPlugin {
   
    private var freePaths: [ARPPath] = [ARPPath]()
    private var busy: Bool = false

    override init() {
        
        super.init()
        
        curveDesigner.didCompletePath = self.didCompletePath
        
        self.pluginImage = UIImage.init(named: "ModelingSweep1Plugin")
        self.pluginInstructionsImage = UIImage.init(named: "ModelingSweep1Instructions")
        self.pluginIdentifier = "Sweep (Path)"
        self.pluginGroupName = "Modeling"
        self.needsBluetoothARPen = false
    }

    func didCompletePath(_ path: ARPPath) {
        freePaths.append(path)
        if let profile = freePaths.first(where: { $0.closed }),
            let spine = freePaths.first(where: { !$0.closed && $0.points.count > 1 }) {
            DispatchQueue.global(qos: .userInitiated).async {
                profile.flatten()
                                
                if let sweep = try? ARPSweep(profile: profile, path: spine) {
                    
                    
                    print("sweep.position: \(sweep.position)")
                    
                    //Spheres
                    //ll2
                    let sphere_min = SCNSphere(radius: 0.005)
                    sphere_min.firstMaterial?.diffuse.contents = UIColor.systemGreen
                    let node_sphere_min = SCNNode(geometry: sphere_min)
                    node_sphere_min.position = sweep.boundingBox.min
                   
                    
                    //ur1
                    let sphere_max = SCNSphere(radius: 0.005)
                    sphere_max.firstMaterial?.diffuse.contents = UIColor.systemGreen
                    let node_sphere_max = SCNNode(geometry: sphere_max)
                    node_sphere_max.position = sweep.boundingBox.max
                    
                    print("sweep")
                    print(sweep.boundingBox.min)
                    print(sweep.boundingBox.max)
                    print("sweep")
                    
                    DispatchQueue.main.async {
                        self.currentScene?.drawingNode.addChildNode(sweep)
                        self.currentScene?.drawingNode.addChildNode(node_sphere_min)
                        self.currentScene?.drawingNode.addChildNode(node_sphere_max)
                     
                        self.freePaths.removeAll(where: { $0 === profile || $0 === spine })
                    }

                    
                }
            }
        }
    }
}
