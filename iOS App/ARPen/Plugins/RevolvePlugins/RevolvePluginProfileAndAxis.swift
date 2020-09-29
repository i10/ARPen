//
//  RevolvePluginProfileAndAxis.swift
//  ARPen
//
//  Created by Jan Benscheid on 15.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class RevolvePluginProfileAndAxis: ModelingPlugin {
    
    private var freePaths: [ARPPath] = [ARPPath]()
    private var busy: Bool = false
        

    override init() {
        super.init()
        
        curveDesigner.didCompletePath = self.didCompletePath
        
        self.pluginImage = UIImage.init(named: "Revolve(Profile+Axis)")
        self.pluginInstructionsImage = UIImage.init(named: "PaintPluginInstructions")
        self.pluginIdentifier = "Revolve (Profile + Axis)"
        self.pluginGroupName = "Modeling"
        self.needsBluetoothARPen = false
        self.pluginDisabledImage = UIImage.init(named: "ARMenusPluginDisabled")
    }
    
    func didCompletePath(_ path: ARPPath) {
        freePaths.append(path)
        if let profile = freePaths.first(where: { !$0.closed && $0.points.count > 2 }),
            let axisPath = freePaths.first(where: { !$0.closed && $0.points.count == 2 }) {
                        
            DispatchQueue.global(qos: .userInitiated).async {
                profile.flatten()
                
                if let revolution = try? ARPRevolution(profile: profile, axis: axisPath) {
                    
                    DispatchQueue.main.async {
                        self.currentScene?.drawingNode.addChildNode(revolution)
                        self.freePaths.removeAll(where: { $0 === profile || $0 === axisPath })
                    }
                }
            }
        }
    }   
}
