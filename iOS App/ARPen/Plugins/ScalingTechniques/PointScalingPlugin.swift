//
//  PointScalingPlugin.swift
//  ARPen
//
//  Created by Farhadiba Mohammed on 09.08.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

//include the UserStudyRecordPluginProtocol to demo recording of user study data
class PointScalingPlugin: Plugin {

    private var recStarted :Bool = false
    private var finished :Bool = false
    private var training :Bool = false
    
    var confirmPressed : Bool = false
    var undoPressed : Bool = false
    
    //Gesture Recognizer
    var panGesture: UIPanGestureRecognizer?
    var tapGesture : UITapGestureRecognizer?
    var currentPoint = CGPoint()
    var scaleFactor : Float = 0

    //Variables for bounding Box updates
    var centerPosition = SCNVector3()
    var updatedWidth : Float = 0
    var updatedHeight : Float = 0
    var updatedLength : Float = 0
    //l = left, r = right, b = back, f = front, d = down, h = high
    var corners : (lbd : SCNVector3, lfd : SCNVector3, rbd : SCNVector3, rfd : SCNVector3, lbh : SCNVector3, lfh : SCNVector3, rbh : SCNVector3, rfh : SCNVector3) = (SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0))
    
    var screenCorners : (lbd : CGPoint, lfd : CGPoint, rbd : CGPoint, rfd : CGPoint, lbh : CGPoint, lfh : CGPoint, rbh : CGPoint, rfh : CGPoint) = (CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0))
    
    var edges : (e1 : SCNVector3, e2 : SCNVector3, e3 : SCNVector3, e4 : SCNVector3, e5 : SCNVector3, e6 : SCNVector3, e7 : SCNVector3, e8 : SCNVector3, e9 : SCNVector3, e10 : SCNVector3, e11 : SCNVector3, e12 : SCNVector3, e13 : SCNVector3) = (SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0), SCNVector3Make(0, 0, 0), SCNVector3Make(0, 0, 0), SCNVector3Make(0, 0, 0), SCNVector3Make(0, 0, 0),  SCNVector3Make(0, 0, 0))

    //Variables to ensure only one Corner an be selected at a time
    var selectedEdge = SCNNode()
    var selected : Bool = false
    var tapped1 : Bool = false
    var tapped2 : Bool = false
    var tapped3 : Bool = false
    var tapped4 : Bool = false
    var tapped5 : Bool = false
    var tapped6 : Bool = false
    var tapped7 : Bool = false
    var tapped8 : Bool = false
    var tapped9 : Bool = false
    var tapped10 : Bool = false
    var tapped11: Bool = false
    var tapped12: Bool = false
    
    var pressCounter = 0
    var firstPoint = SCNVector3()
    var secondPoint = SCNVector3()
    var length = Float()
    
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
    
        self.pluginIdentifier = "PointScaling"
        self.needsBluetoothARPen = false
        self.pluginGroupName = "Scaling"
        
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
        
            colorEdgesBlue()
            
            updatedWidth = originalWidth
            updatedHeight = originalHeight
            updatedLength = originalLength
            
            box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
            box.position = SCNVector3(0,0.2,0)
            centerPosition = box.position
            box.scale = SCNVector3(originalScale.x, originalScale.y, originalScale.z)
            r2d2.scale = SCNVector3(0.001,0.001,0.001)
            r2d2.position = box.position
            
            setCorners()
            setSpherePosition()
            removeAllEdges()
            setEdges()
            
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
        edge1.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
        edge2.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge2.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
        edge3.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge3.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
        edge4.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge4.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
        edge5.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge5.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
        edge6.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge6.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
        edge7.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge7.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
        edge8.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge8.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
        edge9.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge9.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
        edge10.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge10.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
        edge11.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge11.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
        edge12.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        edge12.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
        
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
    
    //computes the edges
    func lineBetweenNodes(positionA: SCNVector3, positionB: SCNVector3, inScene: SCNScene) -> SCNNode {
        let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        let midPosition = SCNVector3 (x:(positionA.x + positionB.x) / 2, y:(positionA.y + positionB.y) / 2, z:(positionA.z + positionB.z) / 2)

        let lineGeometry = SCNCylinder()
        lineGeometry.radius = 0.0015
        lineGeometry.height = CGFloat(distance)
        lineGeometry.radialSegmentCount = 5
        lineGeometry.firstMaterial!.diffuse.contents = UIColor.systemOrange

        let lineNode = SCNNode(geometry: lineGeometry)
        lineNode.opacity = 0.6
        lineNode.position = midPosition
        lineNode.look (at: positionB, up: inScene.rootNode.worldUp, localFront: lineNode.worldUp)
        return lineNode
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        guard let scene = self.currentScene else {return}
        guard let sceneView = self.currentView else { return }
        guard let box = scene.drawingNode.childNode(withName: "currentBoundingBox", recursively: false) else{
         print("not found")
         return
        }
        guard let r2d2 = scene.drawingNode.childNode(withName: "currentr2d2", recursively: false) else{
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
        guard let text1 = scene.drawingNode.childNode(withName: "selectedEdgeScale", recursively: false) else{
          print("not found")
          return
         }
        guard let text2 = scene.drawingNode.childNode(withName: "customScale", recursively: false) else{
          print("not found")
          return
         }
        let pressed = buttons[Button.Button1]!
        let pressed2 = buttons[Button.Button2]!
        let pressed3 = buttons[Button.Button3]!
        
        let widthIncmStr = String(format: "%.1f",updatedWidth*100)
        let heightIncmStr = String(format: "%.1f",updatedHeight*100)
        let lengthIncmStr = String(format: "%.1f",updatedLength*100)
        let valueIncmStr = String(format: "%.1f",length*100)
        
        //first button press selects corner
        if pressCounter == 0{
            if pressed{
                let projectedPenTip = CGPoint(x: Double(sceneView.projectPoint(scene.pencilPoint.position).x), y: Double(sceneView.projectPoint(scene.pencilPoint.position).y))
                var hitResults = sceneView.hitTest(projectedPenTip, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
        
                //Selecting a corner will select the box
                for hit in hitResults{
                    if !selected{
                        //edge between lfd to rfd
                        if hit.node == edge1 {
                            selected = true
                            tapped1 = true
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selectedEdge = edge1
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e1.x-0.025, y:edges.e1.y - 0.015, z:edges.e1.z)
                                text1.opacity = 1
                            }
                        }
                        //edge between lfd to lfh
                        else if hit.node == edge2{
                            selected = true
                            tapped2 = true
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selectedEdge = edge2
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "H:\(heightIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e2.x - 0.06, y:edges.e2.y, z:edges.e2.z)
                            }
                        }
                        //edge between lfh to rfh
                        else if hit.node == edge3{
                            selected = true
                            tapped3 = true
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selectedEdge = edge3
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e3.x-0.025, y:edges.e3.y + 0.01, z:edges.e3.z)
                                text1.opacity = 1
                            }
                        }
                        //edge between rfh to rfd
                        else if hit.node == edge4{
                            selected = true
                            tapped4 = true
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selectedEdge = edge4
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "H:\(heightIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e4.x+0.01, y:edges.e4.y, z:edges.e4.z)
                            }
                        }
                        //edge between lfd to lbd
                        else if hit.node == edge5{
                            selected = true
                            tapped5 = true
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selectedEdge = edge5
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "L:\(lengthIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e5.x - 0.06 , y:edges.e5.y, z:edges.e5.z)
                            }
                        }
                        //edge between lbd to lbh
                        else if hit.node == edge6{
                            selected = true
                            tapped6 = true
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selectedEdge = edge6
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "H:\(heightIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e6.x - 0.06, y:edges.e6.y, z:edges.e6.z)
                            }
                        }
                        //edge between lbh to lfh
                        else if hit.node == edge7{
                            selected = true
                            tapped7 = true
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selectedEdge = edge7
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "L:\(lengthIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e7.x - 0.06, y:edges.e7.y, z:edges.e7.z)
                            }
                        }
                        //edge between lbh to rbh
                        else if hit.node == edge8{
                            selected = true
                            tapped8 = true
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selectedEdge = edge8
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e8.x-0.025, y:edges.e8.y + 0.015, z:edges.e8.z)
                                text1.opacity = 1
                            }
                        }
                        //edge between rbh to rfh
                        else if hit.node == edge9{
                            selected = true
                            tapped9 = true
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selectedEdge = edge9
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "L:\(lengthIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e9.x + 0.01, y:edges.e9.y, z:edges.e9.z)
                            }
                        }
                        //edge between rbh to rbd
                        else if hit.node == edge10{
                            selected = true
                            tapped10 = true
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selectedEdge = edge10
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "H:\(heightIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e10.x + 0.01, y:edges.e10.y - 0.01, z:edges.e10.z)
                            }
                        }
                        //edge between rfd to rbd
                        else if hit.node == edge11{
                            selected = true
                            tapped11 = true
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selectedEdge = edge11
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "L:\(lengthIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e11.x + 0.01 , y:edges.e11.y, z:edges.e11.z)
                            }
                        }
                        //edge between lbd to rbd
                        else if hit.node == edge12{
                            selected = true
                            tapped12 = true
                            if selectionCounter == 0{
                                startTime = Date()
                            }
                            selectedEdge = edge12
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e12.x - 0.025 , y:edges.e12.y - 0.015, z:edges.e12.z)
                                text1.opacity = 1
                            }
                        }
                        //only select the corners
                        else{
                            if let index = hitResults.firstIndex(of: hit) {
                                hitResults.remove(at: index)
                            }
                        }
                    }
                }
            }
            //Need to release button to complete selection, to enable a deselection through button press
            if !pressed && selected{
                pressCounter += 1
            }
        }
        if pressCounter > 0{
            let projectedPenTip = CGPoint(x: Double(sceneView.projectPoint(scene.pencilPoint.position).x), y: Double(sceneView.projectPoint(scene.pencilPoint.position).y))
            var hitResults = sceneView.hitTest(projectedPenTip, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
            
            if pressed3{
                for hit in hitResults{
                    // Deselection of Corner
                    //edge between lfd to rfd
                    if hit.node == selectedEdge{
                        selected = false
                        tapped1 = false
                        tapped2 = true
                        tapped3 = false
                        tapped4 = false
                        tapped5 = false
                        tapped6 = false
                        tapped7 = false
                        tapped8 = false
                        tapped9 = false
                        tapped10 = false
                        tapped11 = false
                        tapped12 = false
                        selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                        text1.opacity = 0.01
                        endTime = Date()
                    }
                    //only select the corners
                    else{
                        if let index = hitResults.firstIndex(of: hit) {
                            hitResults.remove(at: index)
                        }
                    }
                }
            }
            //switch to other edge
            if pressed{
                for hit in hitResults{
                   if hit.node != selectedEdge{
                        //Change selected Edge
                        //edge between lfd to rfd
                        if hit.node == edge1 {
                            tapped1 = true
                            tapped2 = false
                            tapped3 = false
                            tapped4 = false
                            tapped5 = false
                            tapped6 = false
                            tapped7 = false
                            tapped8 = false
                            tapped9 = false
                            tapped10 = false
                            tapped11 = false
                            tapped12 = false
                            pressCounter = 0
                            
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                            
                            selectedEdge = edge1
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e1.x-0.025, y:edges.e1.y - 0.015, z:edges.e1.z)
                                text1.opacity = 1
                            }
                        }
                        //edge between lfd to lfh
                        else if hit.node == edge2{
                            tapped1 = false
                            tapped2 = true
                            tapped3 = false
                            tapped4 = false
                            tapped5 = false
                            tapped6 = false
                            tapped7 = false
                            tapped8 = false
                            tapped9 = false
                            tapped10 = false
                            tapped11 = false
                            tapped12 = false
                            pressCounter = 0
                            
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                            selectedEdge = edge2
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "H:\(heightIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e2.x - 0.06, y:edges.e2.y, z:edges.e2.z)
                            }
                        }
                        //edge between lfh to rfh
                        else if hit.node == edge3{
                            tapped1 = false
                            tapped2 = false
                            tapped3 = true
                            tapped4 = false
                            tapped5 = false
                            tapped6 = false
                            tapped7 = false
                            tapped8 = false
                            tapped9 = false
                            tapped10 = false
                            tapped11 = false
                            tapped12 = false
                            pressCounter = 0
                            
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                            hit.node.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                            selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                            selectedEdge.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                            selectedEdge = edge3
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e3.x-0.025, y:edges.e3.y + 0.01, z:edges.e3.z)
                                text1.opacity = 1
                            }
                        }
                        //edge between rfh to rfd
                        else if hit.node == edge4{
                            tapped1 = false
                            tapped2 = false
                            tapped3 = false
                            tapped4 = true
                            tapped5 = false
                            tapped6 = false
                            tapped7 = false
                            tapped8 = false
                            tapped9 = false
                            tapped10 = false
                            tapped11 = false
                            tapped12 = false
                            pressCounter = 0
                            
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                            selectedEdge = edge4
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "H:\(heightIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e4.x+0.01, y:edges.e4.y, z:edges.e4.z)
                            }
                        }
                        //edge between lfd to lbd
                        else if hit.node == edge5{
                            tapped1 = false
                            tapped2 = false
                            tapped3 = false
                            tapped4 = false
                            tapped5 = true
                            tapped6 = false
                            tapped7 = false
                            tapped8 = false
                            tapped9 = false
                            tapped10 = false
                            tapped11 = false
                            tapped12 = false
                            pressCounter = 0
                            
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                            selectedEdge = edge5
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "L:\(lengthIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e5.x - 0.06 , y:edges.e5.y, z:edges.e5.z)
                            }
                        }
                        //edge between lbd to lbh
                        else if hit.node == edge6{
                            tapped1 = false
                            tapped2 = false
                            tapped3 = false
                            tapped4 = false
                            tapped5 = false
                            tapped6 = true
                            tapped7 = false
                            tapped8 = false
                            tapped9 = false
                            tapped10 = false
                            tapped11 = false
                            tapped12 = false
                            pressCounter = 0
                            
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                            selectedEdge = edge6
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "H:\(heightIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e6.x - 0.06, y:edges.e6.y, z:edges.e6.z)
                            }
                        }
                        //edge between lbh to lfh
                        else if hit.node == edge7{
                            tapped1 = false
                            tapped2 = false
                            tapped3 = false
                            tapped4 = false
                            tapped5 = false
                            tapped6 = false
                            tapped7 = true
                            tapped8 = false
                            tapped9 = false
                            tapped10 = false
                            tapped11 = false
                            tapped12 = false
                            pressCounter = 0
                            
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                            selectedEdge = edge7
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "L:\(lengthIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e7.x - 0.06, y:edges.e7.y, z:edges.e7.z)
                            }
                        }
                        //edge between lbh to rbh
                        else if hit.node == edge8{
                            tapped1 = false
                            tapped2 = false
                            tapped3 = false
                            tapped4 = false
                            tapped5 = false
                            tapped6 = false
                            tapped7 = false
                            tapped8 = true
                            tapped9 = false
                            tapped10 = false
                            tapped11 = false
                            tapped12 = false
                            pressCounter = 0
                            
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                            selectedEdge = edge8
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e8.x-0.025, y:edges.e8.y + 0.015, z:edges.e8.z)
                                text1.opacity = 1
                            }
                        }
                        //edge between rbh to rfh
                        else if hit.node == edge9{
                            tapped1 = false
                            tapped2 = false
                            tapped3 = false
                            tapped4 = false
                            tapped5 = false
                            tapped6 = false
                            tapped7 = false
                            tapped8 = false
                            tapped9 = true
                            tapped10 = false
                            tapped11 = false
                            tapped12 = false
                            pressCounter = 0
                            
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                            selectedEdge = edge9
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "L:\(lengthIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e9.x + 0.01, y:edges.e9.y, z:edges.e9.z)
                            }
                        }
                        //edge between rbh to rbd
                        else if hit.node == edge10{
                            tapped1 = false
                            tapped2 = false
                            tapped3 = false
                            tapped4 = false
                            tapped5 = false
                            tapped6 = false
                            tapped7 = false
                            tapped8 = false
                            tapped9 = false
                            tapped10 = true
                            tapped11 = false
                            tapped12 = false
                            pressCounter = 0
                            
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                            selectedEdge = edge10
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "H:\(heightIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e10.x + 0.01, y:edges.e10.y, z:edges.e10.z)
                            }
                        }
                        //edge between rfd to rbd
                        else if hit.node == edge11{
                            tapped1 = false
                            tapped2 = false
                            tapped3 = false
                            tapped4 = false
                            tapped5 = false
                            tapped6 = false
                            tapped7 = false
                            tapped8 = false
                            tapped9 = false
                            tapped10 = false
                            tapped11 = true
                            tapped12 = false
                            pressCounter = 0
                            
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                            selectedEdge = edge11
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "L:\(lengthIncmStr)cm"
                                text1.opacity = 1
                                text1.position = SCNVector3(x:edges.e11.x + 0.01 , y:edges.e11.y, z:edges.e11.z)
                            }
                        }
                        //edge between lbd to rbd
                        else if hit.node == edge12{
                            tapped1 = false
                            tapped2 = false
                            tapped3 = false
                            tapped4 = false
                            tapped5 = false
                            tapped6 = false
                            tapped7 = false
                            tapped8 = false
                            tapped9 = false
                            tapped10 = false
                            tapped11 = false
                            tapped12 = true
                            pressCounter = 0
                            
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                            selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                            selectedEdge = edge12
                            if let textGeometry1 = text1.geometry as? SCNText {
                                textGeometry1.string = "W:\(widthIncmStr)cm"
                                text1.position = SCNVector3(x:edges.e12.x - 0.025 , y:edges.e12.y - 0.015, z:edges.e12.z)
                                text1.opacity = 1
                            }
                        }
                    }
                    //only select the corners
                    else{
                        if let index = hitResults.firstIndex(of: hit) {
                            hitResults.remove(at: index)
                        }
                    }
                }
            }
            
            //Need to release button to complete deselection
            if !pressed3 && !selected{
                pressCounter = 0
            }
            
            if pressed2{
                //only first button press determines new corner position
                if pressCounter == 1 {
                    firstPoint = scene.pencilPoint.position
//                    print("firstPoint: \(firstPoint)")
                    pressCounter = 2
                    //visualize firstPoint
                    let marker1 = SCNNode()
                    if marker1 != scene.drawingNode.childNode(withName: "firstPointMarker", recursively: false){
                        marker1.position = firstPoint
                        marker1.geometry = SCNSphere(radius: 0.004)
                        marker1.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                        marker1.name = "firstPointMarker"
                        scene.drawingNode.addChildNode(marker1)
                    }
                    else{
                        marker1.position = firstPoint
                    }
                    //visualize fsecondPoint
                    let marker2 = SCNNode()
                    if marker2 != scene.drawingNode.childNode(withName: "secondPointMarker", recursively: false){
                        marker2.position = firstPoint
                        marker2.geometry = SCNSphere(radius: 0.004)
                        marker2.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                        marker2.name = "secondPointMarker"
                        scene.drawingNode.addChildNode(marker2)
                    }
                    else{
                        marker2.position = firstPoint
                    }
                }
            
                if let line = currentScene?.drawingNode.childNode(withName: "line", recursively: false){
                    line.removeFromParentNode()
                }
                
                if pressCounter == 2{
                    // Determine scale
                    let vector = SCNVector3(secondPoint.x - firstPoint.x, secondPoint.y - firstPoint.y, secondPoint.z - firstPoint.z)
                    self.length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
//                    print ("length: \(length)")
                    
                    secondPoint = scene.pencilPoint.position
                    if let marker2 = currentScene?.drawingNode.childNode(withName: "secondPointMarker", recursively: false){
                        marker2.position = secondPoint
                    }
                    
                    let line = lineBetweenNodes(positionA: firstPoint, positionB: secondPoint, inScene: scene)
                    if line != scene.drawingNode.childNode(withName: "line", recursively: false){
                        line.name = "line"
                        self.edges.e13 = SCNVector3 (x:(firstPoint.x + secondPoint.x) / 2, y:(firstPoint.y + secondPoint.y) / 2, z:(firstPoint.z + secondPoint.z) / 2)
                        line.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                        scene.drawingNode.addChildNode(line)
                    }
                    
                    if let textGeometry2 = text2.geometry as? SCNText {
                        textGeometry2.string = "\(valueIncmStr)cm"
                        text2.position = SCNVector3(x:edges.e13.x - 0.025 , y:edges.e13.y + 0.015, z:edges.e13.z)
                        text2.opacity = 1
                    }
                }
            }
            
            if !pressed2 && pressCounter == 2{
//                print("SecondPoint: \(secondPoint)")
//                print("updatedWidth: \(updatedWidth)")
//                print("updatedHeight: \(updatedHeight)")
//                print("updatedLength: \(updatedLength)")
                if let marker1 = currentScene?.drawingNode.childNode(withName: "firstPointMarker", recursively: false){
                    marker1.removeFromParentNode()
                }
                if let marker2 = currentScene?.drawingNode.childNode(withName: "secondPointMarker", recursively: false){
                    marker2.removeFromParentNode()
                }
                if let line = currentScene?.drawingNode.childNode(withName: "line", recursively: false){
                    line.removeFromParentNode()
                }
                text2.opacity = 0.01
                
                //width
                if (tapped1 || tapped3 || tapped8 || tapped12){
                    //line drawn from left to right
                    updatedWidth = length
                    let scaleFactor = Float(updatedWidth/originalWidth)
                    updatedHeight = originalHeight * scaleFactor
                    updatedLength = originalLength * scaleFactor
                    
                    box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
                    r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                    
                    setCorners()
                    setSpherePosition()
                    removeAllEdges()
                    setEdges()
                    
                    //setEdges() colors all edges blue again, recolor selected edge
                    if tapped1{
                        selectedEdge = scene.drawingNode.childNode(withName: "edge1", recursively: false)!
                        selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                    }
                    if tapped3{
                        selectedEdge = scene.drawingNode.childNode(withName: "edge3", recursively: false)!
                        selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                    }
                    if tapped8{
                        selectedEdge = scene.drawingNode.childNode(withName: "edge8", recursively: false)!
                        selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                    }
                    if tapped12{
                        selectedEdge = scene.drawingNode.childNode(withName: "edge12", recursively: false)!
                        selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                    }
                }
                //height
                else if (tapped2 || tapped4 || tapped6 || tapped10){
                    //line drawn from left to right
                    updatedHeight = length
                    let scaleFactor = Float(updatedHeight/originalHeight)
                    updatedWidth = originalWidth * scaleFactor
                    updatedLength = originalLength * scaleFactor
                    
                    box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
                    r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                    
                    setCorners()
                    setSpherePosition()
                    removeAllEdges()
                    setEdges()
                    
                    //removeAllEdges() also removes the sectedEdge assignment and therefore the selectedEdge would be automatically deselected after lifting press
                    if tapped2{
                        selectedEdge = scene.drawingNode.childNode(withName: "edge2", recursively: false)!
                        selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                    }
                    if tapped4{
                        selectedEdge = scene.drawingNode.childNode(withName: "edge4", recursively: false)!
                        selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                    }
                    if tapped6{
                        selectedEdge = scene.drawingNode.childNode(withName: "edge6", recursively: false)!
                        selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                    }
                    if tapped10{
                        selectedEdge = scene.drawingNode.childNode(withName: "edge10", recursively: false)!
                        selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                    }
                
                }
                //length
                else if (tapped5 || tapped7 || tapped9 || tapped11){
                    //line drawn from left to right
                    updatedLength = length
                    let scaleFactor = Float(updatedLength/originalLength)
                    updatedHeight = originalHeight * scaleFactor
                    updatedWidth = originalWidth * scaleFactor
                    
                    box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
                    r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                    
                    setCorners()
                    setSpherePosition()
                    removeAllEdges()
                    setEdges()
                    
                    //removeAllEdges() also removes the sectedEdge assignment and therefore the selectedEdge would be automatically deselected after lifting press
                    if tapped5{
                        selectedEdge = scene.drawingNode.childNode(withName: "edge5", recursively: false)!
                        selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                    }
                    if tapped7{
                        selectedEdge = scene.drawingNode.childNode(withName: "edge7", recursively: false)!
                        selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                    }
                    if tapped9{
                        selectedEdge = scene.drawingNode.childNode(withName: "edge9", recursively: false)!
                        selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                    }
                    if tapped11{
                        selectedEdge = scene.drawingNode.childNode(withName: "edge11", recursively: false)!
                        selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                    }
              
                }
//                print("updatedHeight: \(updatedHeight)")
//                print("updatedWidth: \(updatedWidth)")
//                print("updatedLength: \(updatedLength)")
//                print (corners)
                pressCounter += 1
                
//                print("\(selectedEdge)")
                //differnet text positioning for different edges
                if tapped1{
                    if let textGeometry1 = text1.geometry as? SCNText {
                        textGeometry1.string = "W:\(valueIncmStr)cm"
                        text1.position = SCNVector3(x:edges.e1.x-0.025, y:edges.e1.y - 0.015, z:edges.e1.z)
                        text1.opacity = 1
                    }
                }
                //edge between lfd to lfh
                else if tapped2{
                   if let textGeometry1 = text1.geometry as? SCNText {
                        textGeometry1.string = "H:\(valueIncmStr)cm"
                        text1.opacity = 1
                        text1.position = SCNVector3(x:edges.e2.x - 0.06, y:edges.e2.y, z:edges.e2.z)
                    }
                }
                //edge between lfh to rfh
                else if tapped3{
                    if let textGeometry1 = text1.geometry as? SCNText {
                        textGeometry1.string = "W:\(valueIncmStr)cm"
                        text1.position = SCNVector3(x:edges.e3.x-0.025, y:edges.e3.y + 0.01, z:edges.e3.z)
                        text1.opacity = 1
                    }
                }
                //edge between rfh to rfd
                else if tapped4{
                    if let textGeometry1 = text1.geometry as? SCNText {
                        textGeometry1.string = "H:\(valueIncmStr)cm"
                        text1.opacity = 1
                        text1.position = SCNVector3(x:edges.e4.x+0.01, y:edges.e4.y, z:edges.e4.z)
                    }
                }
                //edge between lfd to lbd
                else if tapped5{
                    if let textGeometry1 = text1.geometry as? SCNText {
                        textGeometry1.string = "L:\(valueIncmStr)cm"
                        text1.opacity = 1
                        text1.position = SCNVector3(x:edges.e5.x - 0.06 , y:edges.e5.y, z:edges.e5.z)
                    }
                }
                //edge between lbd to lbh
                else if tapped6{
                    if let textGeometry1 = text1.geometry as? SCNText {
                        textGeometry1.string = "H:\(valueIncmStr)cm"
                        text1.opacity = 1
                        text1.position = SCNVector3(x:edges.e6.x - 0.06, y:edges.e6.y, z:edges.e6.z)
                    }
                }
                //edge between lbh to lfh
                else if tapped7{
                    if let textGeometry1 = text1.geometry as? SCNText {
                        textGeometry1.string = "L:\(valueIncmStr)cm"
                        text1.opacity = 1
                        text1.position = SCNVector3(x:edges.e7.x - 0.06, y:edges.e7.y, z:edges.e7.z)
                    }
                }
                //edge between lbh to rbh
                else if tapped8{
                    if let textGeometry1 = text1.geometry as? SCNText {
                        textGeometry1.string = "W:\(valueIncmStr)cm"
                        text1.position = SCNVector3(x:edges.e8.x-0.025, y:edges.e8.y + 0.015, z:edges.e8.z)
                        text1.opacity = 1
                    }
                }
                //edge between rbh to rfh
                else if tapped9 {
                   if let textGeometry1 = text1.geometry as? SCNText {
                        textGeometry1.string = "L:\(valueIncmStr)cm"
                        text1.opacity = 1
                        text1.position = SCNVector3(x:edges.e9.x + 0.01, y:edges.e9.y, z:edges.e9.z)
                    }
                }
                //edge between rbh to rbd
                else if tapped10{
                   if let textGeometry1 = text1.geometry as? SCNText {
                        textGeometry1.string = "H:\(valueIncmStr)cm"
                        text1.opacity = 1
                        text1.position = SCNVector3(x:edges.e10.x + 0.01, y:edges.e10.y - 0.01, z:edges.e10.z)
                    }
                }
                //edge between rfd to rbd
                else if tapped11{
                    if let textGeometry1 = text1.geometry as? SCNText {
                        textGeometry1.string = "L:\(valueIncmStr)cm"
                        text1.opacity = 1
                        text1.position = SCNVector3(x:edges.e11.x + 0.01 , y:edges.e11.y, z:edges.e11.z)
                    }
                }
                //edge between lbd to rbd
                else if tapped12{
                    
                    if let textGeometry1 = text1.geometry as? SCNText {
                        textGeometry1.string = "W:\(valueIncmStr)cm"
                        text1.position = SCNVector3(x:edges.e12.x - 0.025 , y:edges.e12.y - 0.015, z:edges.e12.z)
                        text1.opacity = 1
                    }
                }
                endTime = Date()
            }
            
            if !pressed && !pressed2 && !pressed3 && pressCounter>2 {
                pressCounter = 1
                selectedEdge.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                
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
        
        //Define boundingBox
        let boundingBoxCorners = r2d2Node!.boundingBox
        let OriginalMinCorner = boundingBoxCorners.0
        let OriginalMaxCorner = boundingBoxCorners.1
        let minCorner = SCNVector3(x:OriginalMinCorner.x*0.001,y:OriginalMinCorner.y*0.001,z:OriginalMinCorner.z*0.001)
        let maxCorner = SCNVector3(x:OriginalMaxCorner.x*0.001,y:OriginalMaxCorner.y*0.001,z:OriginalMaxCorner.z*0.001)
        //print("maxCorner\(maxCorner)")
        //print("minCorner\(minCorner)")

        /*let sm = "float u = _surface.diffuseTexcoord.x; \n" +
                 "float v = _surface.diffuseTexcoord.y; \n" +
                 "int u100 = int(u * 100); \n" +
                 "int v100 = int(v * 100); \n" +
                 "if (u100 % 99 == 0 || v100 % 99 == 0) { \n" +
                 "  // do nothing \n" +
                 "} else { \n" +
                 "    discard_fragment(); \n" +
                 "} \n"*/
        
        originalWidth = maxCorner.x - minCorner.x
        originalHeight = maxCorner.z - minCorner.z
        originalLength = maxCorner.y - minCorner.y
        //print("width: \(originalWidth)")
        //print("height: \(originalHeight)")
        //print("length: \(originalLength)")
        
        self.updatedWidth = originalWidth
        self.updatedHeight = originalHeight
        self.updatedLength = originalLength
        
        let box = SCNBox(width: CGFloat(originalWidth*0.01), height: CGFloat(originalHeight*0.01), length: CGFloat(originalLength*0.01), chamferRadius: 0)
        //box.firstMaterial?.diffuse.contents  = UIColor.systemBlue
        //box.firstMaterial?.emission.contents = UIColor.systemBlue
        //box.firstMaterial?.shaderModifiers = [SCNShaderModifierEntryPoint.surface: sm]
        box.firstMaterial?.isDoubleSided = true
        let boundingBox = SCNNode(geometry: box)
        
        if boundingBox != scene.drawingNode.childNode(withName: "currentBoundingBox", recursively: false){
            boundingBox.position = SCNVector3(0,0.2,0)
            centerPosition = boundingBox.position
//            print("position:\(boundingBox.position)")
            boundingBox.name = "currentBoundingBox"
            boundingBox.opacity = 0.01
            scene.drawingNode.addChildNode(boundingBox)
            }
        else{
            boundingBox.position = SCNVector3(0,0.2,0)
            
        }
        
        
        setCorners()
        //visualize lines for edges
        setEdges()
        
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
        
        //show current width, length, height of edges incident to the selected corner
        let displayedValue = SCNText(string: "", extrusionDepth: 0.2)
        //displayedWidth.font = UIFont (name: "Arial", size: 3)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        displayedValue.materials = [material]
        let selectedEdgeScale = SCNNode(geometry: displayedValue)
        
        if selectedEdgeScale != scene.drawingNode.childNode(withName: "selectedEdgeScale", recursively: false){
            selectedEdgeScale.position = SCNVector3(x:edges.e1.x, y:edges.e1.y + 0.05, z:edges.e1.z)
            selectedEdgeScale.name = "selectedEdgeScale"
            selectedEdgeScale.scale = SCNVector3(x:0.001, y:0.001, z:0.001)
            scene.drawingNode.addChildNode(selectedEdgeScale)
        }
        else{
            selectedEdgeScale.position = SCNVector3(x:edges.e1.x, y:edges.e1.y + 0.05, z:edges.e1.z)
        }
        
        let displayedLength = SCNText(string: "", extrusionDepth: 0.2)
        displayedLength.materials = [material]
        let drawnValue = SCNNode(geometry: displayedLength)

        if drawnValue != scene.drawingNode.childNode(withName: "customScale", recursively: false){
            drawnValue.position = SCNVector3(x:edges.e4.x  + 0.1 , y:edges.e4.y, z:edges.e4.z)
            drawnValue.name = "customScale"
            drawnValue.scale = SCNVector3(x:0.001, y:0.001, z:0.001)
            scene.drawingNode.addChildNode(drawnValue)
        }
        else{
            drawnValue.position = SCNVector3(x:edges.e4.x + 0.1, y:edges.e4.y, z:edges.e4.z)
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
        if let text1 = currentScene?.drawingNode.childNode(withName: "selectedEdgeScale", recursively: false){
            text1.removeFromParentNode()
         }
        if let text2 = currentScene?.drawingNode.childNode(withName: "customScale", recursively: false){
            text2.removeFromParentNode()
         }
        self.currentScene = nil

        self.currentView = nil
    }
    
}



