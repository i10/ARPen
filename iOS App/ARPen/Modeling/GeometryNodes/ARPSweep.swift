//
//  ARPSweep.swift
//  ARPen
//
//  Created by Jan Benscheid on 26.03.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//
import Foundation

/**
 Node for creating a swept solid.
 */
class ARPSweep: ARPGeomNode {
    
    var profile: ARPPath
    var path: ARPPath

    init(profile: ARPPath, path: ARPPath) throws {
        
        self.profile = profile
        self.path = path
        super.init(pivotChild: profile)
        self.content.addChildNode(profile)
        self.content.addChildNode(path)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func build() throws -> OCCTReference {
        let ref = try? OCCTAPI.shared.sweep(profile: profile.occtReference!, path: path.occtReference!)
        
        if let r = ref {
            OCCTAPI.shared.setPivotOf(handle: r, pivot: pivotChild.worldTransform)
        }

        return ref ?? ""
    }
}
