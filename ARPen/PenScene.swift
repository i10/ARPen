//
//  PenScene.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import SceneKit
import SceneKit.ModelIO

class PenScene: SCNScene {
    
    
    var markerBox: MarkerBox!
    var pencilPoint: SCNNode
    var previousPoint: SCNVector3?
    
    func share() -> URL {
        let filePath = URL(fileURLWithPath: NSTemporaryDirectory() + "/scene.stl")
        let asset = MDLAsset(scnScene: self)
        try! asset.export(to: filePath)
        return filePath
    }
    
    override init() {
        self.pencilPoint = SCNNode()
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.pencilPoint = SCNNode()
        super.init(coder: aDecoder)
        
        self.pencilPoint.geometry = SCNSphere(radius: 0.002)
        self.pencilPoint.name = "PencilPoint"
        self.pencilPoint.geometry?.materials.first?.diffuse.contents = UIColor.red
        
        self.rootNode.addChildNode(self.pencilPoint)
    }
    
    
}
