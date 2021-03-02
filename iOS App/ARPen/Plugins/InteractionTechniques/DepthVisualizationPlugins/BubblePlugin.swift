
import Foundation
import ARKit
import SpriteKit

class BubblePlugin: MinVisPlugin {
    
    private var sonarPoint: SCNVector3?
    
    private let sonarBubbleNum : Int = 5
    private var sonarBubbleIndex : Int = 0
    private var buttonIsPressable = true
    
    override init(){
        super.init()
        self.pluginIdentifier = "Bubble"
        self.pluginGroupName = "Depth Visualization"
        self.pluginImage = UIImage.init(named: "DepthVisualizationBubblePlugin")
        self.pluginInstructionsImage = UIImage.init(named: "DepthVisualizationBubbleInstructions")
        
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        
        super.didUpdateFrame(scene: scene, buttons: buttons)
        
        let pressed = buttons[Button.Button2]!
        if pressed {
            
            if self.buttonIsPressable {
                
                self.buttonIsPressable = false
                
                guard let sonarBubble = self.studySceneConstruction?.superNode.childNode(withName: "sonarBubble\(self.sonarBubbleIndex)", recursively: false) else {
                    var sonarBubble = SCNNode()
                    sonarBubble = SCNNode.init(geometry: SCNSphere.init(radius: 0.0))
                    sonarBubble.name = "sonarBubble\(self.sonarBubbleIndex)"
                    sonarBubble.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    sonarBubble.worldPosition = scene.pencilPoint.worldPosition
                    self.studySceneConstruction?.superNode.addChildNode(sonarBubble)
                    return
                }
                
                sonarBubble.worldPosition = scene.pencilPoint.worldPosition
                (sonarBubble.geometry as? SCNSphere)?.radius = 0.0
                sonarBubble.geometry?.firstMaterial?.transparency = 1.0
                self.sonarPoint = scene.pencilPoint.worldPosition
                self.studySceneConstruction?.superNode.childNodes.forEach({
                    ($0 as? ARPenStudyNode)?.setShaderArgument(name: "waveDist\(self.sonarBubbleIndex)", value: 0.0 as Float)
                })
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1.0
                self.studySceneConstruction?.superNode.childNodes.filter({($0 as SCNNode).worldPosition.distance(vector: self.sonarPoint!) < 0.15}).forEach({
                    ($0 as? ARPenStudyNode)?.setShaderArgument(name: "waveDist\(self.sonarBubbleIndex)", value: 0.1 as Float)
                })
                (sonarBubble.geometry as? SCNSphere)?.radius = 0.1
                sonarBubble.geometry?.firstMaterial?.transparency = 0.0
                SCNTransaction.commit()
                
                self.studySceneConstruction?.superNode.childNodes.filter({($0 as SCNNode).worldPosition.distance(vector: self.sonarPoint!) < 0.15}).forEach({
                    ($0 as? ARPenStudyNode)?.setShaderArgument(name: "sonX\(self.sonarBubbleIndex)", value: self.sonarPoint?.x ?? 0.0)
                    ($0 as? ARPenStudyNode)?.setShaderArgument(name: "sonY\(self.sonarBubbleIndex)", value: self.sonarPoint?.y ?? 0.0)
                    ($0 as? ARPenStudyNode)?.setShaderArgument(name: "sonZ\(self.sonarBubbleIndex)", value: self.sonarPoint?.z ?? 0.0)
                })
                
                self.sonarBubbleIndex = (self.sonarBubbleIndex + 1) % self.sonarBubbleNum
            }
        } else {
            self.buttonIsPressable = true
        }
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        
        for i : Int in 0 ..< self.sonarBubbleNum {
            var sonarBubble = SCNNode()
            sonarBubble = SCNNode.init(geometry: SCNSphere.init(radius: 0.0))
            sonarBubble.name = "sonarBubble\(i)"
            sonarBubble.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sonarBubble.worldPosition = scene.pencilPoint.worldPosition
            self.studySceneConstruction?.superNode.addChildNode(sonarBubble)
        }
        
        var shaderCode : String = "#pragma arguments\n"
        
        for i : Int in 0 ..< self.sonarBubbleNum {
            shaderCode += """
                float sonX\(i);
                float sonY\(i);
                float sonZ\(i);
                float waveDist\(i);\n
            """
        }
        
        shaderCode += """
            #pragma body
            float4 finalColor = _surface.diffuse;
            float4 sonarColor = float4(0.0,0.0,1.0,1.0);\n
        """
        
        for i : Int in 0 ..< self.sonarBubbleNum {
            shaderCode += """
            float distToSon\(i) = distance(float3(sonX\(i),sonY\(i),sonZ\(i)),in.origPosition);
            float x\(i) = abs(distToSon\(i) - waveDist\(i));
            float mixMasterFactor\(i) = 1.0 - fmax(ceil(-100.0 * x\(i) * (x\(i) - 0.001)),0.0);
            float mixFactor\(i) = fmax(fmax(waveDist\(i) - 0.095, 0.0) * 200, mixMasterFactor\(i));
            finalColor = finalColor * (mixFactor\(i)) + sonarColor * (1.0-mixFactor\(i));\n
            """
        }
        
        shaderCode += "_surface.diffuse = finalColor;"
        
        self.studySceneConstruction?.studyNodes.forEach({
            $0.setShaderModifier(shaderModifiers: [SCNShaderModifierEntryPoint.geometry: """
                
                
                #pragma varyings
                float3 origPosition;
                
                #pragma body
                out.origPosition = (scn_node.modelTransform * _geometry.position).xyz;
                """,
                                            SCNShaderModifierEntryPoint.surface: shaderCode
            ])
        })
    }
    
    override func deactivatePlugin() {
        self.studySceneConstruction?.superNode.childNodes.forEach({$0.geometry?.shaderModifiers = nil})
        
        super.deactivatePlugin()
    }
    
}

