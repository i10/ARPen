//
//  SweepPluginTutorial.swift
//  ARPen
//
//  Created by Jan Benscheid on 29.9.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
 This class should demonstrate the exemplary usage of the geometry manipulation code.
 */
class SweepPluginTutorial: ModelingPlugin {
    
    /// Paths, which are not yet used to create a sweep
    private var freePaths: [ARPPath] = [ARPPath]()

    override init() {

        super.init()
        
        // Listen to the `didCompletePath` event.
        curveDesigner.didCompletePath = self.didCompletePath
        
        self.pluginImage = UIImage.init(named: "PaintPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "PaintPluginInstructions")
        self.pluginIdentifier = "Sweep Plugin Tutorial"
        self.needsBluetoothARPen = false
        self.pluginDisabledImage = UIImage.init(named: "ARMenusPluginDisabled")
    }

    func didCompletePath(_ path: ARPPath) {
        // Add newly completed path to set of free paths.
        freePaths.append(path)
        
        // Look in the free paths for one that is closed and one which is open and has more than one point.
        // Use them to create a sweep.
        if let profile = freePaths.first(where: { $0.closed }),
            let spine = freePaths.first(where: { !$0.closed && $0.points.count > 1 }) {
            
            // Geometry creation may take time and should be done asynchronous.
            DispatchQueue.global(qos: .userInitiated).async {
                
                // Only planar paths can be used as profile for sweeping.
                profile.flatten()
                
                // Try to create a sweep
                if let sweep = try? ARPSweep(profile: profile, path: spine) {
                    // Attach the swept object to the scene synchronous.
                    DispatchQueue.main.async {
                        self.currentScene?.drawingNode.addChildNode(sweep)
                        // Remove the links to the used paths from the set of free paths.
                        // You don't need to (and must not) delete the paths themselves. When creating the sweep, they became children of the `ARPSweep` object in order to allow for hierarchical editing.
                        self.freePaths.removeAll(where: { $0 === profile || $0 === spine })
                    }
                }
            }
        }
    }
    
}
