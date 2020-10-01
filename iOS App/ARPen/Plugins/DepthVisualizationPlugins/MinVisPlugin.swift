
import Foundation
import ARKit

class MinVisPlugin: Plugin, UserStudyRecordPluginProtocol {
    
    var recordManager: UserStudyRecordManager!
    
    static var nodeType : ARPenStudyNode.Type = ARPenWireBoxNode.self
    
    var studySceneConstruction : (superNode: SCNNode, studyNodes: [ARPenStudyNode])?
    
    var targetPosition : SCNVector3?
    
    private var previousPoint: SCNVector3?
    private var currentLine : [SCNNode]?
    
    private var nextSceneAligned = true //set to true for demo purpose. Only used in study settings.
//    //only needed for study settings
//    private var backAlignmentTarget : SCNNode?
//    private var frontAlignmentTarget : SCNNode?
    
    private var trialNum : Int = -1
    private var trialRedo : Int = 0
    private var trialRedoOngoing : Bool = false
    
    var helpActive : Bool = false
    var button2WasPressed : Bool = false
    
    var testRun : Bool = true
    
    let LINE_NAME = "drawnLine"
    
    override init() {
        super.init()
        
        self.pluginImage = UIImage.init(named: "SonarPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "None")
        self.pluginIdentifier = "MinVis"
        self.pluginGroupName = "Depth Visualization"
        self.needsBluetoothARPen = false
        
        nibNameOfCustomUIView = "SecondButton"
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        
        guard self.recordManager != nil else {return}
        
        if (self.recordManager.currentActiveUserID != nil) {
            if (!testRun && self.nextSceneAligned) {
                self.recordManager.addNewRecord(withIdentifier: String(describing: type(of: self)), andData: [
                    "timestamp" : "\(Date().millisecondsSince1970)",
                    "penVisible" : scene.markerFound ? "true" : "false",
                    "trial" : "\(self.trialNum)",
                    "trialRedo" : self.trialRedoOngoing ? "\(self.trialRedo)" : "0",
                    "boxtype" : MinVisPlugin.nodeType == ARPenWireBoxNode.self ? "wire" : "full",
                    "targetX" : "\(targetPosition!.x)",
                    "targetY" : "\(targetPosition!.y)",
                    "targetZ" : "\(targetPosition!.z)",
                    "penX" : "\(scene.pencilPoint.worldPosition.x)",
                    "penY" : "\(scene.pencilPoint.worldPosition.y)",
                    "penZ" : "\(scene.pencilPoint.worldPosition.z)",
                    "helpButtonActive" : buttons[Button.Button2]! ? "true" : "false",
                    "lineButtonActive" : buttons[Button.Button1]! ? "true" : "false",
                    "helpActive" : helpActive ? "true" : "false"
                    ])
            }
        } else {
            // for review testing disable the need to log information
            //return
        }
        
        //only needed in study setting (to align scene&pen)
//        if let arSceneView = self.currentView {
//            let projectedAlignmentPosition = arSceneView.projectPoint(frontAlignmentTarget?.worldPosition ?? SCNVector3(0,0,0))
//            let projectedCGPoint = CGPoint(x: CGFloat(projectedAlignmentPosition.x), y: CGFloat(projectedAlignmentPosition.y))
//            let hitResults = arSceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
//
//            if hitResults.filter({$0.node.name == "backAlignmentTarget"}).count > 0 && scene.markerFound {
//                self.nextSceneAligned = true
//                backAlignmentTarget?.removeFromParentNode()
//                frontAlignmentTarget?.removeFromParentNode()
//            }
//        }
        
        let pressed = buttons[Button.Button1]!
        
        if self.nextSceneAligned || self.currentLine != nil {
            if pressed, let previousPoint = self.previousPoint {
                if self.currentLine == nil {
                    self.currentLine = [SCNNode]()
                }
                let cylinderNode = SCNNode()
                cylinderNode.buildLineInTwoPointsWithRotation(from: previousPoint, to: scene.pencilPoint.position, radius: 0.001, color: UIColor.orange)
                cylinderNode.name = LINE_NAME
                scene.drawingNode.addChildNode(cylinderNode)
                self.currentLine?.append(cylinderNode)
                //self.nextSceneAligned = false
            } else if !pressed {
                if self.currentLine != nil {
                    self.currentLine = nil
                    
                    scene.drawingNode.childNodes.filter({$0.name == LINE_NAME}).forEach({
                        $0.removeFromParentNode()
                    })
                    
                    self.calculateNextTarget()
                    self.trialRedoOngoing = false
                }
            }
        }
        
        
        let pressed2 = buttons[Button.Button2]!
        if pressed2 {
            if !self.button2WasPressed {
                self.button2WasPressed = true
                self.helpActive = !self.helpActive
            }
        } else {
            self.button2WasPressed = false
        }
        
        
        self.previousPoint = scene.pencilPoint.position
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView){
        super.activatePlugin(withScene: scene, andView: view)
        
        if (MinVisPlugin.nodeType == ARPenWireBoxNode.self) {
            MinVisPlugin.nodeType = ARPenBoxNode.self
        } else {
            MinVisPlugin.nodeType = ARPenWireBoxNode.self
        }
        
        self.constructStudyScene()
        self.calculateNextTarget()
        self.stopStudy()
    }
    
    override func deactivatePlugin() {
        self.stopStudy()
        
        if let studySceneConstruction = self.studySceneConstruction {
            studySceneConstruction.superNode.removeFromParentNode()
            self.studySceneConstruction = nil
        }
        
        self.currentScene?.drawingNode.childNodes.filter({$0.name == LINE_NAME}).forEach({
            $0.removeFromParentNode()
        })
        
        self.currentView?.superview?.layer.borderWidth = 0.0
        super.deactivatePlugin()
    }
    
    func constructStudyScene() {
        //print("CONSTRUCT SCENE")
        let sceneConstructor = ARPenGridSceneConstructor.init()
        self.studySceneConstruction = sceneConstructor.preparedARPenNodes(withScene: self.currentScene!, andView: self.currentView!, andStudyNodeType: MinVisPlugin.nodeType)
        //remove image alignment for review
        //self.studySceneConstruction!.superNode.position = SCNVector3(0,0,0)
        self.currentScene?.drawingNode.addChildNode(self.studySceneConstruction!.superNode)
    }
    
    func calculateNextTarget() {
        
        self.helpActive = false
        
        self.trialNum += 1
        
        if (self.trialNum > 15) {
            self.stopStudy()
        }
        
        if (self.trialNum < 0) {
            self.trialNum = 0
        }
        
        let nodeCap = 8
        var minX = Float.infinity
        var maxX = -Float.infinity
        var minY = Float.infinity
        var maxY = -Float.infinity
        var minZ = Float.infinity
        var maxZ = -Float.infinity
        
        self.studySceneConstruction?.superNode.childNodes.forEach({
            if ($0.position.x < minX) {
                minX = $0.position.x
            } else if ($0.position.x > maxX) {
                maxX = $0.position.x
            }
            
            if ($0.position.y < minY) {
                minY = $0.position.y
            } else if ($0.position.y > maxY) {
                maxY = $0.position.y
            }
            
            if ($0.position.z < minZ) {
                minZ = $0.position.z
            } else if ($0.position.z > maxZ) {
                maxZ = $0.position.z
            }
        })
        
        self.studySceneConstruction?.studyNodes.forEach({
            $0.isActiveTarget = false
            $0.highlighted = true
        })
        
        self.studySceneConstruction?.superNode.childNodes.filter({$0.name == "testBlob"}).forEach({
            $0.removeFromParentNode()
        })
        
        var studyNodes = self.studySceneConstruction?.studyNodes.shuffled() ?? [];
        
        while !(studyNodes.prefix(nodeCap).contains(self.studySceneConstruction!.studyNodes[trialNum])) {
            studyNodes = self.studySceneConstruction?.studyNodes.shuffled() ?? [];
        }
        
        for studyNode in studyNodes {
            studyNode.removeFromParentNode()
        }
        
        for studyNode in studyNodes.prefix(nodeCap) {
            self.studySceneConstruction?.superNode.addChildNode(studyNode)
        }
        
        if let randomStudyNode = self.studySceneConstruction?.studyNodes[trialNum] {
            
            var possibleFacesToTest = ["front"]
            
            if (randomStudyNode.position.y < minY + (maxY - minY) / 3.0) {
                possibleFacesToTest.append("top")
            }
            
            if (randomStudyNode.position.y > minY + (maxY - minY) / 3.0 * 2.0) {
                possibleFacesToTest.append("bottom")
            }
            
            if (randomStudyNode.position.x < minX + (maxX - minX) / 3.0) {
                possibleFacesToTest.append("right")
            }
            
            if (randomStudyNode.position.x > minX + (maxX - minX) / 3.0 * 2.0) {
                possibleFacesToTest.append("left")
            }
            
            if let chosenFace = possibleFacesToTest.randomElement() {
                var firstPlaneVertex = SCNVector3(0.0, 0.0, 0.0)
                var secondPlaneVertex = SCNVector3(0.0, 0.0, 0.0)
                
                if chosenFace == "front" {
                    firstPlaneVertex = SCNVector3(randomStudyNode.position.x + randomStudyNode.dimension / 2.0, randomStudyNode.position.y + randomStudyNode.dimension / 2.0, randomStudyNode.position.z + randomStudyNode.dimension / 2.0)
                    secondPlaneVertex = SCNVector3(randomStudyNode.position.x - randomStudyNode.dimension / 2.0, randomStudyNode.position.y - randomStudyNode.dimension / 2.0, randomStudyNode.position.z + randomStudyNode.dimension / 2.0)
                }
                
                if chosenFace == "right" {
                    firstPlaneVertex = SCNVector3(randomStudyNode.position.x + randomStudyNode.dimension / 2.0, randomStudyNode.position.y + randomStudyNode.dimension / 2.0, randomStudyNode.position.z + randomStudyNode.dimension / 2.0)
                    secondPlaneVertex = SCNVector3(randomStudyNode.position.x + randomStudyNode.dimension / 2.0, randomStudyNode.position.y - randomStudyNode.dimension / 2.0, randomStudyNode.position.z - randomStudyNode.dimension / 2.0)
                }
                
                if chosenFace == "left" {
                    firstPlaneVertex = SCNVector3(randomStudyNode.position.x - randomStudyNode.dimension / 2.0, randomStudyNode.position.y + randomStudyNode.dimension / 2.0, randomStudyNode.position.z + randomStudyNode.dimension / 2.0)
                    secondPlaneVertex = SCNVector3(randomStudyNode.position.x - randomStudyNode.dimension / 2.0, randomStudyNode.position.y - randomStudyNode.dimension / 2.0, randomStudyNode.position.z - randomStudyNode.dimension / 2.0)
                }
                
                if chosenFace == "top" {
                    firstPlaneVertex = SCNVector3(randomStudyNode.position.x + randomStudyNode.dimension / 2.0, randomStudyNode.position.y + randomStudyNode.dimension / 2.0, randomStudyNode.position.z + randomStudyNode.dimension / 2.0)
                    secondPlaneVertex = SCNVector3(randomStudyNode.position.x - randomStudyNode.dimension / 2.0, randomStudyNode.position.y + randomStudyNode.dimension / 2.0, randomStudyNode.position.z - randomStudyNode.dimension / 2.0)
                }
                
                if chosenFace == "bottom" {
                    firstPlaneVertex = SCNVector3(randomStudyNode.position.x + randomStudyNode.dimension / 2.0, randomStudyNode.position.y - randomStudyNode.dimension / 2.0, randomStudyNode.position.z + randomStudyNode.dimension / 2.0)
                    secondPlaneVertex = SCNVector3(randomStudyNode.position.x - randomStudyNode.dimension / 2.0, randomStudyNode.position.y - randomStudyNode.dimension / 2.0, randomStudyNode.position.z - randomStudyNode.dimension / 2.0)
                }
                
                let directionVector = secondPlaneVertex - firstPlaneVertex
                
                var xFraction = Float.random(in: 0 ... 1)
                var yFraction = Float.random(in: 0 ... 1)
                var zFraction = Float.random(in: 0 ... 1)
                
                // if we have a wireframe box only mark the edges
                if randomStudyNode is ARPenWireBoxNode {
                    randomizerLoop : while (true) {
                        let randomVectorElement = Int.random(in: 0 ... 2)
                        let randomClampValue = Int.random(in: 0 ... 1)
                        
                        if (randomVectorElement == 0 && firstPlaneVertex.x != secondPlaneVertex.x) {
                            xFraction = Float(randomClampValue)
                            break randomizerLoop
                        }
                        
                        if (randomVectorElement == 1 && firstPlaneVertex.y != secondPlaneVertex.y) {
                            yFraction = Float(randomClampValue)
                            break randomizerLoop
                        }
                        
                        if (randomVectorElement == 2 && firstPlaneVertex.z != secondPlaneVertex.z) {
                            zFraction = Float(randomClampValue)
                            break randomizerLoop
                        }
                    }
                }
                
                randomStudyNode.isActiveTarget = true
                randomStudyNode.highlighted = true
                
                var targetBlob = SCNNode()
                targetBlob = SCNNode.init(geometry: SCNSphere.init(radius: 0.002))
                targetBlob.name = "testBlob"
                targetBlob.geometry?.firstMaterial?.diffuse.contents = UIColor.init(red: 0.7, green: 0.0, blue: 0.7, alpha: 1.0)
                targetBlob.geometry?.firstMaterial?.emission.contents = UIColor.blue
                targetBlob.position = SCNVector3(firstPlaneVertex.x + (directionVector.x) * xFraction, firstPlaneVertex.y + (directionVector.y) * yFraction, firstPlaneVertex.z + (directionVector.z) * zFraction)
                self.studySceneConstruction?.superNode.addChildNode(targetBlob)
                self.targetPosition = targetBlob.worldPosition
                
//                backAlignmentTarget?.removeFromParentNode()
//                frontAlignmentTarget?.removeFromParentNode()
                
//                var frontAlignmentTarget = SCNNode()
//                frontAlignmentTarget = SCNNode.init(geometry: SCNSphere.init(radius: 0.001))
//                frontAlignmentTarget.name = "frontAlignmentTarget"
//                frontAlignmentTarget.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
//                frontAlignmentTarget.geometry?.firstMaterial?.emission.contents = UIColor.yellow
//                frontAlignmentTarget.position = SCNVector3((minX + maxX) / 2.0, (minY + maxY) / 2.0, maxZ)
//                frontAlignmentTarget.renderingOrder = 20000
//                frontAlignmentTarget.geometry?.firstMaterial?.readsFromDepthBuffer = false
//                self.studySceneConstruction?.superNode.addChildNode(frontAlignmentTarget)
//                self.frontAlignmentTarget = frontAlignmentTarget
                
//                var backAlignmentTarget = SCNNode()
//                backAlignmentTarget = SCNNode.init(geometry: SCNSphere.init(radius: 0.005))
//                backAlignmentTarget.name = "backAlignmentTarget"
//                backAlignmentTarget.geometry?.firstMaterial?.diffuse.contents = UIColor.red
//                backAlignmentTarget.geometry?.firstMaterial?.emission.contents = UIColor.red
//                backAlignmentTarget.position = SCNVector3((minX + maxX) / 2.0, (minY + maxY) / 2.0, minZ)
//                backAlignmentTarget.renderingOrder = 19999
//                backAlignmentTarget.geometry?.firstMaterial?.readsFromDepthBuffer = false
//                self.studySceneConstruction?.superNode.addChildNode(backAlignmentTarget)
//                self.backAlignmentTarget = backAlignmentTarget
            }
        }
    }
    
    func startStudy() {
        if (self.testRun) {
            self.testRun = false
            self.trialNum = -1
            self.calculateNextTarget()
        } else {
            if self.nextSceneAligned {
                self.trialNum = max(self.trialNum - 1, -1)
            } else {
                self.trialNum = max(self.trialNum - 2, -1)
            }
            self.trialRedo = self.trialRedo + 1
            self.trialRedoOngoing = true
            self.calculateNextTarget()
        }
    }
    
    func stopStudy() {
        self.testRun = true
        self.trialNum = -1
    }
    
    @IBAction func secondSoftwareButtonPressed(_ sender: Any) {
        let buttonEventDict:[String: Any] = ["buttonPressed": Button.Button2, "buttonState" : true]
        NotificationCenter.default.post(name: .softwarePenButtonEvent, object: nil, userInfo: buttonEventDict)
    }
    
    @IBAction func secondSoftwareButtonReleased(_ sender: Any) {
        let buttonEventDict:[String: Any] = ["buttonPressed": Button.Button2, "buttonState" : false]
        NotificationCenter.default.post(name: .softwarePenButtonEvent, object: nil, userInfo: buttonEventDict)
    }
    
}
