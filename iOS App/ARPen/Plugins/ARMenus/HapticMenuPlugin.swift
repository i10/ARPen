import Foundation
import ARKit

class HapticMenuPlugin: StudyPlugin {
    
    let menuOpenedColor = UIColor.cyan
    var menuPosition = SCNVector3(x: 0 / 2, y: -0.2, z: -0.3 / 2)
    
    override init() {
        super.init()
        self.pluginImage = UIImage.init(named: "ARMenusSurfacePlugin")
        self.pluginIdentifier = "Surface Menu"
        self.pluginGroupName = "ARMenus"
        self.pluginInstructionsImage = UIImage.init(named: "ARMenusSurfaceInstructions")
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        MenuManager.shared.menuType = .Haptic
        
        pluginManager?.allowPenInput = true
        pluginManager?.allowTouchInput = false
        
        //if a horizontal surface has been detected, use it's z position to place the menu
        if let horizontalPlanePosition = (self.pluginManager?.delegate as? ViewController)?.horizontalSurfacePosition {
            self.menuPosition.y = horizontalPlanePosition.y
        }
    }
    
    var lastOpenedNode: SCNNode? = nil {
        didSet {
            (oldValue as? ARPenStudyNode)?.changeColors()
            
            (self.lastOpenedNode)?.geometry?.firstMaterial?.diffuse.contents = menuOpenedColor
            (self.lastOpenedNode)?.geometry?.firstMaterial?.emission.contents = menuOpenedColor
        }
    }
    
    override func objectSelected(_ node: Selectable, intersectionAt intersection: SCNVector3, cursor: AREvent) {
        if cursor.eventType == .Ended {
            super.objectSelected(node, intersectionAt: intersection, cursor: cursor)
            lastOpenedNode = node as! SCNNode
            
            (self.arMenu as? SCNNode)?.worldPosition = menuPosition
            
            
        }
    }
    
    override func itemSelected(node: SCNNode?, label: String, indexPath: [Int], isLeaf: Bool) {
        super.itemSelected(node: node, label: label, indexPath: indexPath, isLeaf: isLeaf)
        lastOpenedNode = nil
        
        //update world position information
        if let horizontalPlanePosition = (self.pluginManager?.delegate as? ViewController)?.horizontalSurfacePosition {
            self.menuPosition.y = horizontalPlanePosition.y
        }
    }
    
    override func didStepBack(node: SCNNode?, to depth: Int) {
        super.didStepBack(node: node, to: depth)
        lastOpenedNode = nil
    }
    
    override func menuDidClose(node: SCNNode?) {
        super.menuDidClose(node: node)
        lastOpenedNode = nil
    }
    
    override func onIdleMovement(to position: SCNVector3) {
        super.onIdleMovement(to: position)
        if let m = arMenu as? HapticMenu {
            m.updateMenu(penTip: self.pluginManager?.penScene.pencilPoint, sceneView: pluginManager!.sceneView)
        }
    }
    
}
