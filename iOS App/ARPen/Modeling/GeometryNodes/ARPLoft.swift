//
//  ARPLoft.swift
//  ARPen
//
//  Created by Jan Benscheid on 16.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

/**
 Node for creating a lofted solid.
 */
class ARPLoft: ARPGeomNode {
    
    var profiles: [ARPPath]
    
    init(profiles: [ARPPath]) throws {
        
        self.profiles = profiles
        
        super.init(pivotChild: profiles[0])
        
        for profile in profiles {
            self.content.addChildNode(profile)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addProfile(_ profile: ARPPath) {
        profiles.append(profile)
        content.addChildNode(profile)
        profile.isHidden = true
        rebuild()
    }
    
    override func build() throws -> OCCTReference {
        let ref = try? OCCTAPI.shared.loft(profiles: profiles.map({ $0.occtReference! }))
        
        if let r = ref {
            OCCTAPI.shared.setPivotOf(handle: r, pivot: pivotChild.worldTransform)
        }
        
        return ref ?? ""
    }
}
