import Foundation
import ARKit

class TwoHandedTouch: MidairPlugin {
    override init() {
        super.init()
        self.pluginImage = UIImage.init(named: "ARMenus2HandedPlugin")
        pluginIdentifier = "Two-Handed Touch"
        self.pluginGroupName = "ARMenus"
        self.pluginInstructionsImage = UIImage.init(named: "ARMenus2HandedInstructions")
        self.isExperimentalPlugin = true
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
       
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        pluginManager?.allowPenInput = true
        pluginManager?.allowTouchInput = true
        isPenTipHidden = true
    }
    
    override func deactivatePlugin() {
        super.deactivatePlugin()
        isPenTipHidden = false
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        updateTouchHighlight(touches)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        updateTouchHighlight(touches)
    }
    
    private func updateTouchHighlight(_ touches: Set<UITouch>){
        if let m = arMenu as? MidairPieMenu {
            guard let sceneView = self.pluginManager?.sceneView else { return }
            //            let hits:[SCNHitTestResult] = sceneView.hitTest(touches.first!.location(in: sceneView), options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue]).filter( {$0.node == m} )
            
            //Get 3d coordinates on the near plane
            let point = sceneView.unprojectPoint(SCNVector3(touches.first!.location(in: sceneView).x, touches.first!.location(in: sceneView).y, 0.0))
            let node = SCNNode()
            node.position = point
            m.updateMenu(penTip: node, sceneView: pluginManager!.sceneView)
        }
    }
    
}
