import ARKit

class LinearMenuPlugin: StudyPlugin {
    
    //Only for quick access
    var overlay: SKScene? {
        get {
            return self.pluginManager?.sceneView.overlaySKScene
        }
        set {
            self.pluginManager?.sceneView.overlaySKScene = newValue
        }
    }
    
    override init() {
        super.init()
        self.pluginImage = UIImage.init(named: "ARMenus1HandedPlugin")
        self.pluginIdentifier = "One-Handed Touch"
        self.pluginGroupName = "ARMenus"
        self.pluginInstructionsImage = UIImage.init(named: "ARMenus1HandedInstructions")
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        MenuManager.shared.menuType = .LinearTouch
        
        pluginManager?.allowPenInput = true
        pluginManager?.allowTouchInput = false
    }
    
    override func deactivatePlugin() {
        super.deactivatePlugin()
//        self.pluginManager?.sceneView.overlaySKScene = nil
    }
    override func objectSelected(_ node: Selectable, intersectionAt intersection: SCNVector3, cursor: AREvent) {
        if cursor.eventType != .Ended { return }
        self.toggleMainViewControllerUIElements(toHidden: true)
        super.objectSelected(node, intersectionAt: intersection, cursor: cursor)
        if let m = arMenu as? LinearMenu {
            if let menuSKNodes = m.skScene?.children{
                menuSKNodes.forEach { (menuItem) in
                    menuItem.removeFromParent()
                    self.overlay?.addChild(menuItem)
                    self.overlay?.isUserInteractionEnabled = true
                    (self.overlay as? LinearMenuScene)?.menuTouchedAt = (m.skScene as? LinearMenuScene)?.menuTouchedAt
                }
            }
            m.skScene = nil
            m.geometry = nil
        }
    }
    
    override func menuDidClose(node: SCNNode?) {
        super.menuDidClose(node: node)
        clearOverlay()
    }
    
    override func didStepBack(node: SCNNode?, to depth: Int) {
        super.didStepBack(node: node, to: depth)
        clearOverlay()
    }
    
    override func itemSelected(node: SCNNode?, label: String, indexPath: [Int], isLeaf: Bool) {
        clearOverlay()
        super.itemSelected(node: node, label: label, indexPath: indexPath, isLeaf: isLeaf)
    }
    
//    //No hightlight for this menu
//    override func onIdleMovement(to position: SCNVector3) { }
    
    func clearOverlay() {
        if overlay != nil {
            for child in overlay!.children {
                if child != targetLabelNode {
                    child.removeFromParent()
                }
            }
        }
        overlay?.isUserInteractionEnabled = false
        isPenTipHidden = false
        self.toggleMainViewControllerUIElements(toHidden: false)
    }
    
    /// Replaces the SKScene provided by its superclass with a LinearMenuScene
    override func createOverlay() {
        super.createOverlay()
        if let skNode = targetLabelNode{
            skNode.removeFromParent()
            let newScene = LinearMenuScene(size: overlay!.size)
                newScene.addChild(skNode)
            newScene.isUserInteractionEnabled = false
            overlay = newScene
        }
    }
    
    func toggleMainViewControllerUIElements(toHidden hidden : Bool){
        if let vc = self.pluginManager?.delegate as? ViewController {
            DispatchQueue.main.async {
                vc.menuView.isHidden = hidden
                vc.menuToggleButton.isHidden = hidden
                vc.softwarePenButton.isHidden = hidden
            }
        }
        
    }
    
}
