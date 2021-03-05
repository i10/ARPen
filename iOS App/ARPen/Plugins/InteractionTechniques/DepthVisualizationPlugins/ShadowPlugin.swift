
import Foundation
import ARKit
import SpriteKit

class ShadowPlugin: MinVisPlugin {
    
    var gridPlane : SCNNode?
    
    override init(){
        super.init()
        self.pluginIdentifier = "Shadow"
        self.pluginGroupName = "Depth Visualization"
        self.pluginImage = UIImage.init(named: "DepthVisualizationShadowPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "DepthVisualizationShadowInstructions")
        self.isExperimentalPlugin = true
        
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        
        super.didUpdateFrame(scene: scene, buttons: buttons)
        
        self.gridPlane?.worldPosition.y = (scene.rootNode.childNode(withName: "iDevice Camera", recursively: false)?.worldPosition.y ?? 0.0) - 0.1
        
        if self.helpActive {
            if self.gridPlane?.parent == nil{
                self.studySceneConstruction?.superNode.addChildNode(self.gridPlane!)
            }
        } else {
            self.gridPlane?.removeFromParentNode()
        }
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        
        let lightNode = SCNNode()
        lightNode.name = "topLight"
        lightNode.eulerAngles = SCNVector3Make(Float.pi * 1.5, 0, 0);
        
        lightNode.light = SCNLight()
        lightNode.light?.type = .directional
        lightNode.light?.color = UIColor.white
        
        // scene distances are rather small
        lightNode.light?.zNear = 0.01
        lightNode.light?.zFar = 0.5
        
        // casting shadows in 90° angle produces artifacts, ramping up shadow samples "fixes" it
        lightNode.light?.castsShadow = true
        lightNode.light?.shadowRadius = 1.0
        lightNode.light?.shadowSampleCount = 16
        
        self.currentScene?.drawingNode.addChildNode(lightNode)
        
        
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
        
        var gridPlane = SCNNode()
        gridPlane = SCNNode.init(geometry: SCNPlane(width: 1, height: 1))
        gridPlane.name = "gridPlane"
        gridPlane.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        gridPlane.geometry?.firstMaterial?.transparency = 0.75
        gridPlane.position = SCNVector3((minX + maxX) / 2.0, (minY + maxY) / 2.0, (minZ + maxZ) / 2.0)
        gridPlane.rotation = SCNVector4(1, 0, 0, -0.5 * Double.pi)
        self.studySceneConstruction?.superNode.addChildNode(gridPlane)
        self.gridPlane = gridPlane
    }
    
    override func deactivatePlugin() {
        self.currentScene?.drawingNode.childNode(withName: "topLight", recursively: false)?.removeFromParentNode()
        
        super.deactivatePlugin()
    }
    
}
