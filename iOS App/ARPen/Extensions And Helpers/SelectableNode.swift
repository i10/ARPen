class SelectableNode: SCNNode, Selectable {
    
    var menu: Menu? = nil
    var highlight: Bool = false
    
    var itemSelected: MenuItemSelectedClosure? = nil
    var didStepBack: MenuSteppedBackClosure? = nil
    var menuClosed: MenuClosedClosure? = nil
    
    weak var selectionDelegate: Selectable? = nil
        
    var enabled: Bool = true {
        didSet {
            for child in childNodes {
                (child as? SelectableNode)?.enabled = enabled
            }
        }
    }
    
    init(geometry: SCNGeometry? = nil) {
        super.init()
        self.geometry = geometry
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setMenu(_ menu: Menu, menuItemSelected: MenuItemSelectedClosure?, didStepBack: MenuSteppedBackClosure?, menuDidClose: MenuClosedClosure?){
        self.menu = menu
        self.itemSelected = menuItemSelected
        self.didStepBack = didStepBack
        self.menuClosed = menuDidClose
        
    }
    
    func objectSelected(_ node: Selectable, intersectionAt intersection: SCNVector3, cursor: AREvent) {
        selectionDelegate?.objectSelected(node, intersectionAt: intersection, cursor: cursor)
    }
    
    func openContextMenu() -> ARMenu? {
        return MenuManager.shared.createContextMenuNode(for: self, itemSelected: itemSelected!, menuSteppedBack: didStepBack!, menuClosed: menuClosed!)
    }
    
}

typealias SelectionDelegate = Selectable

protocol Selectable: class {
    /**
     Defines the node's behavior when selected.
     
     - parameters:
        - node: the selected node
        - intersectionAt: The point of intersection describes in the local coordinates of the node
        - cursor: holds further information
     */
    func objectSelected(_ node: Selectable, intersectionAt intersection: SCNVector3, cursor: AREvent)
}

struct AREvent {
    var inputType: ARInputType
    /// Location of the cursor in the local coordinate system of the hit node. For ARInputType.Touch the z location is on the near plane.
    var location: SCNVector3
    var eventType: AREventType
    
    enum AREventType {
        case Began, Ended
    }
    
    enum ARInputType {
        case Touch
        case ARPen
    }
}


