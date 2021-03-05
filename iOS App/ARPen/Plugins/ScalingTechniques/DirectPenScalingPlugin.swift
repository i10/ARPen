//
//  DirectPen.swift
//  ARPen
//
//  Created by Farhadiba Mohammed on 09.08.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

//include the UserStudyRecordPluginProtocol to demo recording of user study data
class DirectPenScalingPlugin: Plugin {
    
    private var recStarted :Bool = false
    private var finished :Bool = false
    private var training :Bool = false

    var confirmPressed : Bool = false
    var undoPressed : Bool = false

    var currentPoint = CGPoint()
    var scaleFactor : Float = 0

    private var insideSphere : SCNNode? = nil
    private var highlighted: Bool = false

    //Variables for bounding Box updates
    var centerPosition = SCNVector3()
    var updatedWidth : Float = 0
    var updatedHeight : Float = 0
    var updatedLength : Float = 0
    //l = left, r = right, b = back, f = front, d = down, h = high
    var corners : (lbd : SCNVector3, lfd : SCNVector3, rbd : SCNVector3, rfd : SCNVector3, lbh : SCNVector3, lfh : SCNVector3, rbh : SCNVector3, rfh : SCNVector3) = (SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0))

    var screenCorners : (lbd : CGPoint, lfd : CGPoint, rbd : CGPoint, rfd : CGPoint, lbh : CGPoint, lfh : CGPoint, rbh : CGPoint, rfh : CGPoint) = (CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0))

    var edges : (e1 : SCNVector3, e2 : SCNVector3, e3 : SCNVector3, e4 : SCNVector3, e5 : SCNVector3, e6 : SCNVector3, e7 : SCNVector3, e8 : SCNVector3, e9 : SCNVector3, e10 : SCNVector3, e11 : SCNVector3, e12 : SCNVector3) = (SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0), SCNVector3Make(0, 0, 0), SCNVector3Make(0, 0, 0), SCNVector3Make(0, 0, 0), SCNVector3Make(0, 0, 0))

    //Variables to ensure only one Corner an be selected at a time
    var selectedCorner = SCNNode()
    var selected : Bool = false
    var tapped1 : Bool = false
    var tapped2 : Bool = false
    var tapped3 : Bool = false
    var tapped4 : Bool = false
    var tapped5 : Bool = false
    var tapped6 : Bool = false
    var tapped7 : Bool = false
    var tapped8 : Bool = false

    //Corner Variables for diagonals
    var next_rfh = SCNVector3()
    var next_lbd = SCNVector3()
    var next_lfh = SCNVector3()
    var next_rbd = SCNVector3()
    var next_rbh = SCNVector3()
    var next_lfd = SCNVector3()
    var next_lbh = SCNVector3()
    var next_rfd = SCNVector3()
    var dirVector1 = CGPoint()
    var dirVector2 = CGPoint()
    var dirVector3 = CGPoint()
    var dirVector4 = CGPoint()

    //variables for initial bounding Box
    var originalWidth : Float = 0
    var originalHeight : Float = 0
    var originalLength : Float = 0
    var originalScale = SCNVector3()

    //Variables for text
    var widthIncmStr : String = ""
    var heightIncmStr : String = ""
    var lengthIncmStr : String = ""

    //Variables For USER STUDY TASK
    var userStudyReps = 0
    var selectionCounter = 0

    //variables for measuring
    var finalWidth : Float = 0
    var finalHeight : Float = 0
    var finalLength : Float = 0

    var randomValue: String = ""
    var target = String()

    var startTime : Date = Date()
    var endTime : Date = Date()
    var elapsedTime: Double = 0.0
    
    override init() {
        super.init()
        
        self.pluginImage = UIImage.init(named: "ScalingPen")
        self.pluginInstructionsImage = UIImage.init(named: "ScalingDirectPenInstructions")
        
        self.pluginIdentifier = "Direct Pen"
        self.needsBluetoothARPen = false
        self.pluginGroupName = "Scaling"
        self.isExperimentalPlugin = true
    }
    
    func reset(){
        guard let scene = self.currentScene else {return}
        guard let box = scene.drawingNode.childNode(withName: "currentBoundingBox", recursively: false) else{
            print("not found")
            return
           }
           guard let r2d2 = scene.drawingNode.childNode(withName: "currentr2d2", recursively: false) else{
               print("not found")
               return
           }
            guard let text1 = scene.drawingNode.childNode(withName: "widthString", recursively: false) else{
              print("not found")
              return
             }
            guard let text2 = scene.drawingNode.childNode(withName: "heightString", recursively: false) else{
              print("not found")
              return
             }
            guard let text3 = scene.drawingNode.childNode(withName: "lengthString", recursively: false) else{
              print("not found")
              return
             }
           guard let sceneView = self.currentView else { return }
        
            //reset box and model
            selected = false
            tapped1 = false
            tapped2 = false
            tapped3 = false
            tapped4 = false
            tapped5 = false
            tapped6 = false
            tapped7 = false
            tapped8 = false

            //compute random width/height/length users should scale the object to
            let randomWidth = String(format: "%.1f",Float.random(in: 3...15))
            let randomHeight = String(format: "%.1f",Float.random(in: 8...25))
            let randomLength = String(format: "%.1f",Float.random(in: 3...12))
            
            //Vary between width/ height/length
            let randomTarget = Int.random(in: 1...3)
            if randomTarget == 1{
                DispatchQueue.main.async {
                    //self.targetLabel.text = "Width: \(randomWidth)"
                    self.target = "width"
                    self.randomValue = randomWidth
                }
            }
            if randomTarget == 2{
                DispatchQueue.main.async {
                    //self.targetLabel.text = "Height: \(randomHeight)"
                    self.target = "height"
                    self.randomValue = randomHeight
                }
            }
            if randomTarget == 3{
                DispatchQueue.main.async {
                    //self.targetLabel.text = "Length: \(randomLength)"
                    self.target = "length"
                    self.randomValue = randomLength
                }
            }
        
            selectedCorner.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            
            updatedWidth = originalWidth
            updatedHeight = originalHeight
            updatedLength = originalLength
            
            box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
            box.position = SCNVector3(0,0.2,0)
            centerPosition = box.position
            box.scale = SCNVector3(originalScale.x, originalScale.y, originalScale.z)
            r2d2.scale = SCNVector3(0.001,0.001,0.001)
            r2d2.position = centerPosition
            
            setCorners()
            setSpherePosition()
            removeAllEdges()
            setEdges()
            colorEdgesBlue()
        
            text1.opacity = 0.01
            text2.opacity = 0.01
            text3.opacity = 0.01
            //measurement variables
            selectionCounter = 0
            elapsedTime = 0.0
    }

    
    //need to adjust the corners while scaling visually
    func setSpherePosition(){
        guard let scene = self.currentScene else {return}
        guard let sphere1 = scene.drawingNode.childNode(withName: "lbdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere2 = scene.drawingNode.childNode(withName: "lfdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere3 = scene.drawingNode.childNode(withName: "rbdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere4 = scene.drawingNode.childNode(withName: "rfdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere5 = scene.drawingNode.childNode(withName: "lbhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere6 = scene.drawingNode.childNode(withName: "lfhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere7 = scene.drawingNode.childNode(withName: "rbhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere8 = scene.drawingNode.childNode(withName: "rfhCorner", recursively: false) else{
            print("not found")
            return
        }
        
        sphere1.position = corners.lbd
        sphere2.position = corners.lfd
        sphere3.position = corners.rbd
        sphere4.position = corners.rfd
        sphere5.position = corners.lbh
        sphere6.position = corners.lfh
        sphere7.position = corners.rbh
        sphere8.position = corners.rfh
    }
    
    func setCorners() {
        let thePosition = centerPosition
        let halfWidth = Float(updatedWidth/2)
        let halfHeight = Float(updatedHeight/2)
        let halfLength = Float(updatedLength/2)

        self.corners.lbd = SCNVector3Make(thePosition.x - halfWidth, thePosition.y - halfHeight, thePosition.z - halfLength)
        self.corners.lfd = SCNVector3Make(thePosition.x - halfWidth, thePosition.y - halfHeight, thePosition.z + halfLength)
        self.corners.rbd = SCNVector3Make(thePosition.x + halfWidth, thePosition.y - halfHeight, thePosition.z - halfLength)
        self.corners.rfd = SCNVector3Make(thePosition.x + halfWidth, thePosition.y - halfHeight, thePosition.z + halfLength)
        self.corners.lbh = SCNVector3Make(thePosition.x - halfWidth, thePosition.y + halfHeight, thePosition.z - halfLength)
        self.corners.lfh = SCNVector3Make(thePosition.x - halfWidth, thePosition.y + halfHeight, thePosition.z + halfLength)
        self.corners.rbh = SCNVector3Make(thePosition.x + halfWidth, thePosition.y + halfHeight, thePosition.z - halfLength)
        self.corners.rfh = SCNVector3Make(thePosition.x + halfWidth, thePosition.y + halfHeight, thePosition.z + halfLength)
    }
    
    func setScreenCorners(){
        guard let sceneView = self.currentView else { return }
        self.screenCorners.lbd = CGPoint(x: Double(sceneView.projectPoint(corners.lbd).x), y: Double(sceneView.projectPoint(corners.lbd).y))
        self.screenCorners.lfd = CGPoint(x: Double(sceneView.projectPoint(corners.lfd).x), y: Double(sceneView.projectPoint(corners.lfd).y))
        self.screenCorners.rbd = CGPoint(x: Double(sceneView.projectPoint(corners.rbd).x), y: Double(sceneView.projectPoint(corners.rbd).y))
        self.screenCorners.rfd = CGPoint(x: Double(sceneView.projectPoint(corners.rfd).x), y: Double(sceneView.projectPoint(corners.rfd).y))
        self.screenCorners.lbh = CGPoint(x: Double(sceneView.projectPoint(corners.lbh).x), y: Double(sceneView.projectPoint(corners.lbh).y))
        self.screenCorners.lfh = CGPoint(x: Double(sceneView.projectPoint(corners.lfh).x), y: Double(sceneView.projectPoint(corners.lfh).y))
        self.screenCorners.rbh = CGPoint(x: Double(sceneView.projectPoint(corners.rbh).x), y: Double(sceneView.projectPoint(corners.rbh).y))
        self.screenCorners.rfh = CGPoint(x: Double(sceneView.projectPoint(corners.rfh).x), y: Double(sceneView.projectPoint(corners.rfh).y))
    }
    
    //compute the diagonals to drag the corner along
    func lineBetweenNodes(positionA: SCNVector3, positionB: SCNVector3, inScene: SCNScene) -> SCNNode {
        let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        let midPosition = SCNVector3 (x:(positionA.x + positionB.x) / 2, y:(positionA.y + positionB.y) / 2, z:(positionA.z + positionB.z) / 2)

        let lineGeometry = SCNCylinder()
        lineGeometry.radius = 0.001
        lineGeometry.height = CGFloat(distance)
        lineGeometry.radialSegmentCount = 5
        lineGeometry.firstMaterial!.diffuse.contents = UIColor.systemOrange

        let lineNode = SCNNode(geometry: lineGeometry)
        lineNode.opacity = 0.01
        lineNode.position = midPosition
        lineNode.look (at: positionB, up: inScene.rootNode.worldUp, localFront: lineNode.worldUp)
        return lineNode
    }
    
    func setEdges(){
        guard let scene = self.currentScene else {return}
        //edge between lfd to rfd
        let edge1 = lineBetweenNodes(positionA: corners.lfd, positionB: corners.rfd, inScene: scene)
        if edge1 != scene.drawingNode.childNode(withName: "edge1", recursively: false){
            edge1.name = "edge1"
            edge1.opacity = 0.6
            scene.drawingNode.addChildNode(edge1)
            self.edges.e1 = SCNVector3 (x:(corners.lfd.x + corners.rfd.x) / 2, y:(corners.lfd.y + corners.rfd.y) / 2, z:(corners.lfd.z + corners.rfd.z) / 2)
        }
        //edge between lfd to lfh
        let edge2 = lineBetweenNodes(positionA: corners.lfd, positionB: corners.lfh, inScene: scene)
        if edge2 != scene.drawingNode.childNode(withName: "edge2", recursively: false){
            edge2.name = "edge2"
            edge2.opacity = 0.6
            scene.drawingNode.addChildNode(edge2)
            self.edges.e2 = SCNVector3 (x:(corners.lfd.x + corners.lfh.x) / 2, y:(corners.lfd.y + corners.lfh.y) / 2, z:(corners.lfd.z + corners.lfh.z) / 2)
        }
        //edge between lfh to rfh
        let edge3 = lineBetweenNodes(positionA: corners.lfh, positionB: corners.rfh, inScene: scene)
        if edge3 != scene.drawingNode.childNode(withName: "edge3", recursively: false){
            edge3.name = "edge3"
            edge3.opacity = 0.6
            scene.drawingNode.addChildNode(edge3)
            self.edges.e3 = SCNVector3 (x:(corners.lfh.x + corners.rfh.x) / 2, y:(corners.lfh.y + corners.rfh.y) / 2, z:(corners.lfh.z + corners.rfh.z) / 2)
        }
        //edge between rfh to rfd
        let edge4 = lineBetweenNodes(positionA: corners.rfh, positionB: corners.rfd, inScene: scene)
        if edge4 != scene.drawingNode.childNode(withName: "edge4", recursively: false){
            edge4.name = "edge4"
            edge4.opacity = 0.6
            scene.drawingNode.addChildNode(edge4)
            self.edges.e4 = SCNVector3 (x:(corners.rfh.x + corners.rfd.x) / 2, y:(corners.rfh.y + corners.rfd.y) / 2, z:(corners.rfh.z + corners.rfd.z) / 2)
        }
        //edge between lfd to lbd
        let edge5 = lineBetweenNodes(positionA: corners.lfd, positionB: corners.lbd, inScene: scene)
        if edge5 != scene.drawingNode.childNode(withName: "edge5", recursively: false){
            edge5.name = "edge5"
            edge5.opacity = 0.6
            scene.drawingNode.addChildNode(edge5)
            self.edges.e5 = SCNVector3 (x:(corners.lfd.x + corners.lbd.x) / 2, y:(corners.lfd.y + corners.lbd.y) / 2, z:(corners.lfd.z + corners.lbd.z) / 2)
        }
        //edge between lbd to lbh
        let edge6 = lineBetweenNodes(positionA: corners.lbd, positionB: corners.lbh, inScene: scene)
        if edge6 != scene.drawingNode.childNode(withName: "edge6", recursively: false){
            edge6.name = "edge6"
            edge6.opacity = 0.6
            scene.drawingNode.addChildNode(edge6)
            self.edges.e6 = SCNVector3 (x:(corners.lbd.x + corners.lbh.x) / 2, y:(corners.lbd.y + corners.lbh.y) / 2, z:(corners.lbd.z + corners.lbh.z) / 2)
        }
        //edge between lbh to lfh
        let edge7 = lineBetweenNodes(positionA: corners.lbh, positionB: corners.lfh, inScene: scene)
        if edge7 != scene.drawingNode.childNode(withName: "edge7", recursively: false){
            edge7.name = "edge7"
            edge7.opacity = 0.6
            scene.drawingNode.addChildNode(edge7)
            self.edges.e7 = SCNVector3 (x:(corners.lbh.x + corners.lfh.x) / 2, y:(corners.lbh.y + corners.lfh.y) / 2, z:(corners.lbh.z + corners.lfh.z) / 2)
        }
        //edge between lbh to rbh
        let edge8 = lineBetweenNodes(positionA: corners.lbh, positionB: corners.rbh, inScene: scene)
        if edge8 != scene.drawingNode.childNode(withName: "edge8", recursively: false){
            edge8.name = "edge8"
            edge8.opacity = 0.6
            scene.drawingNode.addChildNode(edge8)
            self.edges.e8 = SCNVector3 (x:(corners.lbh.x + corners.rbh.x) / 2, y:(corners.lbh.y + corners.rbh.y) / 2, z:(corners.lbh.z + corners.rbh.z) / 2)
        }
        //edge between rbh to rfh
        let edge9 = lineBetweenNodes(positionA: corners.rbh, positionB: corners.rfh, inScene: scene)
        if edge9 != scene.drawingNode.childNode(withName: "edge9", recursively: false){
            edge9.name = "edge9"
            edge9.opacity = 0.6
            scene.drawingNode.addChildNode(edge9)
            self.edges.e9 = SCNVector3 (x:(corners.rbh.x + corners.rfh.x) / 2, y:(corners.rbh.y + corners.rfh.y) / 2, z:(corners.rbh.z + corners.rfh.z) / 2)
        }
        //edge between rbh to rbd
        let edge10 = lineBetweenNodes(positionA: corners.rbh, positionB: corners.rbd, inScene: scene)
        if edge10 != scene.drawingNode.childNode(withName: "edge10", recursively: false){
            edge10.name = "edge10"
            edge10.opacity = 0.6
            scene.drawingNode.addChildNode(edge10)
            self.edges.e10 = SCNVector3 (x:(corners.rbh.x + corners.rbd.x) / 2, y:(corners.rbh.y + corners.rbd.y) / 2, z:(corners.rbh.z + corners.rbd.z) / 2)
        }
        //edge between rfd to rbd
        let edge11 = lineBetweenNodes(positionA: corners.rfd, positionB: corners.rbd, inScene: scene)
        if edge11 != scene.drawingNode.childNode(withName: "edge11", recursively: false){
            edge11.name = "edge11"
            edge11.opacity = 0.6
            scene.drawingNode.addChildNode(edge11)
            self.edges.e11 = SCNVector3 (x:(corners.rfd.x + corners.rbd.x) / 2, y:(corners.rfd.y + corners.rbd.y) / 2, z:(corners.rfd.z + corners.rbd.z) / 2)
        }
        //edge between lbd to rbd
        let edge12 = lineBetweenNodes(positionA: corners.lbd, positionB: corners.rbd, inScene: scene)
        if edge12 != scene.drawingNode.childNode(withName: "edge12", recursively: false){
            edge12.name = "edge12"
            edge12.opacity = 0.6
            scene.drawingNode.addChildNode(edge12)
            self.edges.e12 = SCNVector3 (x:(corners.lbd.x + corners.rbd.x) / 2, y:(corners.lbd.y + corners.rbd.y) / 2, z:(corners.lbd.z + corners.rbd.z) / 2)
        }
    }
    
    func removeAllEdges(){
        guard let scene = self.currentScene else {return}
        guard let edge1 = scene.drawingNode.childNode(withName: "edge1", recursively: false) else{
            print("not found")
            return
        }
        guard let edge2 = scene.drawingNode.childNode(withName: "edge2", recursively: false) else{
            print("not found")
            return
        }
        guard let edge3 = scene.drawingNode.childNode(withName: "edge3", recursively: false) else{
            print("not found")
            return
        }
        guard let edge4 = scene.drawingNode.childNode(withName: "edge4", recursively: false) else{
            print("not found")
            return
        }
        guard let edge5 = scene.drawingNode.childNode(withName: "edge5", recursively: false) else{
            print("not found")
            return
        }
        guard let edge6 = scene.drawingNode.childNode(withName: "edge6", recursively: false) else{
            print("not found")
            return
        }
        guard let edge7 = scene.drawingNode.childNode(withName: "edge7", recursively: false) else{
            print("not found")
            return
        }
        guard let edge8 = scene.drawingNode.childNode(withName: "edge8", recursively: false) else{
            print("not found")
            return
        }
        guard let edge9 = scene.drawingNode.childNode(withName: "edge9", recursively: false) else{
            print("not found")
            return
        }
        guard let edge10 = scene.drawingNode.childNode(withName: "edge10", recursively: false) else{
            print("not found")
            return
        }
        guard let edge11 = scene.drawingNode.childNode(withName: "edge11", recursively: false) else{
            print("not found")
            return
        }
        guard let edge12 = scene.drawingNode.childNode(withName: "edge12", recursively: false) else{
            print("not found")
            return
        }
        edge1.removeFromParentNode()
        edge2.removeFromParentNode()
        edge3.removeFromParentNode()
        edge4.removeFromParentNode()
        edge5.removeFromParentNode()
        edge6.removeFromParentNode()
        edge7.removeFromParentNode()
        edge8.removeFromParentNode()
        edge9.removeFromParentNode()
        edge10.removeFromParentNode()
        edge11.removeFromParentNode()
        edge12.removeFromParentNode()
    }
    
    //changes color to yellow to visualize activated boundingBox
    func colorEdgesBlue(){
        guard let scene = self.currentScene else {return}
        guard let edge1 = scene.drawingNode.childNode(withName: "edge1", recursively: false) else{
            print("not found")
            return
        }
        guard let edge2 = scene.drawingNode.childNode(withName: "edge2", recursively: false) else{
            print("not found")
            return
        }
        guard let edge3 = scene.drawingNode.childNode(withName: "edge3", recursively: false) else{
            print("not found")
            return
        }
        guard let edge4 = scene.drawingNode.childNode(withName: "edge4", recursively: false) else{
            print("not found")
            return
        }
        guard let edge5 = scene.drawingNode.childNode(withName: "edge5", recursively: false) else{
            print("not found")
            return
        }
        guard let edge6 = scene.drawingNode.childNode(withName: "edge6", recursively: false) else{
            print("not found")
            return
        }
        guard let edge7 = scene.drawingNode.childNode(withName: "edge7", recursively: false) else{
            print("not found")
            return
        }
        guard let edge8 = scene.drawingNode.childNode(withName: "edge8", recursively: false) else{
            print("not found")
            return
        }
        guard let edge9 = scene.drawingNode.childNode(withName: "edge9", recursively: false) else{
            print("not found")
            return
        }
        guard let edge10 = scene.drawingNode.childNode(withName: "edge10", recursively: false) else{
            print("not found")
            return
        }
        guard let edge11 = scene.drawingNode.childNode(withName: "edge11", recursively: false) else{
            print("not found")
            return
        }
        guard let edge12 = scene.drawingNode.childNode(withName: "edge12", recursively: false) else{
            print("not found")
            return
        }
        
        edge1.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge2.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge3.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge4.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge5.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge6.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge7.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge8.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge9.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge10.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge11.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge12.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        
    }
    
    //changes color to yellow to visualize activated boundingBox
    func colorCornersBlue(){
        guard let scene = self.currentScene else {return}
        guard let corner1 = scene.drawingNode.childNode(withName: "lbdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner2 = scene.drawingNode.childNode(withName: "lfdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner3 = scene.drawingNode.childNode(withName: "rbdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner4 = scene.drawingNode.childNode(withName: "rfdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner5 = scene.drawingNode.childNode(withName: "lbhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner6 = scene.drawingNode.childNode(withName: "lfhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner7 = scene.drawingNode.childNode(withName: "rbhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner8 = scene.drawingNode.childNode(withName: "rfhCorner", recursively: false) else{
            print("not found")
            return
        }
        
        corner1.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        corner2.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        corner3.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        corner4.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        corner5.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        corner6.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        corner7.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        corner8.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
       
        
    }
    
    func highlightIfPointInsideSphere(point : SCNVector3){
        //check if point is inside a corner sphere, radius 0.008
        guard let scene = self.currentScene else {return}
        guard let sphere1 = scene.drawingNode.childNode(withName: "lbdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere2 = scene.drawingNode.childNode(withName: "lfdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere3 = scene.drawingNode.childNode(withName: "rbdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere4 = scene.drawingNode.childNode(withName: "rfdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere5 = scene.drawingNode.childNode(withName: "lbhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere6 = scene.drawingNode.childNode(withName: "lfhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere7 = scene.drawingNode.childNode(withName: "rbhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere8 = scene.drawingNode.childNode(withName: "rfhCorner", recursively: false) else{
            print("not found")
            return
        }
        
        if (corners.lbd.x - 0.008 <= point.x && point.x <= corners.lbd.x + 0.008 && corners.lbd.y - 0.008 <= point.y && point.y <= corners.lbh.y + 0.008
            && corners.lbd.z - 0.008 <= point.z && point.z <= corners.lbd.z + 0.008){
            sphere1.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
            insideSphere = sphere1
        }
        else if (corners.lfd.x - 0.008 <= point.x && point.x <= corners.lfd.x + 0.008 && corners.lfd.y - 0.008 <= point.y && point.y <= corners.lfd.y + 0.008
        && corners.lfd.z - 0.008 <= point.z && point.z <= corners.lfd.z + 0.008){
            sphere2.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
            insideSphere = sphere2
        }
        else if (corners.rbd.x - 0.008 <= point.x && point.x <= corners.rbd.x + 0.008 && corners.rbd.y - 0.008 <= point.y && point.y <= corners.rbd.y + 0.008
        && corners.rbd.z - 0.008 <= point.z && point.z <= corners.rbd.z + 0.008){
            sphere3.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
            insideSphere = sphere3
        }
        else if (corners.rfd.x - 0.008 <= point.x && point.x <= corners.rfd.x + 0.008 && corners.rfd.y - 0.008 <= point.y && point.y <= corners.rfd.y + 0.008
        && corners.rfd.z - 0.008 <= point.z && point.z <= corners.rfd.z + 0.008){
            sphere4.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
            insideSphere = sphere4
        }
        else if (corners.lbh.x - 0.008 <= point.x && point.x <= corners.lbh.x + 0.008 && corners.lbh.y - 0.008 <= point.y && point.y <= corners.lbh.y + 0.008
        && corners.lbh.z - 0.008 <= point.z && point.z <= corners.lbh.z + 0.008){
            sphere5.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
            insideSphere = sphere5
        }
        else if (corners.lfh.x - 0.008 <= point.x && point.x <= corners.lfh.x + 0.008 && corners.lfh.y - 0.008 <= point.y && point.y <= corners.lfh.y + 0.008
        && corners.lfh.z - 0.008 <= point.z && point.z <= corners.lfh.z + 0.008){
            sphere6.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
            insideSphere = sphere6
        }
        else if  (corners.rbh.x - 0.008 <= point.x && point.x <= corners.rbh.x + 0.008 && corners.rbh.y - 0.008 <= point.y && point.y <= corners.rbh.y + 0.008
               && corners.rbh.z - 0.008 <= point.z && point.z <= corners.rbh.z + 0.008){
            sphere7.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
            insideSphere = sphere7
        }
        else if (corners.rfh.x - 0.008 <= point.x && point.x <= corners.rfh.x + 0.008 && corners.rfh.y - 0.008 <= point.y && point.y <= corners.rfh.y + 0.008
        && corners.rfh.z - 0.008 <= point.z && point.z <= corners.rfh.z + 0.008){
            sphere8.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
            insideSphere  = sphere8
        }
        else{
            if training{
                sphere1.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
                sphere2.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
                sphere3.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
                sphere4.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
                sphere5.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
                sphere6.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
                sphere7.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
                sphere8.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
            }else{
                colorCornersBlue()
            }
        }
    }
    
    func dotProduct(vecA: CGPoint, vecB: CGPoint)-> CGFloat{
        return (vecA.x * vecB.x + vecA.y * vecB.y)
    }

    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        setScreenCorners()
        //define initial diagonals
        dirVector1 = CGPoint(x: screenCorners.lbd.x - screenCorners.rfh.x, y: screenCorners.lbd.y - screenCorners.rfh.y)
        dirVector2 = CGPoint(x: screenCorners.rbd.x - screenCorners.lfh.x, y: screenCorners.rbd.y - screenCorners.lfh.y)
        dirVector3 = CGPoint(x: screenCorners.lfd.x - screenCorners.rbh.x, y: screenCorners.lfd.y - screenCorners.rbh.y)
        dirVector4 = CGPoint(x: screenCorners.rfd.x - screenCorners.lbh.x, y: screenCorners.rfd.y - screenCorners.lbh.y)
        guard let scene = self.currentScene else {return}
        guard let sceneView = self.currentView else { return }
        guard let box = scene.drawingNode.childNode(withName: "currentBoundingBox", recursively: false) else{
         print("not found")
         return
        }
        guard let line1 = scene.drawingNode.childNode(withName: "diagonal1", recursively: false) else{
            print("not found")
            return
        }
        guard let line2 = scene.drawingNode.childNode(withName: "diagonal2", recursively: false) else{
            print("not found")
            return
        }
        guard let line3 = scene.drawingNode.childNode(withName: "diagonal3", recursively: false) else{
            print("not found")
            return
        }
        guard let line4 = scene.drawingNode.childNode(withName: "diagonal4", recursively: false) else{
            print("not found")
            return
        }
        guard let r2d2 = scene.drawingNode.childNode(withName: "currentr2d2", recursively: false) else{
            print("not found")
            return
        }
        guard let corner1 = scene.drawingNode.childNode(withName: "lbdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner2 = scene.drawingNode.childNode(withName: "lfdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner3 = scene.drawingNode.childNode(withName: "rbdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner4 = scene.drawingNode.childNode(withName: "rfdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner5 = scene.drawingNode.childNode(withName: "lbhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner6 = scene.drawingNode.childNode(withName: "lfhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner7 = scene.drawingNode.childNode(withName: "rbhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner8 = scene.drawingNode.childNode(withName: "rfhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let edge1 = scene.drawingNode.childNode(withName: "edge1", recursively: false) else{
            print("not found")
            return
        }
        guard let edge2 = scene.drawingNode.childNode(withName: "edge2", recursively: false) else{
            print("not found")
            return
        }
        guard let edge3 = scene.drawingNode.childNode(withName: "edge3", recursively: false) else{
            print("not found")
            return
        }
        guard let edge4 = scene.drawingNode.childNode(withName: "edge4", recursively: false) else{
            print("not found")
            return
        }
        guard let edge5 = scene.drawingNode.childNode(withName: "edge5", recursively: false) else{
            print("not found")
            return
        }
        guard let edge6 = scene.drawingNode.childNode(withName: "edge6", recursively: false) else{
            print("not found")
            return
        }
        guard let edge7 = scene.drawingNode.childNode(withName: "edge7", recursively: false) else{
            print("not found")
            return
        }
        guard let edge8 = scene.drawingNode.childNode(withName: "edge8", recursively: false) else{
            print("not found")
            return
        }
        guard let edge9 = scene.drawingNode.childNode(withName: "edge9", recursively: false) else{
            print("not found")
            return
        }
        guard let edge10 = scene.drawingNode.childNode(withName: "edge10", recursively: false) else{
            print("not found")
            return
        }
        guard let edge11 = scene.drawingNode.childNode(withName: "edge11", recursively: false) else{
            print("not found")
            return
        }
        guard let edge12 = scene.drawingNode.childNode(withName: "edge12", recursively: false) else{
            print("not found")
            return
        }
        guard let text1 = scene.drawingNode.childNode(withName: "widthString", recursively: false) else{
          print("not found")
          return
         }
        guard let text2 = scene.drawingNode.childNode(withName: "heightString", recursively: false) else{
          print("not found")
          return
         }
        guard let text3 = scene.drawingNode.childNode(withName: "lengthString", recursively: false) else{
          print("not found")
          return
         }
        let pressed = buttons[Button.Button1]!
        
        highlightIfPointInsideSphere(point: scene.pencilPoint.position)
        
        if pressed{
            //only perform scaling if pentip is inside corner sphere
            if let corner = self.insideSphere{
                corner.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                    //select:lbd --> pivot:rfh
                    if corner == corner1 {
                        if selected == false{
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selected = true
                            selectedCorner = corner1
                            tapped1 = true
                            //box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), Float(updatedHeight/2), Float(updatedLength/2))
                            box.pivot = SCNMatrix4MakeTranslation(Float(abs(corners.rfh.x - centerPosition.x)), Float(abs(corners.rfh.y - centerPosition.y)), Float(abs(corners.rfh.z - centerPosition.z)))
                            box.position = corners.rfh
                            
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e12.x - 0.025 , y:edges.e12.y - 0.015, z:edges.e12.z)
                                text1.opacity = 1
                            }
                            
                            if let textGeometry2 = text2.geometry as? SCNText {
                                textGeometry2.string = "H:\(heightIncmStr)cm"
                                text2.opacity = 1
                                text2.position = SCNVector3(x:edges.e6.x - 0.06, y:edges.e6.y + 0.05, z:edges.e6.z)
                            }
                            
                            if let textGeometry3 = text3.geometry as? SCNText {
                                textGeometry3.string = "L:\(lengthIncmStr)cm"
                                text3.opacity = 1
                                text3.position = SCNVector3(x:edges.e5.x - 0.06 , y:edges.e5.y, z:edges.e5.z)
                            }
                        }
                    }
                    //select:lfd --> pivot:rbh
                    else if corner == corner2{
                        if selected == false{
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selected = true
                            selectedCorner = corner2
                            tapped2 = true
                            //box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), Float(updatedHeight/2), -Float(updatedLength/2))
                            box.pivot = SCNMatrix4MakeTranslation(Float(corners.rbh.x-centerPosition.x), Float(corners.rbh.y-centerPosition.y), Float(corners.rbh.z-centerPosition.z))
                            box.position = corners.rbh
                            
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e1.x-0.025, y:edges.e1.y - 0.015, z:edges.e1.z)
                                text1.opacity = 1
                            }
                            if let textGeometry2 = text2.geometry as? SCNText {
                                textGeometry2.string = "H:\(heightIncmStr)cm"
                                text2.opacity = 1
                                text2.position = SCNVector3(x:edges.e2.x - 0.06, y:edges.e2.y, z:edges.e2.z)
                            }
                            if let textGeometry3 = text3.geometry as? SCNText {
                                textGeometry3.string = "L:\(lengthIncmStr)cm"
                                text3.opacity = 1
                                text3.position = SCNVector3(x:edges.e5.x - 0.06 , y:edges.e5.y, z:edges.e5.z)
                            }
                        }
                    }
                    //select:rbd --> pivot:lfh
                    else if corner == corner3 {
                        if selected == false{
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selected = true
                            selectedCorner = corner3
                            tapped3 = true
                            //box.pivot = SCNMatrix4MakeTranslation(-Float(updatedWidth/2), Float(updatedHeight/2), Float(updatedLength/2))
                            box.pivot = SCNMatrix4MakeTranslation(Float(corners.lfh.x + centerPosition.x), Float( corners.lfh.y - centerPosition.y), Float(corners.lfh.z - centerPosition.z))
                            box.position = corners.lfh
                            
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e12.x-0.025, y:edges.e12.y - 0.015, z:edges.e12.z)
                                text1.opacity = 1
                            }
                            
                            if let textGeometry2 = text2.geometry as? SCNText {
                                textGeometry2.string = "H:\(heightIncmStr)cm"
                                text2.opacity = 1
                                text2.position = SCNVector3(x:edges.e10.x + 0.01, y:edges.e10.y, z:edges.e10.z)
                            }
                            
                            if let textGeometry3 = text3.geometry as? SCNText {
                                textGeometry3.string = "L:\(lengthIncmStr)cm"
                                text3.opacity = 1
                                text3.position = SCNVector3(x:edges.e11.x + 0.01 , y:edges.e11.y, z:edges.e11.z)
                            }
                        }
                    }
                    //select:rfd --> pivot:lbh
                    else if corner == corner4 {
                        if selected == false{
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selected = true
                            selectedCorner = corner4
                            tapped4 = true
                            //box.pivot = SCNMatrix4MakeTranslation(-Float(updatedWidth/2), Float(updatedHeight/2), -Float(updatedLength/2))
                            box.pivot = SCNMatrix4MakeTranslation(Float(corners.lbh.x-centerPosition.x), Float(corners.lbh.y-centerPosition.y), Float(corners.lbh.z-centerPosition.z))
                            box.position = corners.lbh
                            
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e1.x-0.025, y:edges.e1.y - 0.015, z:edges.e1.z)
                                text1.opacity = 1
                            }
                            
                            if let textGeometry2 = text2.geometry as? SCNText {
                                textGeometry2.string = "H:\(heightIncmStr)cm"
                                text2.opacity = 1
                                text2.position = SCNVector3(x:edges.e4.x  + 0.01 , y:edges.e4.y, z:edges.e4.z)
                            }
                            
                            if let textGeometry3 = text3.geometry as? SCNText {
                                textGeometry3.string = "L:\(lengthIncmStr)cm"
                                text3.opacity = 1
                                text3.position = SCNVector3(x:edges.e11.x + 0.01 , y:edges.e11.y, z:edges.e11.z)
                            }
                        }
                    }
                    //select:lbh --> pivot:rfd
                    else if corner == corner5{
                        if selected == false{
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selected = true
                            selectedCorner = corner5
                            tapped5 = true
                            //box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), -Float(updatedHeight/2), Float(updatedLength/2))
                            box.pivot = SCNMatrix4MakeTranslation(Float(corners.rfd.x-centerPosition.x), Float(corners.rfd.y-centerPosition.y), Float(corners.rfd.z-centerPosition.z))
                            box.position = corners.rfd
                            
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e8.x-0.025, y:edges.e8.y + 0.015, z:edges.e8.z)
                                text1.opacity = 1
                            }
                            
                            if let textGeometry2 = text2.geometry as? SCNText {
                                textGeometry2.string = "H:\(heightIncmStr)cm"
                                text2.opacity = 1
                                text2.position = SCNVector3(x:edges.e6.x - 0.06 , y:edges.e6.y - 0.01, z:edges.e6.z)
                            }
                            
                            if let textGeometry3 = text3.geometry as? SCNText {
                                textGeometry3.string = "L:\(lengthIncmStr)cm"
                                text3.opacity = 1
                                text3.position = SCNVector3(x:edges.e7.x - 0.06, y:edges.e7.y, z:edges.e7.z)
                            }
                        }
                    }
                    //select:lfh --> pivot:rbd
                    else if corner == corner6{
                        if selected == false{
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selected = true
                            selectedCorner = corner6
                            tapped6 = true
                            //box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), -Float(updatedHeight/2), -Float(updatedLength/2))
                            box.pivot = SCNMatrix4MakeTranslation(Float(corners.rbd.x-centerPosition.x), Float(corners.rbd.y-centerPosition.y), Float(corners.rbd.z-centerPosition.z))
                            box.position = corners.rbd
                            
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e3.x-0.025, y:edges.e3.y + 0.01, z:edges.e3.z)
                                text1.opacity = 1
                            }
                            
                            if let textGeometry2 = text2.geometry as? SCNText {
                                textGeometry2.string = "H:\(heightIncmStr)cm"
                                text2.opacity = 1
                                text2.position = SCNVector3(x:edges.e2.x - 0.06, y:edges.e2.y - 0.01, z:edges.e2.z)
                            }
                            
                            if let textGeometry3 = text3.geometry as? SCNText {
                                textGeometry3.string = "L:\(lengthIncmStr)cm"
                                text3.opacity = 1
                                text3.position = SCNVector3(x:edges.e7.x - 0.06, y:edges.e7.y, z:edges.e7.z)
                            }
                        }
                    }
                    //select:rbh --> pivot:lfd
                    else if corner == corner7 {
                        if selected == false{
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selected = true
                            selectedCorner = corner7
                            tapped7 = true
                            //box.pivot = SCNMatrix4MakeTranslation(-Float(updatedWidth/2), -Float(updatedHeight/2), Float(updatedLength/2))
                            box.pivot = SCNMatrix4MakeTranslation(Float(corners.lfd.x-centerPosition.x), Float(corners.lfd.y-centerPosition.y), Float(corners.lfd.z-centerPosition.z))
                            box.position = corners.lfd
                            
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e8.x-0.025, y:edges.e8.y + 0.015, z:edges.e8.z)
                                text1.opacity = 1
                            }
                            if let textGeometry2 = text2.geometry as? SCNText {
                                textGeometry2.string = "H:\(heightIncmStr)cm"
                                text2.opacity = 1
                                text2.position = SCNVector3(x:edges.e10.x + 0.01, y:edges.e10.y - 0.01, z:edges.e10.z)
                            }
                            
                            if let textGeometry3 = text3.geometry as? SCNText {
                                textGeometry3.string = "L:\(lengthIncmStr)cm"
                                text3.opacity = 1
                                text3.position = SCNVector3(x:edges.e9.x + 0.01, y:edges.e9.y, z:edges.e9.z)
                            }
                        }
                    }
                    //select:rfh --> pivot:lbd
                    else if corner == corner8 {
                        if selected == false{
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selected = true
                            selectedCorner = corner8
                            tapped8 = true
                            //box.pivot = SCNMatrix4MakeTranslation(-Float(0.5*updatedWidth), -Float(0.5*updatedHeight), -Float(0.5*updatedLength))
                            box.pivot = SCNMatrix4MakeTranslation(Float(corners.lbd.x-centerPosition.x), Float(corners.lbd.y-centerPosition.y), Float(corners.lbd.z-centerPosition.z))
                            box.position = corners.lbd
                            
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e3.x-0.025, y:edges.e3.y + 0.01, z:edges.e3.z)
                                text1.opacity = 1
                            }
                            if let textGeometry2 = text2.geometry as? SCNText {
                                textGeometry2.string = "H:\(heightIncmStr)cm"
                                text2.opacity = 1
                                text2.position = SCNVector3(x:edges.e4.x+0.01, y:edges.e4.y, z:edges.e4.z)
                            }
                            
                            if let textGeometry3 = text3.geometry as? SCNText {
                                textGeometry3.string = "L:\(lengthIncmStr)cm"
                                text3.opacity = 1
                                text3.position = SCNVector3(x:edges.e9.x + 0.01, y:edges.e9.y, z:edges.e9.z)
                            }
                        }
                    }
                
               
                if selected == true {
                    currentPoint = CGPoint(x: Double(sceneView.projectPoint(scene.pencilPoint.position).x), y: Double(sceneView.projectPoint(scene.pencilPoint.position).y))
                    //Project onto diagonal connecting lbd and rfh if one of the corners is selected
                    if (tapped1 || tapped8){
                        let vecA = CGPoint(x:currentPoint.x - screenCorners.rfh.x, y:currentPoint.y - screenCorners.rfh.y)
                        let scalar1 = dotProduct(vecA: vecA , vecB: dirVector1)  / dotProduct(vecA: dirVector1, vecB: dirVector1)
                        let scaledDirVec = CGPoint(x: dirVector1.x * scalar1, y: dirVector1.y * scalar1)
                        let projectedPoint1 = CGPoint(x: screenCorners.rfh.x + scaledDirVec.x, y: screenCorners.rfh.y + scaledDirVec.y)
                        var hitTestResult = sceneView.hitTest(projectedPoint1, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
                        for hit in hitTestResult{
                                let currentPointInWC = hit.worldCoordinates
                            updatedHeight = Float(CGFloat(abs(currentPointInWC.y - box.position.y)))
                                let scaleFactor = Float(updatedHeight / originalHeight)
                                updatedWidth = originalWidth * (scaleFactor)
                                updatedLength = originalLength * (scaleFactor)
                                
                                let widthIncmStr = String(format: "%.1f",updatedWidth*100)
                                let heightIncmStr = String(format: "%.1f",updatedHeight*100)
                                let lengthIncmStr = String(format: "%.1f",updatedLength*100)

                                if(tapped1){
                                    centerPosition = SCNVector3(x: corners.rfh.x - Float(updatedWidth/2), y: corners.rfh.y - Float(updatedHeight/2), z: corners.rfh.z - Float(updatedLength/2))
                                    r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                                    r2d2.position = centerPosition
                                    if let textGeometry1 = text1.geometry as? SCNText {
                                        textGeometry1.string = "W:\(widthIncmStr)cm"
                                        text1.position = SCNVector3(x:edges.e12.x - 0.025 , y:edges.e12.y - 0.015, z:edges.e12.z)
                                        text1.opacity = 1
                                    }
                                    
                                    if let textGeometry2 = text2.geometry as? SCNText {
                                        textGeometry2.string = "H:\(heightIncmStr)cm"
                                        text2.opacity = 1
                                        text2.position = SCNVector3(x:edges.e6.x - 0.06, y:edges.e6.y + 0.05, z:edges.e6.z)
                                    }
                                    
                                    if let textGeometry3 = text3.geometry as? SCNText {
                                        textGeometry3.string = "L:\(lengthIncmStr)cm"
                                        text3.opacity = 1
                                        text3.position = SCNVector3(x:edges.e5.x - 0.06 , y:edges.e5.y, z:edges.e5.z)
                                    }
                                }
                                else if(tapped8){
                                    centerPosition = SCNVector3(x: corners.lbd.x + Float(updatedWidth/2), y: corners.lbd.y + Float(updatedHeight/2), z: corners.lbd.z + Float(updatedLength/2))
                                    r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                                    r2d2.position = centerPosition
                                    if let textGeometry1 = text1.geometry as? SCNText {
                                        textGeometry1.string = "W:\(widthIncmStr)cm"
                                        text1.position = SCNVector3(x:edges.e3.x-0.025, y:edges.e3.y + 0.01, z:edges.e3.z)
                                        text1.opacity = 1
                                    }
                                    if let textGeometry2 = text2.geometry as? SCNText {
                                        textGeometry2.string = "H:\(heightIncmStr)cm"
                                        text2.opacity = 1
                                        text2.position = SCNVector3(x:edges.e4.x+0.01, y:edges.e4.y, z:edges.e4.z)
                                    }
                                    
                                    if let textGeometry3 = text3.geometry as? SCNText {
                                        textGeometry3.string = "L:\(lengthIncmStr)cm"
                                        text3.opacity = 1
                                        text3.position = SCNVector3(x:edges.e9.x + 0.01, y:edges.e9.y, z:edges.e9.z)
                                    }
                                }
                                //print("centerPosition: \(centerPosition)")
                                //update Corners
                                setCorners()
                                setSpherePosition()
                                removeAllEdges()
                                setEdges()
                                colorEdgesBlue()
                            
                                
                                //update diagonals
                                if let line2 = currentScene?.drawingNode.childNode(withName: "diagonal2", recursively: false){
                                    line2.removeFromParentNode()
                                }
                                if let line3 = currentScene?.drawingNode.childNode(withName: "diagonal3", recursively: false){
                                    line3.removeFromParentNode()
                                }
                                if let line4 = currentScene?.drawingNode.childNode(withName: "diagonal4", recursively: false){
                                    line4.removeFromParentNode()
                                }
                            
                                let vector2 = SCNVector3(corners.rbd.x - corners.lfh.x, corners.rbd.y - corners.lfh.y, corners.rbd.z - corners.lfh.z)
                                 next_lfh = corners.lfh + SCNVector3(-5*vector2.x,-5*vector2.y,-5*vector2.z)
                                 next_rbd = corners.lfh + SCNVector3(6*vector2.x,6*vector2.y,6*vector2.z)
                                
                                let vector3 = SCNVector3(corners.lfd.x - corners.rbh.x, corners.lfd.y - corners.rbh.y, corners.lfd.z - corners.rbh.z)
                                 next_rbh = corners.rbh + SCNVector3(-5*vector3.x,-5*vector3.y,-5*vector3.z)
                                 next_lfd = corners.rbh + SCNVector3(6*vector3.x,6*vector3.y,6*vector3.z)
                                
                                let vector4 = SCNVector3(corners.rfd.x - corners.lbh.x, corners.rfd.y - corners.lbh.y, corners.rfd.z - corners.lbh.z)
                                 next_lbh = corners.lbh + SCNVector3(-5*vector4.x,-5*vector4.y,-5*vector4.z)
                                 next_rfd = corners.lbh + SCNVector3(6*vector4.x,6*vector4.y,6*vector4.z)

                                //diagonal from lfh to rbd
                                let line2 = lineBetweenNodes(positionA: next_rbd, positionB: next_lfh, inScene: scene)
                                    if line2 != scene.drawingNode.childNode(withName: "diagonal2", recursively: false){
                                    line2.name = "diagonal2"
                                    scene.drawingNode.addChildNode(line2)
                                }
                                //diagonal from lfd to rbh
                                let line3 = lineBetweenNodes(positionA: next_rbh, positionB: next_lfd, inScene: scene)
                                    if line3 != scene.drawingNode.childNode(withName: "diagonal3", recursively: false){
                                    line3.name = "diagonal3"
                                    scene.drawingNode.addChildNode(line3)
                                }
                                //diagonal from rfd to lbh
                                let line4 = lineBetweenNodes(positionA: next_lbh, positionB: next_rfd, inScene: scene)
                                    if line4 != scene.drawingNode.childNode(withName: "diagonal4", recursively: false){
                                    line4.name = "diagonal4"
                                    scene.drawingNode.addChildNode(line4)
                                }
                                else{
                                    if let index = hitTestResult.firstIndex(of: hit) {
                                        hitTestResult.remove(at: index)
                                    }
                                }

                            }
                        }
                    
                        
                    //Project onto diagonal connecting lfd and rbh if one of the corners is selected
                    else if (tapped2 || tapped7){
                        let vecA = CGPoint(x:currentPoint.x - screenCorners.rbh.x, y:currentPoint.y - screenCorners.rbh.y)
                        let scalar3 = dotProduct(vecA: vecA , vecB: dirVector3)  / dotProduct(vecA: dirVector3, vecB: dirVector3)
                        let scaledDirVec = CGPoint(x: dirVector3.x * scalar3, y: dirVector3.y * scalar3)
                        let projectedPoint3 = CGPoint(x: screenCorners.rbh.x + scaledDirVec.x, y: screenCorners.rbh.y + scaledDirVec.y)
                        var hitTestResult = sceneView.hitTest(projectedPoint3, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
                        for hit in hitTestResult{
                            if hit.node == line3{
                                let currentPointInWC = hit.worldCoordinates
                                updatedHeight = (abs(currentPointInWC.y - box.position.y))
                                let scaleFactor = Float(updatedHeight / originalHeight)
                                updatedWidth = originalWidth * (scaleFactor)
                                updatedLength = originalLength * (scaleFactor)
                                
                                let widthIncmStr = String(format: "%.1f",updatedWidth*100)
                                let heightIncmStr = String(format: "%.1f",updatedHeight*100)
                                let lengthIncmStr = String(format: "%.1f",updatedLength*100)

                                if(tapped2){
                                    centerPosition = SCNVector3(x: corners.rbh.x - Float(updatedWidth/2), y: corners.rbh.y - Float(updatedHeight/2), z: corners.rbh.z + Float(updatedLength/2))
                                    r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                                    r2d2.position = centerPosition
                                    if let textGeometry1 = text1.geometry as? SCNText {
                                        textGeometry1.string = "W:\(widthIncmStr)cm"
                                        text1.position = SCNVector3(x:edges.e1.x-0.025, y:edges.e1.y - 0.015, z:edges.e1.z)
                                        text1.opacity = 1
                                    }
                                    if let textGeometry2 = text2.geometry as? SCNText {
                                        textGeometry2.string = "H:\(heightIncmStr)cm"
                                        text2.opacity = 1
                                        text2.position = SCNVector3(x:edges.e2.x - 0.06, y:edges.e2.y, z:edges.e2.z)
                                    }
                                    if let textGeometry3 = text3.geometry as? SCNText {
                                        textGeometry3.string = "L:\(lengthIncmStr)cm"
                                        text3.opacity = 1
                                        text3.position = SCNVector3(x:edges.e5.x - 0.06 , y:edges.e5.y, z:edges.e5.z)
                                    }
                                }
                                else if(tapped7){
                                    centerPosition = SCNVector3(x: corners.lfd.x + Float(updatedWidth/2), y: corners.lfd.y + Float(updatedHeight/2), z: corners.lfd.z - Float(updatedLength/2))
                                    r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                                    r2d2.position = centerPosition
                                    if let textGeometry1 = text1.geometry as? SCNText {
                                        textGeometry1.string = "W:\(widthIncmStr)cm"
                                        text1.position = SCNVector3(x:edges.e8.x-0.025, y:edges.e8.y + 0.015, z:edges.e8.z)
                                        text1.opacity = 1
                                    }
                                    if let textGeometry2 = text2.geometry as? SCNText {
                                        textGeometry2.string = "H:\(heightIncmStr)cm"
                                        text2.opacity = 1
                                        text2.position = SCNVector3(x:edges.e10.x + 0.01, y:edges.e10.y - 0.01, z:edges.e10.z)
                                    }
                                    
                                    if let textGeometry3 = text3.geometry as? SCNText {
                                        textGeometry3.string = "L:\(lengthIncmStr)cm"
                                        text3.opacity = 1
                                        text3.position = SCNVector3(x:edges.e9.x + 0.01, y:edges.e9.y, z:edges.e9.z)
                                    }
                                }
                                
                                //update Corners
                                setCorners()
                                setSpherePosition()
                                removeAllEdges()
                                setEdges()
                                colorEdgesBlue()
                                
                                //update diagonals
                                if let line2 = currentScene?.drawingNode.childNode(withName: "diagonal2", recursively: false){
                                    line2.removeFromParentNode()
                                }
                                if let line1 = currentScene?.drawingNode.childNode(withName: "diagonal1", recursively: false){
                                    line1.removeFromParentNode()
                                }
                                if let line4 = currentScene?.drawingNode.childNode(withName: "diagonal4", recursively: false){
                                    line4.removeFromParentNode()
                                }
                                
                                let vector1 = SCNVector3(corners.lbd.x - corners.rfh.x, corners.lbd.y - corners.rfh.y, corners.lbd.z - corners.rfh.z)
                                 next_rfh = corners.rfh + SCNVector3(-5*vector1.x,-5*vector1.y,-5*vector1.z)
                                 next_lbd = corners.rfh + SCNVector3(6*vector1.x,6*vector1.y,6*vector1.z)
                                
                                let vector2 = SCNVector3(corners.rbd.x - corners.lfh.x, corners.rbd.y - corners.lfh.y, corners.rbd.z - corners.lfh.z)
                                 next_lfh = corners.lfh + SCNVector3(-5*vector2.x,-5*vector2.y,-5*vector2.z)
                                 next_rbd = corners.lfh + SCNVector3(6*vector2.x,6*vector2.y,6*vector2.z)
                                
                                let vector4 = SCNVector3(corners.rfd.x - corners.lbh.x, corners.rfd.y - corners.lbh.y, corners.rfd.z - corners.lbh.z)
                                 next_lbh = corners.lbh + SCNVector3(-5*vector4.x,-5*vector4.y,-5*vector4.z)
                                 next_rfd = corners.lbh + SCNVector3(6*vector4.x,6*vector4.y,6*vector4.z)

                                //diagonal from lfh to rbd
                                let line2 = lineBetweenNodes(positionA: next_rbd, positionB: next_lfh, inScene: scene)
                                    if line2 != scene.drawingNode.childNode(withName: "diagonal2", recursively: false){
                                         line2.name = "diagonal2"
                                         scene.drawingNode.addChildNode(line2)
                                    }
                                //diagonal from lbd to rfh
                                let line1 = lineBetweenNodes(positionA: next_lbd, positionB: next_rfh, inScene: scene)
                                    if line1 != scene.drawingNode.childNode(withName: "diagonal1", recursively: false){
                                        line1.name = "diagonal1"
                                        scene.drawingNode.addChildNode(line1)
                                    }
                                //diagonal from rfd to lbh
                                let line4 = lineBetweenNodes(positionA: next_lbh, positionB: next_rfd, inScene: scene)
                                    if line4 != scene.drawingNode.childNode(withName: "diagonal4", recursively: false){
                                         line4.name = "diagonal4"
                                         scene.drawingNode.addChildNode(line4)
                                    }
                            }
                            else{
                                if let index = hitTestResult.firstIndex(of: hit) {
                                    hitTestResult.remove(at: index)
                                }
                            }
                        }
                    }
                    //Project onto diagonal connecting rbd and lfh if one of the corners is selected
                    else if (tapped3 || tapped6){
                    let vecA = CGPoint(x:currentPoint.x - screenCorners.lfh.x, y:currentPoint.y - screenCorners.lfh.y)
                    let scalar2 = dotProduct(vecA: vecA , vecB: dirVector2)  / dotProduct(vecA: dirVector2, vecB: dirVector2)
                    let scaledDirVec = CGPoint(x: dirVector2.x * scalar2, y: dirVector2.y * scalar2)
                    let projectedPoint2 = CGPoint(x: screenCorners.lfh.x + scaledDirVec.x, y: screenCorners.lfh.y + scaledDirVec.y)
                    var hitTestResult = sceneView.hitTest(projectedPoint2, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
                        for hit in hitTestResult{
                            if hit.node == line2{
                            let currentPointInWC = hit.worldCoordinates
                            updatedHeight = (abs(currentPointInWC.y - box.position.y))
                            let scaleFactor = Float(updatedHeight / originalHeight)
                            updatedWidth = originalWidth * (scaleFactor)
                            updatedLength = originalLength * (scaleFactor)
                                
                            let widthIncmStr = String(format: "%.1f",updatedWidth*100)
                            let heightIncmStr = String(format: "%.1f",updatedHeight*100)
                            let lengthIncmStr = String(format: "%.1f",updatedLength*100)

                            if(tapped3){
                                centerPosition = SCNVector3(x: corners.lfh.x + Float(updatedWidth/2), y: corners.lfh.y - Float(updatedHeight/2), z: corners.lfh.z - Float(updatedLength/2))
                                r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                                r2d2.position = centerPosition
                                if let textGeometry1 = text1.geometry as? SCNText {
                                    textGeometry1.string = "W:\(widthIncmStr)cm"
                                    text1.position = SCNVector3(x:edges.e12.x-0.025, y:edges.e12.y - 0.015, z:edges.e12.z)
                                    text1.opacity = 1
                                }
                                
                                if let textGeometry2 = text2.geometry as? SCNText {
                                    textGeometry2.string = "H:\(heightIncmStr)cm"
                                    text2.opacity = 1
                                    text2.position = SCNVector3(x:edges.e10.x + 0.01, y:edges.e10.y, z:edges.e10.z)
                                }
                                
                                if let textGeometry3 = text3.geometry as? SCNText {
                                    textGeometry3.string = "L:\(lengthIncmStr)cm"
                                    text3.opacity = 1
                                    text3.position = SCNVector3(x:edges.e11.x + 0.01 , y:edges.e11.y, z:edges.e11.z)
                                }
                            }
                            else if(tapped6){
                                centerPosition = SCNVector3(x: corners.rbd.x - Float(updatedWidth/2), y: corners.rbd.y + Float(updatedHeight/2), z: corners.rbd.z + Float(updatedLength/2))
                                r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                                r2d2.position = centerPosition
                                if let textGeometry1 = text1.geometry as? SCNText {
                                    textGeometry1.string = "W:\(widthIncmStr)cm"
                                    text1.position = SCNVector3(x:edges.e3.x-0.025, y:edges.e3.y + 0.01, z:edges.e3.z)
                                    text1.opacity = 1
                                }
                                
                                if let textGeometry2 = text2.geometry as? SCNText {
                                    textGeometry2.string = "H:\(heightIncmStr)cm"
                                    text2.opacity = 1
                                    text2.position = SCNVector3(x:edges.e2.x - 0.06, y:edges.e2.y - 0.01, z:edges.e2.z)
                                }
                                
                                if let textGeometry3 = text3.geometry as? SCNText {
                                    textGeometry3.string = "L:\(lengthIncmStr)cm"
                                    text3.opacity = 1
                                    text3.position = SCNVector3(x:edges.e7.x - 0.06, y:edges.e7.y, z:edges.e7.z)
                                }
                            }
                            
                            //updateCorners
                            setCorners()
                            setSpherePosition()
                            removeAllEdges()
                            setEdges()
                            colorEdgesBlue()

                            if let line1 = currentScene?.drawingNode.childNode(withName: "diagonal1", recursively: false){
                                line1.removeFromParentNode()
                            }
                            if let line3 = currentScene?.drawingNode.childNode(withName: "diagonal3", recursively: false){
                                line3.removeFromParentNode()
                            }
                            if let line4 = currentScene?.drawingNode.childNode(withName: "diagonal4", recursively: false){
                                line4.removeFromParentNode()
                            }
                                
                            let vector1 = SCNVector3(corners.lbd.x - corners.rfh.x, corners.lbd.y - corners.rfh.y, corners.lbd.z - corners.rfh.z)
                             next_rfh = corners.rfh + SCNVector3(-5*vector1.x,-5*vector1.y,-5*vector1.z)
                             next_lbd = corners.rfh + SCNVector3(6*vector1.x,6*vector1.y,6*vector1.z)
                            
                            let vector3 = SCNVector3(corners.lfd.x - corners.rbh.x, corners.lfd.y - corners.rbh.y, corners.lfd.z - corners.rbh.z)
                             next_rbh = corners.rbh + SCNVector3(-5*vector3.x,-5*vector3.y,-5*vector3.z)
                             next_lfd = corners.rbh + SCNVector3(6*vector3.x,6*vector3.y,6*vector3.z)
                            
                            let vector4 = SCNVector3(corners.rfd.x - corners.lbh.x, corners.rfd.y - corners.lbh.y, corners.rfd.z - corners.lbh.z)
                             next_lbh = corners.lbh + SCNVector3(-5*vector4.x,-5*vector4.y,-5*vector4.z)
                             next_rfd = corners.lbh + SCNVector3(6*vector4.x,6*vector4.y,6*vector4.z)

                            //diagonal from lfd to rbh
                            let line3 = lineBetweenNodes(positionA: next_rbh, positionB: next_lfd, inScene: scene)
                                if line3 != scene.drawingNode.childNode(withName: "diagonal3", recursively: false){
                                    line3.name = "diagonal3"
                                    scene.drawingNode.addChildNode(line3)
                                }
                            //diagonal from lbd to rfh
                            let line1 = lineBetweenNodes(positionA: next_lbd, positionB: next_rfh, inScene: scene)
                                if line1 != scene.drawingNode.childNode(withName: "diagonal1", recursively: false){
                                    line1.name = "diagonal1"
                                    scene.drawingNode.addChildNode(line1)
                                }
                            //diagonal from rfd to lbh
                            let line4 = lineBetweenNodes(positionA: next_lbh, positionB: next_rfd, inScene: scene)
                                if line4 != scene.drawingNode.childNode(withName: "diagonal4", recursively: false){
                                    line4.name = "diagonal4"
                                    scene.drawingNode.addChildNode(line4)
                                }
                            }
                            else{
                                if let index = hitTestResult.firstIndex(of: hit) {
                                    hitTestResult.remove(at: index)
                                }
                            }
                        }
                    }
                    //Project onto diagonal connecting rfd and lbh if one of the corners is selected
                    else if (tapped4 || tapped5){
                    let vecA = CGPoint(x:currentPoint.x - screenCorners.lbh.x, y:currentPoint.y - screenCorners.lbh.y)
                    let scalar4 = dotProduct(vecA: vecA , vecB: dirVector4)  / dotProduct(vecA: dirVector4, vecB: dirVector4)
                    let scaledDirVec = CGPoint(x: dirVector4.x * scalar4, y: dirVector4.y * scalar4)
                    let projectedPoint4 = CGPoint(x: screenCorners.lbh.x + scaledDirVec.x, y: screenCorners.lbh.y + scaledDirVec.y)
                    var hitTestResult = sceneView.hitTest(projectedPoint4, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
                        for hit in hitTestResult{
                        //line4.opacity = 0.1
                            if hit.node == line4{
                                let currentPointInWC = hit.worldCoordinates
                                updatedHeight = (abs(currentPointInWC.y - box.position.y))
                                let scaleFactor = Float(updatedHeight / originalHeight)
                                updatedWidth = originalWidth * (scaleFactor)
                                updatedLength = originalLength * (scaleFactor)
                                
                                let widthIncmStr = String(format: "%.1f",updatedWidth*100)
                                let heightIncmStr = String(format: "%.1f",updatedHeight*100)
                                let lengthIncmStr = String(format: "%.1f",updatedLength*100)

                                if(tapped4){
                                    centerPosition = SCNVector3(x: corners.lbh.x + Float(updatedWidth/2), y: corners.lbh.y - Float(updatedHeight/2), z: corners.lbh.z + Float(updatedLength/2))
                                    r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                                    r2d2.position = centerPosition
                                    if let textGeometry1 = text1.geometry as? SCNText {
                                        textGeometry1.string = "W:\(widthIncmStr)cm"
                                        text1.position = SCNVector3(x:edges.e1.x-0.025, y:edges.e1.y - 0.015, z:edges.e1.z)
                                        text1.opacity = 1
                                    }
                                    
                                    if let textGeometry2 = text2.geometry as? SCNText {
                                        textGeometry2.string = "H:\(heightIncmStr)cm"
                                        text2.opacity = 1
                                        text2.position = SCNVector3(x:edges.e4.x  + 0.01 , y:edges.e4.y, z:edges.e4.z)
                                    }
                                    
                                    if let textGeometry3 = text3.geometry as? SCNText {
                                        textGeometry3.string = "L:\(lengthIncmStr)cm"
                                        text3.opacity = 1
                                        text3.position = SCNVector3(x:edges.e11.x + 0.01 , y:edges.e11.y, z:edges.e11.z)
                                    }
                                }
                                else if(tapped5){
                                    centerPosition = SCNVector3(x: corners.rfd.x - Float(updatedWidth/2), y: corners.rfd.y + Float(updatedHeight/2), z: corners.rfd.z - Float(updatedLength/2))
                                    r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                                    r2d2.position = centerPosition
                                    if let textGeometry1 = text1.geometry as? SCNText {
                                        textGeometry1.string = "W:\(widthIncmStr)cm"
                                        text1.position = SCNVector3(x:edges.e8.x-0.025, y:edges.e8.y + 0.015, z:edges.e8.z)
                                        text1.opacity = 1
                                    }
                                    
                                    if let textGeometry2 = text2.geometry as? SCNText {
                                        textGeometry2.string = "H:\(heightIncmStr)cm"
                                        text2.opacity = 1
                                        text2.position = SCNVector3(x:edges.e6.x - 0.06 , y:edges.e6.y - 0.01, z:edges.e6.z)
                                    }
                                    
                                    if let textGeometry3 = text3.geometry as? SCNText {
                                        textGeometry3.string = "L:\(lengthIncmStr)cm"
                                        text3.opacity = 1
                                        text3.position = SCNVector3(x:edges.e7.x - 0.06, y:edges.e7.y, z:edges.e7.z)
                                    }
                                }
                                
                                //update corners
                                setCorners()
                                setSpherePosition()
                                removeAllEdges()
                                setEdges()
                                colorEdgesBlue()
                                
                                //update diagonals
                                if let line1 = currentScene?.drawingNode.childNode(withName: "diagonal1", recursively: false){
                                    line1.removeFromParentNode()
                                }
                                if let line2 = currentScene?.drawingNode.childNode(withName: "diagonal2", recursively: false){
                                    line2.removeFromParentNode()
                                }
                                if let line3 = currentScene?.drawingNode.childNode(withName: "diagonal3", recursively: false){
                                    line3.removeFromParentNode()
                                }
                                
                                let vector1 = SCNVector3(corners.lbd.x - corners.rfh.x, corners.lbd.y - corners.rfh.y, corners.lbd.z - corners.rfh.z)
                                 next_rfh = corners.rfh + SCNVector3(-5*vector1.x,-5*vector1.y,-5*vector1.z)
                                 next_lbd = corners.rfh + SCNVector3(6*vector1.x,6*vector1.y,6*vector1.z)
                                
                                let vector2 = SCNVector3(corners.rbd.x - corners.lfh.x, corners.rbd.y - corners.lfh.y, corners.rbd.z - corners.lfh.z)
                                 next_lfh = corners.lfh + SCNVector3(-5*vector2.x,-5*vector2.y,-5*vector2.z)
                                 next_rbd = corners.lfh + SCNVector3(6*vector2.x,6*vector2.y,6*vector2.z)
                                
                                let vector3 = SCNVector3(corners.lfd.x - corners.rbh.x, corners.lfd.y - corners.rbh.y, corners.lfd.z - corners.rbh.z)
                                 next_rbh = corners.rbh + SCNVector3(-5*vector3.x,-5*vector3.y,-5*vector3.z)
                                 next_lfd = corners.rbh + SCNVector3(6*vector3.x,6*vector3.y,6*vector3.z)
                                
                                //diagonal from lfd to rbh
                                let line3 = lineBetweenNodes(positionA: next_rbh, positionB: next_lfd, inScene: scene)
                                    if line3 != scene.drawingNode.childNode(withName: "diagonal3", recursively: false){
                                        line3.name = "diagonal3"
                                        scene.drawingNode.addChildNode(line3)
                                    }
                                //diagonal from lbd to rfh
                                let line1 = lineBetweenNodes(positionA: next_lbd, positionB: next_rfh, inScene: scene)
                                    if line1 != scene.drawingNode.childNode(withName: "diagonal1", recursively: false){
                                        line1.name = "diagonal1"
                                        scene.drawingNode.addChildNode(line1)
                                    }
                                //diagonal from lfh to rbd
                                let line2 = lineBetweenNodes(positionA: next_rbd, positionB: next_lfh, inScene: scene)
                                    if line2 != scene.drawingNode.childNode(withName: "diagonal2", recursively: false){
                                        line2.name = "diagonal2"
                                        scene.drawingNode.addChildNode(line2)
                                    }
                            }
                            else{
                                 if let index = hitTestResult.firstIndex(of: hit) {
                                     hitTestResult.remove(at: index)
                                 }
                            }
                        }
                    }
                }
            }
        }
        else{
            insideSphere = nil
            if selected == true{
                box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                selected = false
                tapped2 = false
                tapped3 = false
                tapped4 = false
                tapped5 = false
                tapped6 = false
                tapped7 = false
                tapped8 = false
                
                if training{
                    selectedCorner.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
                }
                else{
                    selectedCorner.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                }
                
                self.selectedCorner = SCNNode()
                text1.opacity = 0.01
                text2.opacity = 0.01
                text3.opacity = 0.01
                endTime = Date()
            }
        }
        
        if recStarted && selected{
            if userStudyReps < 6{
                if confirmPressed{
                    
                    elapsedTime = endTime.timeIntervalSince(startTime)
                    
            
                    userStudyReps += 1
                    confirmPressed = false
                    reset()
                }
                if undoPressed{
                    reset()
                }
            }else{
                DispatchQueue.main.async {
                    //self.instructLabel.text = "You finished"
                }
                return
            }
        }
    }
     
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        
        self.currentScene = scene
        self.currentView = view
        
        self.recStarted = false
        self.finished = false
        self.training = true
        
        //define r2d2
        let starwars = SCNScene(named: "art.scnassets/R2D2/r2d2Center.dae")
        let r2d2Node = starwars?.rootNode.childNode(withName: "Merged_Meshes", recursively: true)
        let r2d2 = r2d2Node!
        r2d2.scale = SCNVector3(0.001,0.001,0.001)
        //r2d2.position = SCNVector3(0,0.2,-0.4)
        
        //Define boundingBox
        let boundingBoxCorners = r2d2Node!.boundingBox
        let OriginalMinCorner = boundingBoxCorners.0
        let OriginalMaxCorner = boundingBoxCorners.1
        let minCorner = SCNVector3(x:OriginalMinCorner.x*0.001,y:OriginalMinCorner.y*0.001,z:OriginalMinCorner.z*0.001)
        let maxCorner = SCNVector3(x:OriginalMaxCorner.x*0.001,y:OriginalMaxCorner.y*0.001,z:OriginalMaxCorner.z*0.001)
        
        originalWidth = (maxCorner.x - minCorner.x)
        originalHeight = (maxCorner.z - minCorner.z)
        originalLength = (maxCorner.y - minCorner.y)
        
        self.updatedWidth = originalWidth
        self.updatedHeight = originalHeight
        self.updatedLength = originalLength
        
        let box = SCNBox(width: CGFloat(originalWidth*0.01), height: CGFloat(originalHeight*0.01), length: CGFloat(originalLength*0.01), chamferRadius: 0)
        box.firstMaterial?.isDoubleSided = true
        let boundingBox = SCNNode(geometry: box)
        
        if boundingBox != scene.drawingNode.childNode(withName: "currentBoundingBox", recursively: false){
            boundingBox.position = SCNVector3(0,0,-0.3)
            centerPosition = boundingBox.position
            boundingBox.name = "currentBoundingBox"
            boundingBox.opacity = 0.01
            scene.drawingNode.addChildNode(boundingBox)
            }
        else{
            boundingBox.position = SCNVector3(0,0,-0.3)
            
        }
        
        setCorners()
        setEdges()
        //print("corners: \(corners)")
        
        //Visualize corners for Selection
        let sphere1 = SCNNode()
        let sphere2 = SCNNode()
        let sphere3 = SCNNode()
        let sphere4 = SCNNode()
        let sphere5 = SCNNode()
        let sphere6 = SCNNode()
        let sphere7 = SCNNode()
        let sphere8 = SCNNode()
        
        if sphere1 != scene.drawingNode.childNode(withName: "lbdCorner", recursively: false){
            sphere1.position = corners.lbd
            sphere1.geometry = SCNSphere(radius: 0.008)
            sphere1.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
            sphere1.name = "lbdCorner"
            scene.drawingNode.addChildNode(sphere1)
            }
        else{
            sphere1.position = corners.lbd
        }
        
        if sphere2 != scene.drawingNode.childNode(withName: "lfdCorner", recursively: false){
            sphere2.position = corners.lfd
            sphere2.geometry = SCNSphere(radius: 0.01)
            sphere2.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
            sphere2.name = "lfdCorner"
            scene.drawingNode.addChildNode(sphere2)
            }
        else{
            sphere2.position = corners.lfd
        }
        
        if sphere3 != scene.drawingNode.childNode(withName: "rbdCorner", recursively: false){
            sphere3.position = corners.rbd
            sphere3.geometry = SCNSphere(radius: 0.01)
            sphere3.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
            sphere3.name = "rbdCorner"
            scene.drawingNode.addChildNode(sphere3)
            }
        else{
            sphere3.position = corners.rbd
        }
        
        if sphere4 != scene.drawingNode.childNode(withName: "rfdCorner", recursively: false){
            sphere4.position = corners.rfd
            sphere4.geometry = SCNSphere(radius: 0.01)
            sphere4.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
            sphere4.name = "rfdCorner"
            scene.drawingNode.addChildNode(sphere4)
            }
        else{
            sphere4.position = corners.rfd
        }
        
        if sphere5 != scene.drawingNode.childNode(withName: "lbhCorner", recursively: false){
            sphere5.position = corners.lbh
            sphere5.geometry = SCNSphere(radius: 0.01)
            sphere5.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
            sphere5.name = "lbhCorner"
            scene.drawingNode.addChildNode(sphere5)
            }
        else{
            sphere5.position = corners.lbh
        }
        
        if sphere6 != scene.drawingNode.childNode(withName: "lfhCorner", recursively: false){
            sphere6.position = corners.lfh
            sphere6.geometry = SCNSphere(radius: 0.01)
            sphere6.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
            sphere6.name = "lfhCorner"
            scene.drawingNode.addChildNode(sphere6)
            }
        else{
            sphere6.position = corners.lfh
        }
        
        if sphere7 != scene.drawingNode.childNode(withName: "rbhCorner", recursively: false){
            sphere7.position = corners.rbh
            sphere7.geometry = SCNSphere(radius: 0.01)
            sphere7.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
            sphere7.name = "rbhCorner"
            scene.drawingNode.addChildNode(sphere7)
            }
        else{
            sphere7.position = corners.rbh
        }
        
        if sphere8 != scene.drawingNode.childNode(withName: "rfhCorner", recursively: false){
            sphere8.position = corners.rfh
            sphere8.geometry = SCNSphere(radius: 0.01)
            sphere8.geometry?.firstMaterial?.diffuse.contents = UIColor.systemOrange
            sphere8.name = "rfhCorner"
            scene.drawingNode.addChildNode(sphere8)
            }
        else{
            sphere8.position = corners.rfh
        }
        
        //create Object to scale
       if r2d2 != scene.drawingNode.childNode(withName: "currentr2d2", recursively: false){
           //r2d2.position = SCNVector3(-0.05+Float(width/2),-0.05,-0.3+Float(length/2))
           r2d2.position = centerPosition
           r2d2.name = "currentr2d2"
           //r2d2.pivot = SCNMatrix4MakeTranslation(-Float(width/2),0,-Float(length/2))
           scene.drawingNode.addChildNode(r2d2)
           r2d2.opacity = 1.0
           
       }
       else{
           r2d2.position = centerPosition
       }
        
        //define initial diagonals
        let vector1 = SCNVector3(corners.lbd.x - corners.rfh.x, corners.lbd.y - corners.rfh.y, corners.lbd.z - corners.rfh.z)
         next_rfh = corners.rfh + SCNVector3(-5*vector1.x,-5*vector1.y,-5*vector1.z)
         next_lbd = corners.rfh + SCNVector3(6*vector1.x,6*vector1.y,6*vector1.z)
        
        let vector2 = SCNVector3(corners.rbd.x - corners.lfh.x, corners.rbd.y - corners.lfh.y, corners.rbd.z - corners.lfh.z)
         next_lfh = corners.lfh + SCNVector3(-5*vector2.x,-5*vector2.y,-5*vector2.z)
         next_rbd = corners.lfh + SCNVector3(6*vector2.x,6*vector2.y,6*vector2.z)
        
        let vector3 = SCNVector3(corners.lfd.x - corners.rbh.x, corners.lfd.y - corners.rbh.y, corners.lfd.z - corners.rbh.z)
         next_rbh = corners.rbh + SCNVector3(-5*vector3.x,-5*vector3.y,-5*vector3.z)
         next_lfd = corners.rbh + SCNVector3(6*vector3.x,6*vector3.y,6*vector3.z)
        
        let vector4 = SCNVector3(corners.rfd.x - corners.lbh.x, corners.rfd.y - corners.lbh.y, corners.rfd.z - corners.lbh.z)
         next_lbh = corners.lbh + SCNVector3(-5*vector4.x,-5*vector4.y,-5*vector4.z)
         next_rfd = corners.lbh + SCNVector3(6*vector4.x,6*vector4.y,6*vector4.z)
        
        //diagonal from lbd to rfh
        let line1 = lineBetweenNodes(positionA: next_lbd, positionB: next_rfh, inScene: scene)
                //starwars?.rootNode.addChildNode(line)
                if line1 != scene.drawingNode.childNode(withName: "diagonal1", recursively: false){
                    line1.name = "diagonal1"
                    scene.drawingNode.addChildNode(line1)
                }
        //diagonal from lfh to rbd
        let line2 = lineBetweenNodes(positionA: next_rbd, positionB: next_lfh, inScene: scene)
                //starwars?.rootNode.addChildNode(line)
                if line2 != scene.drawingNode.childNode(withName: "diagonal2", recursively: false){
                    line2.name = "diagonal2"
                    scene.drawingNode.addChildNode(line2)
                }
        //diagonal from lfd to rbh
        let line3 = lineBetweenNodes(positionA: next_rbh, positionB: next_lfd, inScene: scene)
                //starwars?.rootNode.addChildNode(line)
                if line3 != scene.drawingNode.childNode(withName: "diagonal3", recursively: false){
                    line3.name = "diagonal3"
                    scene.drawingNode.addChildNode(line3)
                }
       //diagonal from rfd to lbh
        let line4 = lineBetweenNodes(positionA: next_lbh, positionB: next_rfd, inScene: scene)
                //starwars?.rootNode.addChildNode(line)
                if line4 != scene.drawingNode.childNode(withName: "diagonal4", recursively: false){
                    line4.name = "diagonal4"
                    scene.drawingNode.addChildNode(line4)
                }
        
        //show current width, length, height of edges incident to the selected corner
        let displayedWidth = SCNText(string: "", extrusionDepth: 0.2)
        //displayedWidth.font = UIFont (name: "Arial", size: 3)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        displayedWidth.materials = [material]
        let widthString = SCNNode(geometry: displayedWidth)
        
        if widthString != scene.drawingNode.childNode(withName: "widthString", recursively: false){
            widthString.position = SCNVector3(x:edges.e1.x, y:edges.e1.y + 0.05, z:edges.e1.z)
            widthString.name = "widthString"
            widthString.scale = SCNVector3(x:0.001, y:0.001, z:0.001)
            scene.drawingNode.addChildNode(widthString)
        }
        else{
            widthString.position = SCNVector3(x:edges.e1.x, y:edges.e1.y + 0.05, z:edges.e1.z)
        }
        
        let displayedHeight = SCNText(string: "", extrusionDepth: 0.2)
        displayedHeight.materials = [material]
        let heightString = SCNNode(geometry: displayedHeight)

        if heightString != scene.drawingNode.childNode(withName: "heightString", recursively: false){
            heightString.position = SCNVector3(x:edges.e4.x  + 0.1 , y:edges.e4.y, z:edges.e4.z)
            heightString.name = "heightString"
            heightString.scale = SCNVector3(x:0.001, y:0.001, z:0.001)
            scene.drawingNode.addChildNode(heightString)
        }
        else{
            heightString.position = SCNVector3(x:edges.e4.x + 0.1, y:edges.e4.y, z:edges.e4.z)
        }
        
        let displayedLength = SCNText(string: "", extrusionDepth: 0.2)
        displayedLength.materials = [material]
        let lengthString = SCNNode(geometry: displayedLength)
        
        if lengthString != scene.drawingNode.childNode(withName: "lengthString", recursively: false){
            lengthString.position = SCNVector3(x:edges.e11.x + 0.1 , y:edges.e11.y, z:edges.e11.z)
            lengthString.name = "lengthString"
            lengthString.scale = SCNVector3(x:0.001, y:0.001, z:0.001)
            scene.drawingNode.addChildNode(lengthString)
        }
        else{
            lengthString.position = SCNVector3(x:edges.e5.x + 0.1 , y:edges.e5.y, z:edges.e5.z)
        }
        
    }
    
    
    override func deactivatePlugin() {
        if let boundingBox = currentScene?.drawingNode.childNode(withName: "currentBoundingBox", recursively: false){
            boundingBox.removeFromParentNode()
        }
        if let sphere1 = currentScene?.drawingNode.childNode(withName: "lbdCorner", recursively: false){
            sphere1.removeFromParentNode()
        }
        if let sphere2 = currentScene?.drawingNode.childNode(withName: "lfdCorner", recursively: false){
            sphere2.removeFromParentNode()
        }
        if let sphere3 = currentScene?.drawingNode.childNode(withName: "rbdCorner", recursively: false){
            sphere3.removeFromParentNode()
        }
        if let sphere4 = currentScene?.drawingNode.childNode(withName: "rfdCorner", recursively: false){
            sphere4.removeFromParentNode()
        }
        if let sphere5 = currentScene?.drawingNode.childNode(withName: "lbhCorner", recursively: false){
            sphere5.removeFromParentNode()
        }
        if let sphere6 = currentScene?.drawingNode.childNode(withName: "lfhCorner", recursively: false){
            sphere6.removeFromParentNode()
        }
        if let sphere7 = currentScene?.drawingNode.childNode(withName: "rbhCorner", recursively: false){
            sphere7.removeFromParentNode()
        }
        if let sphere8 = currentScene?.drawingNode.childNode(withName: "rfhCorner", recursively: false){
            sphere8.removeFromParentNode()
        }
        if let line1 = currentScene?.drawingNode.childNode(withName: "diagonal1", recursively: false){
            line1.removeFromParentNode()
        }
        if let line2 = currentScene?.drawingNode.childNode(withName: "diagonal2", recursively: false){
            line2.removeFromParentNode()
        }
        if let line3 = currentScene?.drawingNode.childNode(withName: "diagonal3", recursively: false){
            line3.removeFromParentNode()
        }
        if let line4 = currentScene?.drawingNode.childNode(withName: "diagonal4", recursively: false){
            line4.removeFromParentNode()
        }
        if let edge1 = currentScene?.drawingNode.childNode(withName: "edge1", recursively: false){
            edge1.removeFromParentNode()
        }
        if let edge2 = currentScene?.drawingNode.childNode(withName: "edge2", recursively: false){
            edge2.removeFromParentNode()
        }
        if let edge3 = currentScene?.drawingNode.childNode(withName: "edge3", recursively: false){
            edge3.removeFromParentNode()
        }
        if let edge4 = currentScene?.drawingNode.childNode(withName: "edge4", recursively: false){
            edge4.removeFromParentNode()
        }
        if let edge5 = currentScene?.drawingNode.childNode(withName: "edge5", recursively: false){
            edge5.removeFromParentNode()
        }
        if let edge6 = currentScene?.drawingNode.childNode(withName: "edge6", recursively: false){
            edge6.removeFromParentNode()
        }
        if let edge7 = currentScene?.drawingNode.childNode(withName: "edge7", recursively: false){
            edge7.removeFromParentNode()
        }
        if let edge8 = currentScene?.drawingNode.childNode(withName: "edge8", recursively: false){
            edge8.removeFromParentNode()
        }
        if let edge9 = currentScene?.drawingNode.childNode(withName: "edge9", recursively: false){
            edge9.removeFromParentNode()
        }
        if let edge10 = currentScene?.drawingNode.childNode(withName: "edge10", recursively: false){
            edge10.removeFromParentNode()
        }
        if let edge11 = currentScene?.drawingNode.childNode(withName: "edge11", recursively: false){
            edge11.removeFromParentNode()
        }
        if let edge12 = currentScene?.drawingNode.childNode(withName: "edge12", recursively: false){
            edge12.removeFromParentNode()
        }
        if let r2d2 = currentScene?.drawingNode.childNode(withName: "currentr2d2", recursively: false){
            r2d2.removeFromParentNode()
        }
        if let text1 = currentScene?.drawingNode.childNode(withName: "widthString", recursively: false){
            text1.removeFromParentNode()
         }
        if let text2 = currentScene?.drawingNode.childNode(withName: "heightString", recursively: false){
            text2.removeFromParentNode()
         }
        if let text3 = currentScene?.drawingNode.childNode(withName: "lengthString", recursively: false){
            text3.removeFromParentNode()
         }
        self.currentScene = nil

        self.currentView = nil
    }
}



