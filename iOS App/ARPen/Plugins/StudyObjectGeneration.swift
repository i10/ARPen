//
//  StudyObjectGeneration.swift
//  ARPen
//
//  Created by Martin on 09.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

//include the UserStudyRecordPluginProtocol to demo recording of user study data
class StudyObjectGeneration: Plugin, UserStudyRecordPluginProtocol {
    //reference to userStudyRecordManager to add new records
    var recordManager: UserStudyRecordManager!
    
    var pluginImage : UIImage? = UIImage.init(named: "CubeByDraggingPlugin")
    var pluginInstructionsImage: UIImage? = UIImage.init(named: "CubePluginInstructions")
    var pluginIdentifier: String = "StudyObjectCreator"
    var needsBluetoothARPen: Bool = false
    var pluginDisabledImage: UIImage? = UIImage.init(named: "ARMenusPluginDisabled")
    var currentScene : PenScene?
    var currentView: ARSCNView?
    
    var objectCounter: Int = 0
    var objectCurrentlyBuilding: Bool = false
    
    let objectOpacity = 0.4
    
    let cubeSizeSmall = 0.05
    let cubeSizeLarge = 0.2
    
    // trial data
    var userID = 5
    var trialNumber = 0
    
    /**
     The starting point is the point of the pencil where the button was first pressed.
     If this var is nil, there was no initial point
     */
    private var startingPoint: SCNVector3?
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        guard scene.markerFound else {
            //Don't reset the previous point to avoid restarting cube if the marker detection failed for some frames
            //self.startingPoint = nil
            return
        }
        
        
    
        //Check state of the first button -> used to create the cube
        let pressed = buttons[Button.Button1]!
        
        //if the button is pressed -> either set the starting point of the cube (first action) or scale the cube to fit from the starting point to the current point
        if pressed {
            if let startingPoint = self.startingPoint {
                //see if there is an active box node that is currently being drawn. Otherwise create it
                
                
                var spawnPoint = scene.pencilPoint.position
                
                // if no object exists: create new object
                if !objectCurrentlyBuilding{
                    // object exists already: delete it and create new object
                    
                    if let objectNode = scene.drawingNode.childNode(withName: "currentStudyObjectNode", recursively: false){
                        for obj in objectNode.childNodes{
                            obj.removeFromParentNode()
                        }
                        objectNode.removeFromParentNode()
                    }
                    
                    
                    if let objectNode = scene.drawingNode.childNode(withName: "currentStudyObjectBoxNode", recursively: false){
                        for obj in objectNode.childNodes{
                            obj.removeFromParentNode()
                        }
                        objectNode.removeFromParentNode()
                    }
                    
                    if let objectNode = scene.drawingNode.childNode(withName: "currentStudyObjectSphereNode", recursively: false){
                        for obj in objectNode.childNodes{
                            obj.removeFromParentNode()
                        }
                        objectNode.removeFromParentNode()
                    }
                    
                    if let objectNode = scene.drawingNode.childNode(withName: "currentStudyObjectGuideNode", recursively: false){
                        for obj in objectNode.childNodes{
                            obj.removeFromParentNode()
                        }
                        objectNode.removeFromParentNode()
                    }
                    
                    // whether previous object existed or not, create new one
                    switch objectCounter {
                    case 0:
                        // flat corner small
                        let objectNode = generateObject(size: 1, shape: 1, corner: 3, startingPoint: spawnPoint, scene: scene)
                        break
                    case 1:
                    // flat corner large
                        let objectNode = generateObject(size: 2, shape: 1, corner: 3, startingPoint: spawnPoint, scene: scene)
                        break
                    case 2:
                    // exterior corner small
                        let objectNode = generateObject(size: 1, shape: 1, corner: 1, startingPoint: spawnPoint, scene: scene)
                        break
                    case 3:
                    // exterior corner large
                        let objectNode = generateObject(size: 2, shape: 1, corner: 1, startingPoint: spawnPoint, scene: scene)
                        break
                    case 4:
                    // interior corner small
                        let objectNode = generateObject(size: 1, shape: 1, corner: 2, startingPoint: spawnPoint, scene: scene)
                        break
                    default:
                    // interior corner large
                        let objectNode = generateObject(size: 2, shape: 1, corner: 2, startingPoint: spawnPoint, scene: scene)
                        break
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
                //self.startingPoint = scene.pencilPoint.position
                self.startingPoint = SCNVector3Zero
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
    
    func getTrialNumber()->Int{
        return trialNumber
    }
    
    func getUserID()->Int{
        return userID
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentScene = scene
        self.currentView = view
    }
    
    func deactivatePlugin() {
        self.currentScene = nil
        self.currentView = nil
    }
    



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
    scene.drawingNode.addChildNode(objectNode)
    objectNode.addChildNode(boxNode)
    
    
    objectNode.position = startingPoint
    
    var cubeSize: Float
    switch size{
    case 1: cubeSize = Float(cubeSizeSmall)
        break
    case 2: cubeSize = Float(cubeSizeLarge)
        break
    default: cubeSize = 0.2
        break
    }
    
    boxNode.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let boxNodeGeometry = boxNode.geometry as! SCNBox
    
    //set the dimensions of the box
    boxNodeGeometry.width = CGFloat(cubeSize)
    boxNodeGeometry.height = CGFloat(cubeSize)
    boxNodeGeometry.length = CGFloat(cubeSize)
    
    boxNode.position = SCNVector3Zero
    
    
    
    
    // create guiding line around object
    let guideNode = SCNNode()
    guideNode.name = "currentStudyObjectGuideNode"
    objectNode.addChildNode(guideNode)
    
    guideNode.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let guideNodeGeometry = guideNode.geometry as! SCNBox


    cubeSize = cubeSize * 1.001
    
    guideNode.position = SCNVector3(0, cubeSize/2, 0)
    
    

    //set the dimensions of the box
    guideNodeGeometry.width = CGFloat(cubeSize)
    guideNodeGeometry.height = CGFloat(0.0005)
    guideNodeGeometry.length = CGFloat(cubeSize)
              
//    switch direction{
//    // horizontal
//    case 1:
//
//        //set the dimensions of the box
//        guideNodeGeometry.width = CGFloat(cubeSize)
//        guideNodeGeometry.height = CGFloat(0.0005)
//        guideNodeGeometry.length = CGFloat(cubeSize)
//
//        break
//    // vertical
//    case 2:
//
//        guideNodeGeometry.width = CGFloat(0.0005)
//        guideNodeGeometry.height = CGFloat(cubeSize)
//        guideNodeGeometry.length = CGFloat(cubeSize)
//
//        break
//    // diagonal
//    case 3:
//
//        guideNodeGeometry.width = CGFloat(cubeSize)
//        guideNodeGeometry.height = CGFloat(cubeSize)
//        guideNodeGeometry.length = CGFloat(cubeSize)
//
//        break
//    default:
//
//
//        guideNodeGeometry.width = CGFloat(cubeSize)
//        guideNodeGeometry.height = CGFloat(cubeSize)
//        guideNodeGeometry.length = CGFloat(cubeSize)
//
//        break
//    }
    
    guideNodeGeometry.materials.first?.diffuse.contents = UIColor.red
    

    boxNode.opacity = CGFloat(objectOpacity)
    
    return objectNode
}


func createCubeInterior(size: Int, startingPoint: SCNVector3, scene: PenScene)->SCNNode{
    
    let objectNode = SCNNode()
    objectNode.name = "currentStudyObjectNode"
    let boxNode = SCNNode()
    boxNode.name = "currentStudyObjectBoxNode"
    scene.drawingNode.addChildNode(objectNode)
    objectNode.addChildNode(boxNode)
    
    objectNode.position = startingPoint
    
    var cubeSize: Float
    switch size{
    case 1: cubeSize = Float(cubeSizeSmall)
        break
    case 2: cubeSize = Float(cubeSizeLarge)
        break
    default: cubeSize = 0.2
        break
    }
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
    
    baseNodeGeometry.width = CGFloat(cubeSize * 3)
    baseNodeGeometry.height = CGFloat(0.001)
    baseNodeGeometry.length = CGFloat(cubeSize * 3)
    
//    baseNode.position = SCNVector3(0, -0.5 * cubeSize, 0)
    baseNode.position = SCNVector3Zero

    // create guiding line around object
    let guideNode = SCNNode()
    guideNode.name = "currentStudyObjectGuideNode"
    objectNode.addChildNode(guideNode)
    
    cubeSize = cubeSize * 1.001
    
    guideNode.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let guideNodeGeometry = guideNode.geometry as! SCNBox
    
    guideNodeGeometry.width = CGFloat(cubeSize)
    guideNodeGeometry.height = CGFloat(0.0005)
    guideNodeGeometry.length = CGFloat(cubeSize)
    guideNodeGeometry.materials.first?.diffuse.contents = UIColor.red
    

   // guideNode.position = SCNVector3(0, -0.5 * cubeSize, 0)
    guideNode.position = SCNVector3Zero
    
    boxNode.opacity = CGFloat(objectOpacity)
    //baseNode.opacity = CGFloat(objectOpacity)
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
    
    objectNode.position = startingPoint
    
    
    var cubeSize: Float
    switch size{
    case 1: cubeSize = Float(cubeSizeSmall)
        break
    case 2: cubeSize = Float(cubeSizeLarge)
        break
    default: cubeSize = 0.2
        break
    }
    
    boxNode.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let boxNodeGeometry = boxNode.geometry as! SCNBox
    
    //set the dimensions of the box
    boxNodeGeometry.width = CGFloat(cubeSize)
    boxNodeGeometry.height = CGFloat(cubeSize)
    boxNodeGeometry.length = CGFloat(cubeSize)
    
    boxNode.position = SCNVector3Zero
    
    // create guiding line around object
    let guideNode = SCNNode()
    guideNode.name = "currentStudyObjectGuideNode"
    objectNode.addChildNode(guideNode)
    
    cubeSize = cubeSize * 1.001
    
    guideNode.geometry = SCNBox.init(width: CGFloat(cubeSize), height: CGFloat(cubeSize), length: CGFloat(cubeSize), chamferRadius: 0.0)
    let guideNodeGeometry = guideNode.geometry as! SCNBox
    
    
    guideNode.position = SCNVector3Zero
    

    //set the dimensions of the box
    guideNodeGeometry.width = CGFloat(cubeSize)
    guideNodeGeometry.height = CGFloat(0.0005)
    guideNodeGeometry.length = CGFloat(cubeSize)
    
//    switch direction{
//    // horizontal
//    case 1:
//
//        //set the dimensions of the box
//        guideNodeGeometry.width = CGFloat(cubeSize)
//        guideNodeGeometry.height = CGFloat(0.0005)
//        guideNodeGeometry.length = CGFloat(0.0005)
//
//        break
//    // vertical
//    case 2:
//
//        guideNodeGeometry.width = CGFloat(0.0005)
//        guideNodeGeometry.height = CGFloat(0.0005)
//        guideNodeGeometry.length = CGFloat(cubeSize)
//
//        break
//    // diagonal
//    case 3:
//
//        guideNodeGeometry.width = CGFloat(cubeSize)
//        guideNodeGeometry.height = CGFloat(0.0005)
//        guideNodeGeometry.length = CGFloat(cubeSize)
//
//        break
//    default:
//
//
//        guideNodeGeometry.width = CGFloat(cubeSize)
//        guideNodeGeometry.height = CGFloat(0.0005)
//        guideNodeGeometry.length = CGFloat(cubeSize)
//
//        break
//    }
    guideNodeGeometry.materials.first?.diffuse.contents = UIColor.red
    

    boxNode.opacity = CGFloat(objectOpacity)
    
    return objectNode}


//func createSphereInterior(size: Int, startingPoint: SCNVector3, scene: PenScene)->SCNNode{
//    let objectNode = SCNNode()
//    objectNode.name = "currentStudyObjectNode"
//    let sphereNode = SCNNode()
//    sphereNode.name = "currentStudyObjectSphereNode"
//    scene.drawingNode.addChildNode(objectNode)
//    objectNode.addChildNode(sphereNode)
//
//    objectNode.position = scene.pencilPoint.position
//
//    var sphereSize: Float
//    switch size{
//    case 1: sphereSize = 0.1
//        break
//    case 2: sphereSize = 0.5
//        break
//    default: sphereSize = 0.2
//        break
//    }
//
//    sphereSize = sphereSize / 2
//    // create sphere itself
//    sphereNode.geometry = SCNSphere.init(radius: CGFloat(sphereSize))
//    let sphereNodeGeometry = sphereNode.geometry as! SCNSphere
//
//    sphereNodeGeometry.radius = CGFloat(sphereSize)
//
//    sphereNode.position = SCNVector3Zero
//
//    // create "base"
//    let baseNode = SCNNode()
//    baseNode.name = "currentStudyObjectBoxNode"
//    objectNode.addChildNode(baseNode)
//
//    baseNode.geometry = SCNBox.init(width: CGFloat(sphereSize), height: CGFloat(sphereSize), length: CGFloat(sphereSize), chamferRadius: 0.0)
//    let baseNodeGeometry = baseNode.geometry as! SCNBox
//
//    baseNodeGeometry.width = CGFloat(sphereSize * 3)
//    baseNodeGeometry.height = CGFloat(0.001)
//    baseNodeGeometry.length = CGFloat(sphereSize * 3)
//
//    baseNode.position = SCNVector3Zero
//
//    // create guiding line around object
//    let guideNode = SCNNode()
//    guideNode.name = "currentStudyObjectGuideNode"
//    objectNode.addChildNode(guideNode)
//
//    sphereSize = sphereSize * 1.001
//
//    guideNode.geometry = SCNCylinder.init(radius: CGFloat(sphereSize), height: 0.0005)
//    let guideNodeGeometry = guideNode.geometry as! SCNCylinder
//
//    guideNodeGeometry.radius = CGFloat(sphereSize)
//    guideNodeGeometry.height = CGFloat(0.0005)
//    guideNodeGeometry.materials.first?.diffuse.contents = UIColor.red
//
//
//    guideNode.position = SCNVector3(0, 0, 0)
//
//    sphereNode.opacity = CGFloat(objectOpacity)
//    baseNode.opacity = CGFloat(objectOpacity)
//
//    return objectNode
//}


//func createSphereExterior(size: Int, startingPoint: SCNVector3, scene: PenScene)->SCNNode{
//    let objectNode = SCNNode()
//    objectNode.name = "currentStudyObjectNode"
//    let sphereNode = SCNNode()
//    sphereNode.name = "currentStudyObjectSphereNode"
//    scene.drawingNode.addChildNode(objectNode)
//    objectNode.addChildNode(sphereNode)
//
//    objectNode.position = scene.pencilPoint.position
//
//    var sphereSize: Float
//    switch size{
//    case 1: sphereSize = 0.1
//        break
//    case 2: sphereSize = 0.5
//        break
//    default: sphereSize = 0.2
//        break
//    }
//    sphereSize = sphereSize / 2
//    // create sphere itself
//    sphereNode.geometry = SCNSphere.init(radius: CGFloat(sphereSize))
//    let sphereNodeGeometry = sphereNode.geometry as! SCNSphere
//
//    sphereNodeGeometry.radius = CGFloat(sphereSize)
//
//    sphereNode.position = SCNVector3Zero
//
//    // create guiding line around object
//    let guideNode = SCNNode()
//    guideNode.name = "currentStudyObjectGuideNode"
//    objectNode.addChildNode(guideNode)
//
//    sphereSize = sphereSize * 1.001
//
//    guideNode.geometry = SCNCylinder.init(radius: CGFloat(sphereSize), height: 0.0005)
//    let guideNodeGeometry = guideNode.geometry as! SCNCylinder
//
//    guideNodeGeometry.radius = CGFloat(sphereSize)
//    guideNodeGeometry.height = CGFloat(0.0005)
//    guideNodeGeometry.materials.first?.diffuse.contents = UIColor.red
//
//    guideNode.position = SCNVector3(0, 0, 0)
//
//    sphereNode.opacity = CGFloat(objectOpacity)
//
//    return objectNode
//}

}
