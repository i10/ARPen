
import Foundation
import ARKit
import SpriteKit

class HeatmapPlugin: MinVisPlugin {
    
    private var sonarPoint: SCNVector3?
    
    override init(){
        super.init()
        self.pluginIdentifier = "Heatmap"
        self.pluginGroupName = "Depth Visualization"
        self.pluginImage = UIImage.init(named: "DepthVisualizationHeatmapPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "DepthVisualizationHeatmapInstructions")
        self.isExperimentalPlugin = true
        
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        
        super.didUpdateFrame(scene: scene, buttons: buttons)
        
        self.sonarPoint = scene.pencilPoint.worldPosition
        
        self.studySceneConstruction?.superNode.childNodes.forEach({
            ($0 as? ARPenStudyNode)?.setShaderArgument(name: "sonX", value: self.sonarPoint?.x ?? 0.0)
            ($0 as? ARPenStudyNode)?.setShaderArgument(name: "sonY", value: self.sonarPoint?.y ?? 0.0)
            ($0 as? ARPenStudyNode)?.setShaderArgument(name: "sonZ", value: self.sonarPoint?.z ?? 0.0)
            ($0 as? ARPenStudyNode)?.setShaderArgument(name: "active", value: self.helpActive ? 1.0 : 0.0)
        })
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        
        self.setShaderModifiers()
    }
    
    override func calculateNextTarget() {
        super.calculateNextTarget()
        
        self.setShaderModifiers()
    }
    
    func setShaderModifiers() {
        self.studySceneConstruction?.superNode.childNodes.filter({$0.name != "testBlob"}).forEach({
            ($0 as? ARPenStudyNode)?.setShaderModifier(shaderModifiers: [SCNShaderModifierEntryPoint.geometry: """
                
                
                #pragma varyings
                float3 origPosition;
                
                #pragma body
                out.origPosition = (scn_node.modelTransform * _geometry.position).xyz;
                """,
                                            SCNShaderModifierEntryPoint.surface: """
                #pragma arguments
                float sonX;
                float sonY;
                float sonZ;
                float active;
                
                #pragma body
                float distToSon = distance(float3(sonX,sonY,sonZ),in.origPosition);
                
                if (active > 0.5){
                    if (distToSon > 0.01) {
                        _surface.diffuse = float4(distToSon*5.0,1.0-distToSon*5.0,0.0,1.0);
                    } else {
                        _surface.diffuse = float4(0.0,0.0,1.0,1.0);
                    }
                    _surface.emission = float4(0.0,0.0,0.0,0.0);
                }
                """])
        })
    }
    
    override func deactivatePlugin() {
        self.studySceneConstruction?.superNode.childNodes.forEach({$0.geometry?.shaderModifiers = nil})
        
        super.deactivatePlugin()
    }
    
}


