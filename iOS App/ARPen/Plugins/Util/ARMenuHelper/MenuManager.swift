import SpriteKit
import ARKit

typealias MenuItemSelectedClosure = ((_ node: SCNNode?, _ label: String, _ indexPath: [Int], _ isLeaf: Bool) -> Void)
typealias MenuSteppedBackClosure = ((_ node: SCNNode?, _ toDepth: Int) -> Void)
typealias MenuClosedClosure = ((_ node: SCNNode?) -> Void)

/**
 This Singleton class, manages the creation of menus, the menu policies (e.g., only allowing a single menu), and passes menu events
 **/
class MenuManager: MenuDelegate {
    
    static let shared = MenuManager()
    private init(){}
    
    /// The currently open menu. If set, it also sets the menu's delegate.
    private var openMenu: ARMenu? = nil {
        didSet {
            openMenu?.menuDelegate = self
        }
    }
    
    var itemSelected: MenuItemSelectedClosure? = nil
    var menuSteppedBack: MenuSteppedBackClosure? = nil
    var menuClosed: MenuClosedClosure? = nil
    
    var menuType: MenuType = .LinearTouch
    
    func createContextMenuNode(for node: SelectableNode, itemSelected: MenuItemSelectedClosure?, menuSteppedBack: MenuSteppedBackClosure?, menuClosed: MenuClosedClosure?) -> ARMenu? {
        guard let menu = node.menu else { return nil }
        let menuNode = createMenu(menu, attachedTo: node, itemSelected: itemSelected, menuSteppedBack: menuSteppedBack, menuClosed: menuClosed)
        return menuNode
    }
    
    private func getMenuOfType(_ type: MenuType, model: Menu, path: [Int]) -> ARMenu {      
        switch type {
        case .MidairPie:
            return MidairPieMenu(menu: model, path: path)
        case .MovingCursor:
            return MovingCursorMenu(menu: model, path: path)
        case .Haptic:
            return HapticMenu(menu: model, path: path)
        default:
            return LinearMenu(menu: model, path: path)
        }
    }
    
    func createMenu(_ menu: Menu, attachedTo rootNode: SCNNode?, itemSelected: MenuItemSelectedClosure?, menuSteppedBack: MenuSteppedBackClosure?, menuClosed: MenuClosedClosure?) -> ARMenu? {
        openMenu?.closeMenu(asAbort: true)
        
        let menuNode = getMenuOfType(self.menuType, model: menu, path: [])
        
        menuNode.drawMenu()
        rootNode?.addChildNode(menuNode as! SCNNode)
        openMenu = menuNode
        
        self.itemSelected = itemSelected
        self.menuSteppedBack = menuSteppedBack
        self.menuClosed = menuClosed
        return menuNode
    }
    
    func closeMenu() {
        openMenu?.closeMenu(asAbort: true)
    }
    
    func menuItemSelected(owner: SCNNode?, label: String, indexPath: [Int], isLeaf: Bool) {
        itemSelected?(owner, label, indexPath, isLeaf)
        if isLeaf {
            openMenu = nil
        }
    }
    
    func menuSteppedBack(owner: SCNNode?,to depth: Int) {
        menuSteppedBack?(owner, depth)
    }
    
    func menuDidClose(owner: SCNNode?) {
        menuClosed?(owner)
        openMenu = nil
    }
    
}

enum MenuType {
    case MidairPie, LinearTouch, MovingCursor, Haptic
}


