//
//  ARPCube.swift
//  ARPen
//
//  Created by Jan Benscheid on 18.02.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class ARPCylinder: ARPGeomNode {
    
    var radius: Double = 1
    var height: Double = 1
    
    override init() {
        super.init()
    }
    
    init(radius: Double, height: Double) {
        self.radius = radius
        self.height = height
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func build() throws -> OCCTReference {
        return try OCCTAPI.shared.createCylinder(radius: self.radius, height: self.height)
    }
}
