//
//  StudyFreehandPainting.swift
//  ARPen
//
//  Created by Martin on 19.02.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class StudyFreehandPainting: Plugin, UserStudyRecordPluginProtocol {
    
    var recordManager: UserStudyRecordManager!
    
    
    var pluginImage : UIImage? = UIImage.init(named: "FreehandPainting")
    var pluginInstructionsImage: UIImage? = UIImage.init(named: "FreehandPaintingPluginInstructions")
    var pluginIdentifier: String = "Freehand"
    var needsBluetoothARPen: Bool = false
    var pluginDisabledImage: UIImage? = UIImage.init(named: "ARMenusPluginDisabled")
    var currentScene : PenScene?
    var currentView: ARSCNView?
    
    var penColor: UIColor = UIColor.init(red: 0.73, green: 0.12157, blue: 0.8, alpha: 1)
    
    var objectCounter: Int = 0
    var objectCurrentlyBuilding: Bool = false
    
    
    let objectOpacity = 0.7
    
    let cubeSizeSmall = 0.08
    let cubeSizeLarge = 0.12
    
    // trial data
    var userID = 5
    var trialNumber = 0
    var trialID = -1
    var trialList = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    var trialValid = true
    
    /**
     The starting point is the point of the pencil where the button was first pressed.
     If this var is nil, there was no initial point
     */
    private var startingPoint: SCNVector3?
    
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    private var previousPoint: SCNVector3?
    //collection of currently & last drawn line elements to offer undo
    var previousDrawnLineNodes: [[SCNNode]]?
    private var currentLine : [SCNNode]?
    private var removedOneLine = false
    
    private var closestPoint: SCNVector3?
    
    private var averageError = Float(-1)
    
    private var dataExported = true
    private var retryTrial = false

    // modified undoPreviousAction for user study
    func undoPreviousAction() {
        retryTrial = true
        //print("undoButton")
    }
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        guard scene.markerFound else {
            //Don't reset the previous point to avoid disconnected lines if the marker detection failed for some frames
            //self.previousPoint = nil
            return
        }
        
        
        let pressed2 = buttons[Button.Button2]!

        if (pressed2){
            //print("retryTrial")
            while (self.previousDrawnLineNodes!.count > 0) {
                  //print("removing line")
                  let lastLine = self.previousDrawnLineNodes?.last

                  self.previousDrawnLineNodes?.removeLast()

                  // Remove the previous line
                  for currentNode in lastLine! {
                      currentNode.removeFromParentNode()
                  }
              }
              let targetMeasurementDict = [
                  "TrialNumber" : String(describing: trialNumber),
                  "TrialID": String(describing: trialID),
                  "TrialValid": String(describing: false)
              ]
              self.recordManager.addNewRecord(withIdentifier: self.pluginIdentifier, andData: targetMeasurementDict)
              trialNumber = trialNumber + 1
            retryTrial = false
        }
        
        
        let pressed = buttons[Button.Button1]!
        
        var objectList: [SCNNode]
        
        if let arImageNode = scene.rootNode.childNode(withName: "ARImage", recursively: false){
            objectList = arImageNode.childNodes
        } else {
            objectList = scene.drawingNode.childNodes
        }
        
        
        var closestDistance = Float(-1)
        var closestPosition: SCNVector3?
        closestPosition = nil
        var numberOfPositions: Int = 0
        var currentError = Float(-1)
        
        
        
        if pressed, let previousPoint = self.previousPoint {
            
            
            if currentLine == nil {
                currentLine = [SCNNode]()
            }
            let cylinderNode = SCNNode()
            
            cylinderNode.buildLineInTwoPointsWithRotation(from:
                cylinderNode.convertPosition(previousPoint, to: scene.arAnchorImage), to: scene.pencilPoint.convertPosition(SCNVector3Zero, to: scene.arAnchorImage), radius: 0.001, color: penColor)
            //cylinderNode.buildLineInTwoPointsWithRotation(from: previousPoint, to: scene.pencilPoint.position, radius: 0.001, color: penColor)
            
            cylinderNode.name = "cylinderLine"
            scene.arAnchorImage.addChildNode(cylinderNode)
            //scene.drawingNode.addChildNode(cylinderNode)
            
            //add last drawn line element to currently drawn line collection
            currentLine?.append(cylinderNode)
            // For study: measure distance to closest guide line position:
            
            if (objectList.contains(where: {($0.name?.hasPrefix("currentStudyObjectNode") ?? false)})){
                for obj in objectList{
                    var distance = Float(-1)
                    var surfacePosition = SCNVector3Zero
                    
                    for child in obj.childNodes{
                            if (child.name?.hasPrefix("currentStudyObjectGuideNode") ?? false){
                            // use positioning with box, ignoring chamfer
                            // convert pen position to box space
                            var localPosition = scene.projectionNode.convertPosition(SCNVector3Zero, to: obj)
                            
                            // clamp coordinates to box size
                            
                            if (localPosition.x > Float((child.geometry as! SCNBox).width)/2){
                                localPosition.x = Float((child.geometry as! SCNBox).width)/2
                            }
                            if (localPosition.x < Float(-(child.geometry as! SCNBox).width)/2){
                                localPosition.x = Float(-(child.geometry as! SCNBox).width)/2
                            }
                            
                            if (localPosition.y > Float((child.geometry as! SCNBox).height)/2){
                                localPosition.y = Float((child.geometry as! SCNBox).height)/2
                            }
                            if (localPosition.y < Float(-(child.geometry as! SCNBox).height)/2){
                                localPosition.y = Float(-(child.geometry as! SCNBox).height)/2
                            }
                            
                            if (localPosition.z > Float((child.geometry as! SCNBox).length)/2){
                                localPosition.z = Float((child.geometry as! SCNBox).length)/2
                            }
                            if (localPosition.z < Float(-(child.geometry as! SCNBox).length)/2){
                                localPosition.z = Float(-(child.geometry as! SCNBox).length)/2
                            }
                            // if inside box, go to closest edge position
                            
                            if (localPosition.x > Float(-(child.geometry as! SCNBox).width)/2 &&
                                localPosition.x < Float( (child.geometry as! SCNBox).width)/2 &&
                                localPosition.y > Float(-(child.geometry as! SCNBox).height)/2 &&
                                localPosition.y < Float( (child.geometry as! SCNBox).height)/2 &&
                                localPosition.z > Float(-(child.geometry as! SCNBox).length)/2 &&
                                localPosition.z < Float( (child.geometry as! SCNBox).length)/2 ){
                                
                                
                                // find closest edge position
                                var deltaX = Float(0)
                                var deltaY = Float(0)
                                var deltaZ = Float(0)
                                
                                if (localPosition.x >= 0){
                                    deltaX = Float((child.geometry as! SCNBox).width)/2 - localPosition.x
                                }
                                if (localPosition.x < 0){
                                    deltaX = -Float((child.geometry as! SCNBox).width)/2 - localPosition.x
                                }
                                if (localPosition.y >= 0){
                                    deltaY = Float((child.geometry as! SCNBox).height)/2 - localPosition.y
                                }
                                if (localPosition.y < 0){
                                    deltaY = -Float((child.geometry as! SCNBox).height)/2 - localPosition.y
                                }
                                if (localPosition.z >= 0){
                                    deltaZ = Float((child.geometry as! SCNBox).length)/2 - localPosition.z
                                }
                                if (localPosition.z < 0){
                                    deltaZ = -Float((child.geometry as! SCNBox).length)/2 - localPosition.z
                                }
                                
                                if (deltaX < 0){
                                    deltaX = -deltaX
                                }
                                if (deltaY < 0){
                                    deltaY = -deltaY
                                }
                                if (deltaZ < 0){
                                    deltaZ = -deltaZ
                                }
                                
                                if (deltaX <= deltaY && deltaX <= deltaZ){
                                    // X position is closest to edge
                                    if (localPosition.x >= 0){
                                        localPosition.x = Float((child.geometry as! SCNBox).width)/2
                                    }
                                    if (localPosition.x < 0){
                                        localPosition.x = -Float((child.geometry as! SCNBox).width)/2
                                    }
                                }
                                if (deltaY < deltaX && deltaY <= deltaZ){
                                    // Y position is closest to edge
                                    if (localPosition.y >= 0){
                                        localPosition.y = Float((child.geometry as! SCNBox).height)/2
                                    }
                                    if (localPosition.y < 0){
                                        localPosition.y = -Float((child.geometry as! SCNBox).height)/2
                                    }
                                }
                                if (deltaZ < deltaX && deltaZ < deltaY){
                                    // Z position is closest to edge
                                    if (localPosition.z >= 0){
                                        localPosition.z = Float((child.geometry as! SCNBox).length)/2
                                    }
                                    if (localPosition.z < 0){
                                        localPosition.z = -Float((child.geometry as! SCNBox).length)/2
                                    }
                                }
                            }
                            // convert pos back to global space
                            surfacePosition = child.convertPosition(localPosition, to: nil)
                            distance = surfacePosition.distance(vector: scene.projectionNode.position)
                                
                            }
                            if (distance > 0 && distance < closestDistance || closestDistance < 0){
                                //print("found new closest position")
                                numberOfPositions += 1
                                closestDistance = distance
                                
                                currentError = closestDistance
                                averageError = (distance + averageError * Float(numberOfPositions-1)) / Float(numberOfPositions)
                                //print("average error: ", averageError)
                            }
                        }
                    }
            }

            let timestamp = Date().timeIntervalSince1970
            let userID = 0

            
            var currentStudyObject: SCNNode?
            
            if (objectList.contains(where: {($0.name?.hasPrefix("currentStudyObjectNode") ?? false)})){
                
                for obj in objectList{
                                        
                    if (obj.name?.hasPrefix("currentStudyObjectNode") ?? false){
                        currentStudyObject = obj
                    }
                }
            }
            
            let studyObjectSize = Float(99)
            let studyObjectCornerType = "CornerTypeUnknown"
            
            

            let targetMeasurementDict = [
                
            "TrialNumber" : String(describing: trialNumber),
            "TrialID" : String(describing: trialID),
            "PenTipPositionX" : String(describing: scene.pencilPoint.position.x),
            "PenTipPositionY" : String(describing: scene.pencilPoint.position.y),
            "PenTipPositionZ" : String(describing: scene.pencilPoint.position.z),
            "ProjectionPositionX" : String(describing: scene.projectionNode.position.x),
            "ProjectionPositionY" : String(describing: scene.projectionNode.position.y),
            "ProjectionPositionZ" : String(describing: scene.projectionNode.position.z),
            "RelativeProjectionX" : String(describing: scene.projectionNode.convertPosition(SCNVector3Zero, to: scene.arAnchorImage).x),
            "RelativeProjectionY" : String(describing: scene.projectionNode.convertPosition(SCNVector3Zero, to: scene.arAnchorImage).y),
            "RelativeProjectionZ" : String(describing: scene.projectionNode.convertPosition(SCNVector3Zero, to: scene.arAnchorImage).z),
            "StudyObjectPositionX" : String(describing: currentStudyObject?.position.x ?? -1),
            "StudyObjectPositionY" : String(describing: currentStudyObject?.position.y ?? -1),
            "StudyObjectPositionZ" : String(describing: currentStudyObject?.position.z ?? -1)
            ]
            
            
            dataExported = false
            self.recordManager.addNewRecord(withIdentifier: self.pluginIdentifier, andData: targetMeasurementDict)

            
        } else if !pressed {
            if let currentLine = self.currentLine {
                self.previousDrawnLineNodes?.append(currentLine)
                self.currentLine = nil
            }
        }
        
        
        
        
        

        
        self.previousPoint = scene.pencilPoint.position
        scene.projectionNode.position = closestPosition ?? scene.projectionNode.position
        
        // MARK: Button3, Object Creation
        

                //Check state of the first button -> used to create the cube
                let pressed3 = buttons[Button.Button3]!
                
                //if the button is pressed -> either set the starting point of the cube (first action) or scale the cube to fit from the starting point to the current point
                if pressed3 {

                    
                    if !dataExported {
                        //self.recordManager.saveToFile()
                        self.recordManager.urlToCSV()
                        dataExported = true
                    }
                    
                    
                    var objectNode = SCNNode()
                    if let startingPoint = self.startingPoint {
                        // spawnPoint is the position at which StudyObjects are created
                       
                        //let spawnPoint = SCNVector3Zero
                        var spawnPoint = scene.pencilPoint.position
                        if let arImageNode = scene.rootNode.childNode(withName: "ARImage", recursively: false){
                            spawnPoint = arImageNode.position
                        }
                        //see if there is an active box node that is currently being drawn. Otherwise create it
                        
                        // if no object exists: create new object
                        if !objectCurrentlyBuilding{
                            // object exists already: delete it and create new object
                            
                            // Case: study object was created as child of drawing node
                            if let studyObjectNode = scene.drawingNode.childNode(withName: "currentStudyObjectNode", recursively: false){
                                for obj in studyObjectNode.childNodes{
                                    obj.removeFromParentNode()
                                }
                                studyObjectNode.removeFromParentNode()
//                                while (self.previousDrawnLineNodes!.count > 0){
//                                    undoPreviousAction()
//                                }
                            }
                            
                            
                            if let studyObjectNode = scene.drawingNode.childNode(withName: "currentStudyObjectBoxNode", recursively: false){
                                for obj in studyObjectNode.childNodes{
                                    obj.removeFromParentNode()
                                }
                                studyObjectNode.removeFromParentNode()
//                                while (self.previousDrawnLineNodes!.count > 0){
//                                    undoPreviousAction()
//                                }
                            }
                            
                            if let studyObjectNode = scene.drawingNode.childNode(withName: "currentStudyObjectSphereNode", recursively: false){
                                for obj in studyObjectNode.childNodes{
                                    obj.removeFromParentNode()
                                }
                                studyObjectNode.removeFromParentNode()
//                                while (self.previousDrawnLineNodes!.count > 0){
//                                    undoPreviousAction()
//                                }
                            }
                            
                            if let studyObjectNode =  scene.drawingNode.childNode(withName: "currentStudyObjectGuideNode", recursively: false){
                                for obj in studyObjectNode.childNodes{
                                    obj.removeFromParentNode()
                                }
                                studyObjectNode.removeFromParentNode()
//                                while (self.previousDrawnLineNodes!.count > 0){
//                                    undoPreviousAction()
//                                }
                            }
                            
                             if let arImageNode = scene.rootNode.childNode(withName: "ARImage", recursively: false){
                                if let studyObjectNode = arImageNode.childNode(withName: "currentStudyObjectNode", recursively: false){
                                    for obj in studyObjectNode.childNodes{
                                        obj.removeFromParentNode()
                                    }
                                    studyObjectNode.removeFromParentNode()
                                          
                                    while (self.previousDrawnLineNodes!.count > 0){
                                            let lastLine = self.previousDrawnLineNodes?.last
                                            self.previousDrawnLineNodes?.removeLast()
                                            
                                            // Remove the previous line
                                            for currentNode in lastLine! {
                                                currentNode.removeFromParentNode()
                                            }
                                        }
                                }
                                
                                
                                if let studyObjectNode = arImageNode.childNode(withName: "currentStudyObjectBoxNode", recursively: false){
                                    for obj in studyObjectNode.childNodes{
                                        obj.removeFromParentNode()
                                    }
                                    studyObjectNode.removeFromParentNode()
//                                    while (self.previousDrawnLineNodes!.count > 0){
//                                        undoPreviousAction()
//                                    }
                                }
                                
                                if let studyObjectNode = arImageNode.childNode(withName: "currentStudyObjectSphereNode", recursively: false){
                                    for obj in studyObjectNode.childNodes{
                                        obj.removeFromParentNode()
                                    }
                                    studyObjectNode.removeFromParentNode()
//                                    while (self.previousDrawnLineNodes!.count > 0){
//                                        undoPreviousAction()
//                                    }
                                }
                                
                                if let studyObjectNode =  arImageNode.childNode(withName: "currentStudyObjectGuideNode", recursively: false){
                                    for obj in studyObjectNode.childNodes{
                                        obj.removeFromParentNode()
                                    }
                                    studyObjectNode.removeFromParentNode()
//                                    while (self.previousDrawnLineNodes!.count > 0){
//                                        undoPreviousAction()
//                                    }
                                }
                            }
                            
                            if (objectCounter == 0 || objectCounter >= trialList.count){
                                trialList.shuffle()
                                objectCounter = 0
                                //print("shuffle")
                            }
                            
                            trialID = trialList[objectCounter]
                            
                            // whether previous object existed or not, create new one
                            switch trialList[objectCounter] {
                            case 0:
                            // flat corner small
                                objectNode = generateObject(size: 1, shape: 1, corner: 3, startingPoint: spawnPoint, scene: scene)
                                break
                            case 1:
                            // flat corner large
                                objectNode = generateObject(size: 2, shape: 1, corner: 3, startingPoint: spawnPoint, scene: scene)
                                break
                            case 2:
                            // exterior corner small
                                objectNode = generateObject(size: 1, shape: 1, corner: 1, startingPoint: spawnPoint, scene: scene)
                                break
                            case 3:
                            // exterior corner large
                                objectNode = generateObject(size: 2, shape: 1, corner: 1, startingPoint: spawnPoint, scene: scene)
                                break
                            case 4:
                            // interior corner small
                                objectNode = generateObject(size: 1, shape: 1, corner: 2, startingPoint: spawnPoint, scene: scene)
                                break
                            case 5:
                            // interior corner large
                                objectNode = generateObject(size: 2, shape: 1, corner: 2, startingPoint: spawnPoint, scene: scene)
                                break
                            case 6:
                            // Right Side Flat small
                                objectNode = generateObject(size: 1, shape: 1, corner: 4, startingPoint: spawnPoint, scene: scene)
                                break
                            case 7:
                            // Right Side Flat large
                                objectNode = generateObject(size: 2, shape: 1, corner: 4, startingPoint: spawnPoint, scene: scene)
                                break
                            case 8:
                            // Front Side Flat small
                                objectNode = generateObject(size: 1, shape: 1, corner: 5, startingPoint: spawnPoint, scene: scene)
                                break
                            case 9:
                            // Front Side Flat large
                                objectNode = generateObject(size: 2, shape: 1, corner: 5, startingPoint: spawnPoint, scene: scene)
                                break
                            
                            default:
                                break
                            }

                            if let arImageNode = scene.rootNode.childNode(withName: "ARImage", recursively: false){
                                arImageNode.addChildNode(objectNode)
                            } else {
                                scene.drawingNode.addChildNode(objectNode)
                            }
        //
        //                    let objectNode = generateObject(size: 1, shape: 1, direction: 1, corner: 2, startingPoint: scene.pencilPoint.position, scene: scene)
        //                    objectNode.name = "currentStudyObjectNode"
                            objectCurrentlyBuilding = true
                            objectCounter += 1
                        }
                    
                        
                    }
                    else {
                        //if the button is pressed but no startingPoint exists -> first frame with the button pressed. Set current pencil position as the start point
                        self.startingPoint = scene.pencilPoint.position
                    }
                }
                else {
                    //if the button is not pressed, check if a startingPoint is set -> released button. Reset the startingPoint to nil and set the name of the drawn box to "finished"
                    if objectCurrentlyBuilding{
                        objectCurrentlyBuilding = false
                    }
                    if self.startingPoint != nil {
                        self.startingPoint = nil
                        if let boxNode = scene.drawingNode.childNode(withName: "currentStudyObjectNode", recursively: false), let boxNodeGeometry = boxNode.geometry as? SCNBox {
                            boxNode.name = "currentStudyObjectNode"
                            
                            //store a new record with the size of the finished box
                            let boxDimensionsDict = ["Width" : String(describing: boxNodeGeometry.width), "Height" : String(describing: boxNodeGeometry.height), "Length" : String(describing: boxNodeGeometry.length)]
                            self.recordManager.addNewRecord(withIdentifier: "BoxFinished", andData: boxDimensionsDict)
                        }
                    }
                    
                    
            
                }
                
        
        
        
        
    }
    
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentScene = scene
        self.currentView = view
        previousDrawnLineNodes = [[SCNNode]]()
        
        
        scene.pencilPoint.opacity = 1
        scene.projectionNode.opacity = 0
    }
    
    func deactivatePlugin() {
        guard let scene = self.currentScene else {

            self.currentScene = nil
            self.currentView = nil
            
            return
            
        }
        
        if let arImageNode = scene.rootNode.childNode(withName: "ARImage", recursively: false){
            if let studyObjectNode = arImageNode.childNode(withName: "currentStudyObjectNode", recursively: false){
                for obj in studyObjectNode.childNodes{
                    obj.removeFromParentNode()
                }
                studyObjectNode.removeFromParentNode()
                
                while (self.previousDrawnLineNodes!.count > 0){
                        let lastLine = self.previousDrawnLineNodes?.last
                        
                        self.previousDrawnLineNodes?.removeLast()
        
                        // Remove the previous line
                        for currentNode in lastLine! {
                            currentNode.removeFromParentNode()
                        }
                    }
            }
        }
        
        self.currentScene = nil
        self.currentView = nil
        
    }
    // MARK: Object Creation
    

func generateObject(size: Int, shape: Int, corner: Int, startingPoint: SCNVector3, scene: PenScene)->SCNNode{
    var objectNode = SCNNode()
    
        switch corner{
        // interior
        case 1:
            objectNode = createCubeInterior(size: size, startingPoint: startingPoint, scene: scene)
            break
        // exterior
        case 2:
            objectNode = createCubeExterior(size: size, startingPoint: startingPoint, scene: scene)
            break
        // flat
        case 3:
            objectNode = createCubeFlat(size: size, startingPoint: startingPoint, scene: scene)
            break
        // flat + right side
        case 4:
            objectNode = createCubeFlatRightSide(size: size, startingPoint: startingPoint, scene: scene)
            break
        // flat + front side
        case 5:
            objectNode = createCubeFlatFrontSide(size: size, startingPoint: startingPoint,scene: scene)
            break
        default: break
        }
    
    trialNumber = trialNumber+1
    
    
    return objectNode
    
}

func createCubeExterior(size: Int, startingPoint: SCNVector3, scene: PenScene)->SCNNode{
    let objectNode = SCNNode()
    objectNode.name = "currentStudyObjectNode"
    let boxNode = SCNNode()
    boxNode.name = "currentStudyObjectBoxNode"
    objectNode.addChildNode(boxNode)
    
    var spawnPoint = startingPoint
    
    var cubeSize: Float
    switch size{
    case 1: cubeSize = Float(cubeSizeSmall)
    spawnPoint = spawnPoint + SCNVector3(0, cubeSizeSmall/2, 0)
        break
    case 2: cubeSize = Float(cubeSizeLarge)
    spawnPoint = spawnPoint + SCNVector3(0, cubeSizeLarge/2, 0)
        break
    default: cubeSize = 0.2
        break
    }
    
    objectNode.position = spawnPoint
    
    boxNode.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let boxNodeGeometry = boxNode.geometry as! SCNBox
    
    //set the dimensions of the box
    boxNodeGeometry.width = CGFloat(cubeSize)
    boxNodeGeometry.height = CGFloat(cubeSize)
    boxNodeGeometry.length = CGFloat(cubeSize)
    
    boxNode.position = SCNVector3Zero
    
    
    
    
    // create guiding line around object
    createTargetLine(parentNode: objectNode, cubeSize: cubeSize, height: cubeSize/2)
    
    

    boxNode.opacity = CGFloat(objectOpacity)
    
    return objectNode
}


func createTargetLine(parentNode: SCNNode, cubeSize: Float, height: Float){
    // create four guide boxes, so that they form a ring, not a solid plane
    let guideNode1 = SCNNode()
    let guideNode2 = SCNNode()
    let guideNode3 = SCNNode()
    let guideNode4 = SCNNode()
    guideNode1.name = "currentStudyObjectGuideNode"
    guideNode2.name = "currentStudyObjectGuideNode"
    guideNode3.name = "currentStudyObjectGuideNode"
    guideNode4.name = "currentStudyObjectGuideNode"
    parentNode.addChildNode(guideNode1)
    parentNode.addChildNode(guideNode2)
    parentNode.addChildNode(guideNode3)
    parentNode.addChildNode(guideNode4)
    
    guideNode1.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let guideNodeGeometry1 = guideNode1.geometry as! SCNBox
    guideNode2.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let guideNodeGeometry2 = guideNode2.geometry as! SCNBox
    guideNode3.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let guideNodeGeometry3 = guideNode3.geometry as! SCNBox
    guideNode4.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let guideNodeGeometry4 = guideNode4.geometry as! SCNBox

    let guideSize = cubeSize * 1.001
    
    guideNode1.position = SCNVector3(cubeSize/2, height, 0)
    guideNode2.position = SCNVector3(-cubeSize/2, height, 0)
    guideNode3.position = SCNVector3(0, height, cubeSize/2)
    guideNode4.position = SCNVector3(0, height, -cubeSize/2)
            
    //set the dimensions of the boxes
    guideNodeGeometry1.width = CGFloat(0.0005)
    guideNodeGeometry1.height = CGFloat(0.0005)
    guideNodeGeometry1.length = CGFloat(guideSize)
    guideNodeGeometry2.width = CGFloat(0.0005)
    guideNodeGeometry2.height = CGFloat(0.0005)
    guideNodeGeometry2.length = CGFloat(guideSize)
    guideNodeGeometry3.width = CGFloat(guideSize)
    guideNodeGeometry3.height = CGFloat(0.0005)
    guideNodeGeometry3.length = CGFloat(0.0005)
    guideNodeGeometry4.width = CGFloat(guideSize)
    guideNodeGeometry4.height = CGFloat(0.0005)
    guideNodeGeometry4.length = CGFloat(0.0005)
              
    guideNodeGeometry1.materials.first?.diffuse.contents = UIColor.red
    guideNodeGeometry2.materials.first?.diffuse.contents = UIColor.red
    guideNodeGeometry3.materials.first?.diffuse.contents = UIColor.red
    guideNodeGeometry4.materials.first?.diffuse.contents = UIColor.red
    
    // Add starting point and draw direction signifiers
    let startPointNode = SCNNode()
    startPointNode.name = "currentStudyObjectStartingPointNode"
    parentNode.addChildNode(startPointNode)
    startPointNode.geometry = SCNSphere.init(radius: 0.002)
    let startPointGeometry = startPointNode.geometry as! SCNSphere
    startPointGeometry.materials.first?.diffuse.contents = UIColor.red
    startPointNode.position = SCNVector3(-cubeSize/2, height, cubeSize/2)
    
    
    let directionArrowNode = SCNNode()
    directionArrowNode.name = "currentStudyObjectDirectionArrowNode"
    parentNode.addChildNode(directionArrowNode)
    directionArrowNode.geometry = SCNCone.init(topRadius: 0, bottomRadius: 0.0035, height: 0.008)
    let directionArrowGeometry = directionArrowNode.geometry as! SCNCone
    directionArrowGeometry.materials.first?.diffuse.contents = UIColor.red
    directionArrowNode.position = SCNVector3(0, height, cubeSize/2)
    directionArrowNode.eulerAngles = SCNVector3(-cubeSize/4, 0, -Float.pi/2)
}


func createCubeInterior(size: Int, startingPoint: SCNVector3, scene: PenScene)->SCNNode{
    
    let objectNode = SCNNode()
    objectNode.name = "currentStudyObjectNode"
    let boxNode = SCNNode()
    boxNode.name = "currentStudyObjectBoxNode"
    scene.drawingNode.addChildNode(objectNode)
    objectNode.addChildNode(boxNode)
    
    var spawnPoint = startingPoint
    
    var cubeSize: Float
    switch size{
    case 1: cubeSize = Float(cubeSizeSmall)
    spawnPoint = spawnPoint + SCNVector3(0, cubeSizeSmall/2, 0)
        break
    case 2: cubeSize = Float(cubeSizeLarge)
    spawnPoint = spawnPoint + SCNVector3(0, cubeSizeLarge/2, 0)
        break
    default: cubeSize = 0.2
        break
    }
    
    objectNode.position = spawnPoint
    
    // create box itself
    boxNode.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let boxNodeGeometry = boxNode.geometry as! SCNBox
    
    boxNodeGeometry.width = CGFloat(cubeSize)
    boxNodeGeometry.height = CGFloat(cubeSize)
    boxNodeGeometry.length = CGFloat(cubeSize)
    
    boxNode.position = SCNVector3Zero

    // create "base"
    let baseNode = SCNNode()
    baseNode.name = "currentStudyObjectBoxNode"
    objectNode.addChildNode(baseNode)
    
    baseNode.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let baseNodeGeometry = baseNode.geometry as! SCNBox
    
    baseNodeGeometry.width = CGFloat(cubeSize * 1.4)
    baseNodeGeometry.height = CGFloat(0.001)
    baseNodeGeometry.length = CGFloat(cubeSize * 1.4)
    
    
    // create guiding line around object
    createTargetLine(parentNode: objectNode, cubeSize: cubeSize, height: 0)
    
    
    boxNode.opacity = CGFloat(objectOpacity)
    baseNode.opacity = CGFloat(objectOpacity)
    baseNode.position = SCNVector3(0, -0.001, 0)
    
    return objectNode
}

func createCubeFlat(size: Int, startingPoint: SCNVector3, scene: PenScene)->SCNNode{
    
    let objectNode = SCNNode()
    objectNode.name = "currentStudyObjectNode"
    let boxNode = SCNNode()
    boxNode.name = "currentStudyObjectBoxNode"
    scene.drawingNode.addChildNode(objectNode)
    objectNode.addChildNode(boxNode)
    
    var spawnPoint = startingPoint
    
    var cubeSize: Float
    switch size{
    case 1: cubeSize = Float(cubeSizeSmall)
    spawnPoint = spawnPoint + SCNVector3(0, cubeSizeSmall/2, 0)
        break
    case 2: cubeSize = Float(cubeSizeLarge)
    spawnPoint = spawnPoint + SCNVector3(0, cubeSizeLarge/2, 0)
        break
    default: cubeSize = 0.2
        break
    }
    
    objectNode.position = spawnPoint
    
    boxNode.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let boxNodeGeometry = boxNode.geometry as! SCNBox
    
    //set the dimensions of the box
    boxNodeGeometry.width = CGFloat(cubeSize)
    boxNodeGeometry.height = CGFloat(cubeSize)
    boxNodeGeometry.length = CGFloat(cubeSize)
    
    boxNode.position = SCNVector3Zero
    
    
    // create guiding line around object
    createTargetLine(parentNode: objectNode, cubeSize: cubeSize, height: 0)
    

    boxNode.opacity = CGFloat(objectOpacity)
    
    return objectNode
    
}

func createCubeFlatRightSide(size: Int, startingPoint: SCNVector3, scene: PenScene)->SCNNode{
    
    let objectNode = SCNNode()
    objectNode.name = "currentStudyObjectNode"
    let boxNode = SCNNode()
    boxNode.name = "currentStudyObjectBoxNode"
    scene.drawingNode.addChildNode(objectNode)
    objectNode.addChildNode(boxNode)
    
    var spawnPoint = startingPoint
    
    var cubeSize: Float
    switch size{
    case 1: cubeSize = Float(cubeSizeSmall)
    spawnPoint = spawnPoint + SCNVector3(0, cubeSizeSmall/2, 0)
        break
    case 2: cubeSize = Float(cubeSizeLarge)
    spawnPoint = spawnPoint + SCNVector3(0, cubeSizeLarge/2, 0)
        break
    default: cubeSize = 0.2
        break
    }
    
    objectNode.position = spawnPoint
    
    boxNode.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let boxNodeGeometry = boxNode.geometry as! SCNBox
    
    //set the dimensions of the box
    boxNodeGeometry.width = CGFloat(cubeSize)
    boxNodeGeometry.height = CGFloat(cubeSize)
    boxNodeGeometry.length = CGFloat(cubeSize)
    
    boxNode.position = SCNVector3Zero
    
    

    boxNode.opacity = CGFloat(objectOpacity)
    

    // create guiding line around object
    // create four guide boxes, so that they form a ring, not a solid plane
    let guideNode1 = SCNNode()
    let guideNode2 = SCNNode()
    let guideNode3 = SCNNode()
    let guideNode4 = SCNNode()
    guideNode1.name = "currentStudyObjectGuideNode"
    guideNode2.name = "currentStudyObjectGuideNode"
    guideNode3.name = "currentStudyObjectGuideNode"
    guideNode4.name = "currentStudyObjectGuideNode"
    objectNode.addChildNode(guideNode1)
    objectNode.addChildNode(guideNode2)
    objectNode.addChildNode(guideNode3)
    objectNode.addChildNode(guideNode4)
    
    guideNode1.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let guideNodeGeometry1 = guideNode1.geometry as! SCNBox
    guideNode2.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let guideNodeGeometry2 = guideNode2.geometry as! SCNBox
    guideNode3.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let guideNodeGeometry3 = guideNode3.geometry as! SCNBox
    guideNode4.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let guideNodeGeometry4 = guideNode4.geometry as! SCNBox

    let guideSize = cubeSize * 1.001
    
    // 1 = Top, 2 = Back, 3 = Bottom, 4 = Front
    guideNode1.position = SCNVector3(cubeSize/2, cubeSize/2, 0)
    guideNode2.position = SCNVector3(cubeSize/2, 0, cubeSize/2)
    guideNode3.position = SCNVector3(cubeSize/2, -cubeSize/2, 0)
    guideNode4.position = SCNVector3(cubeSize/2, 0, -cubeSize/2)
    
    //set the dimensions of the boxes
    guideNodeGeometry1.width = CGFloat(0.0005)
    guideNodeGeometry1.height = CGFloat(0.0005)
    guideNodeGeometry1.length = CGFloat(guideSize)
    guideNodeGeometry2.width = CGFloat(0.0005)
    guideNodeGeometry2.height = CGFloat(guideSize)
    guideNodeGeometry2.length = CGFloat(0.0005)
    guideNodeGeometry3.width = CGFloat(0.0005)
    guideNodeGeometry3.height = CGFloat(0.0005)
    guideNodeGeometry3.length = CGFloat(guideSize)
    guideNodeGeometry4.width = CGFloat(0.0005)
    guideNodeGeometry4.height = CGFloat(guideSize)
    guideNodeGeometry4.length = CGFloat(0.0005)
    
    guideNodeGeometry1.materials.first?.diffuse.contents = UIColor.red
    guideNodeGeometry2.materials.first?.diffuse.contents = UIColor.red
    guideNodeGeometry3.materials.first?.diffuse.contents = UIColor.red
    guideNodeGeometry4.materials.first?.diffuse.contents = UIColor.red
    
    // Add starting point and draw direction signifiers
    let startPointNode = SCNNode()
    startPointNode.name = "currentStudyObjectStartingPointNode"
    objectNode.addChildNode(startPointNode)
    startPointNode.geometry = SCNSphere.init(radius: 0.002)
    let startPointGeometry = startPointNode.geometry as! SCNSphere
    startPointGeometry.materials.first?.diffuse.contents = UIColor.red
    startPointNode.position = SCNVector3(cubeSize/2, -cubeSize/2, cubeSize/2)
    
    
    let directionArrowNode = SCNNode()
    directionArrowNode.name = "currentStudyObjectDirectionArrowNode"
    objectNode.addChildNode(directionArrowNode)
    directionArrowNode.geometry = SCNCone.init(topRadius: 0, bottomRadius: 0.0035, height: 0.008)
    let directionArrowGeometry = directionArrowNode.geometry as! SCNCone
    directionArrowGeometry.materials.first?.diffuse.contents = UIColor.red
    directionArrowNode.position = SCNVector3(cubeSize/2, 0, cubeSize/2)
    directionArrowNode.eulerAngles = SCNVector3(0, 0, 0)
    
    
    
    
    return objectNode
}

func createCubeFlatFrontSide(size: Int, startingPoint: SCNVector3, scene: PenScene)->SCNNode{
    
    let objectNode = SCNNode()
    objectNode.name = "currentStudyObjectNode"
    let boxNode = SCNNode()
    boxNode.name = "currentStudyObjectBoxNode"
    scene.drawingNode.addChildNode(objectNode)
    objectNode.addChildNode(boxNode)
    
    var spawnPoint = startingPoint
    
    var cubeSize: Float
    switch size{
    case 1: cubeSize = Float(cubeSizeSmall)
    spawnPoint = spawnPoint + SCNVector3(0, cubeSizeSmall/2, 0)
        break
    case 2: cubeSize = Float(cubeSizeLarge)
    spawnPoint = spawnPoint + SCNVector3(0, cubeSizeLarge/2, 0)
        break
    default: cubeSize = 0.2
        break
    }
    
    objectNode.position = spawnPoint
    
    boxNode.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let boxNodeGeometry = boxNode.geometry as! SCNBox
    
    //set the dimensions of the box
    boxNodeGeometry.width = CGFloat(cubeSize)
    boxNodeGeometry.height = CGFloat(cubeSize)
    boxNodeGeometry.length = CGFloat(cubeSize)
    
    boxNode.position = SCNVector3Zero
    
    

    boxNode.opacity = CGFloat(objectOpacity)
    

    // create guiding line around object
    // create four guide boxes, so that they form a ring, not a solid plane
    let guideNode1 = SCNNode()
    let guideNode2 = SCNNode()
    let guideNode3 = SCNNode()
    let guideNode4 = SCNNode()
    guideNode1.name = "currentStudyObjectGuideNode"
    guideNode2.name = "currentStudyObjectGuideNode"
    guideNode3.name = "currentStudyObjectGuideNode"
    guideNode4.name = "currentStudyObjectGuideNode"
    objectNode.addChildNode(guideNode1)
    objectNode.addChildNode(guideNode2)
    objectNode.addChildNode(guideNode3)
    objectNode.addChildNode(guideNode4)
    
    guideNode1.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let guideNodeGeometry1 = guideNode1.geometry as! SCNBox
    guideNode2.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let guideNodeGeometry2 = guideNode2.geometry as! SCNBox
    guideNode3.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let guideNodeGeometry3 = guideNode3.geometry as! SCNBox
    guideNode4.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let guideNodeGeometry4 = guideNode4.geometry as! SCNBox

    let guideSize = cubeSize * 1.001
    
    // 1 = Top, 2 = Right, 3 = Bottom, 4 = Left
    guideNode1.position = SCNVector3(0, cubeSize/2, cubeSize/2)
    guideNode2.position = SCNVector3(cubeSize/2, 0, cubeSize/2)
    guideNode3.position = SCNVector3(0, -cubeSize/2, cubeSize/2)
    guideNode4.position = SCNVector3(-cubeSize/2, 0, cubeSize/2)
    
    //set the dimensions of the boxes
    guideNodeGeometry1.width = CGFloat(guideSize)
    guideNodeGeometry1.height = CGFloat(0.0005)
    guideNodeGeometry1.length = CGFloat(0.0005)
    guideNodeGeometry2.width = CGFloat(0.0005)
    guideNodeGeometry2.height = CGFloat(guideSize)
    guideNodeGeometry2.length = CGFloat(0.0005)
    guideNodeGeometry3.width = CGFloat(guideSize)
    guideNodeGeometry3.height = CGFloat(0.0005)
    guideNodeGeometry3.length = CGFloat(0.0005)
    guideNodeGeometry4.width = CGFloat(0.0005)
    guideNodeGeometry4.height = CGFloat(guideSize)
    guideNodeGeometry4.length = CGFloat(0.0005)
    
    guideNodeGeometry1.materials.first?.diffuse.contents = UIColor.red
    guideNodeGeometry2.materials.first?.diffuse.contents = UIColor.red
    guideNodeGeometry3.materials.first?.diffuse.contents = UIColor.red
    guideNodeGeometry4.materials.first?.diffuse.contents = UIColor.red
    
    // Add starting point and draw direction signifiers
    let startPointNode = SCNNode()
    startPointNode.name = "currentStudyObjectStartingPointNode"
    objectNode.addChildNode(startPointNode)
    startPointNode.geometry = SCNSphere.init(radius: 0.002)
    let startPointGeometry = startPointNode.geometry as! SCNSphere
    startPointGeometry.materials.first?.diffuse.contents = UIColor.red
    startPointNode.position = SCNVector3(-cubeSize/2, cubeSize/2, cubeSize/2)
    
    
    let directionArrowNode = SCNNode()
    directionArrowNode.name = "currentStudyObjectDirectionArrowNode"
    objectNode.addChildNode(directionArrowNode)
    directionArrowNode.geometry = SCNCone.init(topRadius: 0, bottomRadius: 0.0035, height: 0.008)
    let directionArrowGeometry = directionArrowNode.geometry as! SCNCone
    directionArrowGeometry.materials.first?.diffuse.contents = UIColor.red
    directionArrowNode.position = SCNVector3(0, cubeSize/2, cubeSize/2)
    directionArrowNode.eulerAngles = SCNVector3(0, 0, -Float.pi/2)
    
    
    
    
    return objectNode
}


}

