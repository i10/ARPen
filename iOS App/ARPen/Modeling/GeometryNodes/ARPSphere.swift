//
//  ARPSphere.swift
//  ARPen
//
//  Created by Jan Benscheid on 15.02.19.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation

class ARPSphere: ARPGeomNode {
    
    var radius: Double = 0.5
    
    override init() {
        super.init()
    }
    
    init(radius: Double) {
        self.radius = radius
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func build() throws -> OCCTReference {
        return try OCCTAPI.shared.createSphere(radius: radius)
    }
}
