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
    var pencilPoint: SCNNode
    
    //Node that carries all the drawing operations
    let drawingNode: SCNNode
    /**
     If a marker was found in the current frame the var is true
     */
    var markerFound = true
    
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
        self.pencilPoint = SCNNode()
        self.drawingNode = SCNNode()
        super.init()
    }
    
    /**
     This initializer will be called after `init(named:)` is called.
     */
    required init?(coder aDecoder: NSCoder) {
        self.pencilPoint = SCNNode()
        self.drawingNode = SCNNode()
        super.init(coder: aDecoder)
        
        setupPencilPoint()
    }
    
    func setupPencilPoint() {        
        self.pencilPoint.geometry = SCNSphere(radius: 0.002)
        self.pencilPoint.name = "PencilPoint"
        self.pencilPoint.geometry?.materials.first?.diffuse.contents = UIColor.init(red: 0.73, green: 0.12157, blue: 0.8, alpha: 1)
        
        //simple coordinate system on the pencil point
        /*let coordSystemNode = SCNNode()
        let cylinderRadius = CGFloat(0.0005)
        let cylinderHeight = CGFloat(0.01)
        
        let xAxisGeometry = SCNCylinder(radius: cylinderRadius, height: cylinderHeight)
        xAxisGeometry.materials.first?.diffuse.contents = UIColor.red
        let xAxisNode = SCNNode(geometry: xAxisGeometry)
        xAxisNode.eulerAngles.z = -Float.pi/2
        xAxisNode.position.x = Float(cylinderHeight/2)
        coordSystemNode.addChildNode(xAxisNode)
        
        let yAxisGeometry = SCNCylinder(radius: cylinderRadius, height: cylinderHeight)
        yAxisGeometry.materials.first?.diffuse.contents = UIColor.green
        let yAxisNode = SCNNode(geometry: yAxisGeometry)
        yAxisNode.position.y = Float(cylinderHeight/2)
        coordSystemNode.addChildNode(yAxisNode)
        
        let zAxisGeometry = SCNCylinder(radius: cylinderRadius, height: cylinderHeight)
        zAxisGeometry.materials.first?.diffuse.contents = UIColor.blue
        let zAxisNode = SCNNode(geometry: zAxisGeometry)
        zAxisNode.eulerAngles.x = Float.pi/2
        zAxisNode.position.z = Float(cylinderHeight/2)
        coordSystemNode.addChildNode(zAxisNode)
        
        self.pencilPoint.addChildNode(coordSystemNode)*/
        
        self.rootNode.addChildNode(self.pencilPoint)
        self.rootNode.addChildNode(self.drawingNode)
    }
    
}
