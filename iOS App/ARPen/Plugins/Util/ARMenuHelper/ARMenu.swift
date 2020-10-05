import SpriteKit

/**
 The ARMenu protocol describes the main
 */
protocol ARMenu {
    
    ///Model of the menu visualization
    var menu: Menu { get set }
    
    /**
    The node whose menu is shown. This does not include parental menus!
    */
    var owner: SCNNode? { get }
    
    /// Describes the path from the root menu to this submenu
    var path: [Int] { get set }
    
    ///Menu delegate which is set by the MenuManager to pass menu events through the MenuManager back to the plugin.
    ///If submenus are implemented, their menuDelegate must be set manually!
    var menuDelegate: MenuDelegate? { get set }
    
    init(menu: Menu, path: [Int])
    
    func drawMenu()
    func closeMenu(asAbort: Bool)
}

extension ARMenu where Self: SCNNode, Self: Selectable {
    
    var owner: SCNNode? {
        get {
            if self.parent is ARMenu {
                return (self.parent as! ARMenu).owner
            } else {
                return self.parent
            }
        }
    }
    
    func closeMenu(asAbort: Bool = true){
        if asAbort {
            menuDelegate?.menuDidClose(owner: owner)
        }
        if let parentMenuNode = parent as? ARMenu {
            parentMenuNode.closeMenu(asAbort: false)
        }
        self.removeFromParentNode()
    }
    
    func stepBack() {
//        if path.count > 0 {
            menuDelegate?.menuSteppedBack(owner: owner, to: path.count - 1)
            self.removeFromParentNode()
//        } else {
            closeMenu(asAbort: false)
//        }
        
    }
}

protocol MenuDelegate {
    func menuItemSelected(owner: SCNNode?, label: String, indexPath: [Int], isLeaf: Bool)
    func menuSteppedBack(owner: SCNNode?, to depth: Int)
    func menuDidClose(owner: SCNNode?)
}
