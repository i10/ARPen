//
//  PenScene.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import SceneKit
import SceneKit.ModelIO

/**
 This is a subclass of `SCNScene`. It is used to hold the MarkerBox and centralize some methods
 */
class PenScene: SCNScene {
    
    /**
     The instance of the MarkerBox
     */
    var markerBox: MarkerBox!
    /**
     The pencil point is the node that corresponds to the real world pencil point.
     `pencilPoint.position` is always the best known position of the pencil point.
     */
    var pencilPoint = SCNNode()
    
    //Node that carries all the drawing operations
    let drawingNode = SCNNode()
    /**
     If a marker was found in the current frame the var is true
     */
    var markerFound = true
    
    
    var directionNode = SCNNode()
    var projectionNode = SCNNode()
    var arAnchorImage = SCNNode()
    
    /**
     Calling this method will convert the whole scene with every nodes in it to an stl file
     and saves it in the temporary directory as a file
     - Returns: An URL to the scene.stl file. Located in the tmp directory of the app
     */
    func share() -> URL {
        let filePath = URL(fileURLWithPath: NSTemporaryDirectory() + "/scene.stl")
        let drawingItems = MDLObject(scnNode: self.drawingNode)
        let asset = MDLAsset()
        asset.add(drawingItems)
        try! asset.export(to: filePath)
        return filePath
    }
    
    /**
     init. Should not be called. Is not called by SceneKit
     */
    override init() {
        super.init()
        
        setupPencilPoint()
    }
    
    // the following property is needed since initWithCoder is overwritten in this class. Since no decoding happens in the function and the decoding is passed on to the superclass, this class supports secure coding as well.
    override public class var supportsSecureCoding: Bool { return true }
    /**
     This initializer will be called after `init(named:)` is called.
     */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupPencilPoint()
    }
    
    func setupPencilPoint() {        
        self.pencilPoint.geometry = SCNSphere(radius: 0.002)
        self.pencilPoint.name = "PencilPoint"
        self.pencilPoint.geometry?.materials.first?.diffuse.contents = UIColor.init(red: 0.73, green: 0.12157, blue: 0.8, alpha: 1)
        
        self.projectionNode.geometry = SCNSphere(radius: 0.002)
        self.projectionNode.name = "projectionNode"

        self.projectionNode.geometry?.materials.first?.diffuse.contents = UIColor.green
        
        self.rootNode.addChildNode(self.pencilPoint)
        self.rootNode.addChildNode(self.drawingNode)
        self.rootNode.addChildNode(self.directionNode)
        self.rootNode.addChildNode(self.projectionNode)
    }
    
}
