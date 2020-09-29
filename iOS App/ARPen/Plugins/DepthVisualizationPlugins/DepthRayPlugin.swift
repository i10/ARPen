
import Foundation
import ARKit
import SpriteKit

class DepthRayPlugin: MinVisPlugin {
    
    var distanceLabel: SKLabelNode?
    
    private var sonarPoint: SCNVector3?
    
    private let testOffset : [(Float, Float)] = [(0, 2), (0, -2), (2, 0), (-2, 0), (0, 4), (0, -4), (4, 0), (-4, 0), (0, 6), (0, -6), (6, 0), (-6, 0), (0, 8), (0, -8), (8, 0), (-8, 0)]
    
    override init(){
        super.init()
        self.pluginIdentifier = "DepthRay"
        self.pluginGroupName = "Depth Visualization"
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        
        super.didUpdateFrame(scene: scene, buttons: buttons)
        
        if self.helpActive {
            if let arSceneView = self.currentView {
                let projectedPencilPosition = arSceneView.projectPoint(scene.pencilPoint.position)
                
                for index : Int in 0..<testOffset.count {
                    let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x + testOffset[index].0), y: CGFloat(projectedPencilPosition.y + testOffset[index].1))
                    let hitResults = arSceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
                    
                    if hitResults.filter({$0.node.name != "PencilPoint" && $0.node.name != "indicatorPlane" && !($0.node.name?.starts(with: "BoundingBox") ?? false)}).count > 0 {
                        scene.drawingNode.childNode(withName: "indicatorPlane", recursively: false)?.geometry?.firstMaterial?.transparency = 1.0
                    } else {
                        scene.drawingNode.childNode(withName: "indicatorPlane", recursively: false)?.geometry?.firstMaterial?.transparency = 0.0
                        continue
                    }
                    
                    let distanceInCM = ((hitResults.filter({$0.node.name != "PencilPoint" && $0.node.name != "indicatorPlane" && !($0.node.name?.starts(with: "BoundingBox") ?? false)}).first?.worldCoordinates.distance(vector: scene.pencilPoint.position)) ?? 0) * 100
                    self.distanceLabel?.text = String(format: "%.1f", distanceInCM)
                    
                    scene.drawingNode.childNode(withName: "indicatorPlane", recursively: false)?.position = scene.pencilPoint.position + SCNVector3(x: 0, y: 0.005, z: 0)
                    
                    break
                }
            }
        } else {
            scene.drawingNode.childNode(withName: "indicatorPlane", recursively: false)?.geometry?.firstMaterial?.transparency = 0.0
        }
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        super.activatePlugin(withScene: scene, andView: view)
        
        let renderToTextureScene = SKScene(size: CGSize(width: 2000, height: 250))
        renderToTextureScene.backgroundColor = UIColor.clear
        
        let indicatorBackground = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 2000, height: 250), cornerRadius: 10)
        indicatorBackground.fillColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        indicatorBackground.strokeColor = #colorLiteral(red: 0.3098039329, green: 0.2039215714, blue: 0.03921568766, alpha: 1)
        indicatorBackground.lineWidth = 10
        indicatorBackground.alpha = 0.4
        
        self.distanceLabel = SKLabelNode(text: "0")
        self.distanceLabel?.fontSize = 300
        self.distanceLabel?.fontName = "San Fransisco"
        self.distanceLabel?.position = CGPoint(x:1000,y:20)
        
        renderToTextureScene.addChild(indicatorBackground)
        renderToTextureScene.addChild(self.distanceLabel!)
        
        let indicatorPlane = SCNPlane(width: 0.02, height: 0.005)
        
        let renderToTextureMaterial = SCNMaterial()
        renderToTextureMaterial.isDoubleSided = false
        renderToTextureMaterial.diffuse.contents = renderToTextureScene
        renderToTextureMaterial.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        indicatorPlane.materials = [renderToTextureMaterial]
        
        let indicatorNode = SCNNode(geometry: indicatorPlane)
        indicatorNode.name = "indicatorPlane"
        indicatorNode.constraints = [SCNBillboardConstraint()]
        indicatorNode.renderingOrder = 19998
        indicatorNode.geometry?.firstMaterial?.readsFromDepthBuffer = false
        self.currentScene?.drawingNode.addChildNode(indicatorNode)
    }
    
    override func deactivatePlugin() {
        currentScene?.drawingNode.childNode(withName: "indicatorPlane", recursively: false)?.removeFromParentNode()
        
        super.deactivatePlugin()
    }
    
}



