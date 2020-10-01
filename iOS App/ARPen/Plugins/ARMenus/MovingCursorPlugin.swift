import ARKit

class MovingCursorPlugin: MidairPlugin {
    
    override init() {
        super.init()
        self.pluginIdentifier = "Device Pointer"
        self.pluginGroupName = "ARMenus"
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
       
        super.activatePlugin(withScene: scene, andView: view)
        MenuManager.shared.menuType = .MovingCursor
        
        pluginManager?.allowPenInput = true
        pluginManager?.allowTouchInput = false
    }
    
    override func objectSelected(_ node: Selectable, intersectionAt intersection: SCNVector3, cursor: AREvent) {
        if cursor.eventType != .Ended { return }
        super.objectSelected(node, intersectionAt: intersection, cursor: cursor)
        if let m = self.arMenu {
            (m as! MovingCursorMenu).referenceNode = self.pluginManager?.sceneView.pointOfView
            
        }
        if node is ARPenStudyNode && (node as! SCNNode).name != "start sign"{
            isPenTipHidden = true
        } else {
            isPenTipHidden = false
        }
    }
    
    override func onIdleMovement(to position: SCNVector3) {
        super.onIdleMovement(to: position)
    }
    
    override func itemSelected(node: SCNNode?, label: String, indexPath: [Int], isLeaf: Bool) {
        super.itemSelected(node: node, label: label, indexPath: indexPath, isLeaf: isLeaf)
        isPenTipHidden = false
    }
    
    override func menuDidClose(node: SCNNode?) {
        super.menuDidClose(node: node)
        isPenTipHidden = false
    }
    
    override func didStepBack(node: SCNNode?, to depth: Int) {
        super.didStepBack(node: node, to: depth)
        isPenTipHidden = false
    }
    
    override func onPenMoved(to position: SCNVector3, clickedButtons: [Button]) {
        onIdleMovement(to: position)
    }
    
    override func onPenClickEnded(at position: SCNVector3, releasedButton: Button) {
        if let m = arMenu as? MovingCursorMenu {
            m.selectItem()
        }
    }
    
}
