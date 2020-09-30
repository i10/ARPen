import Foundation
import SpriteKit

class HapticMenu: MidairPieMenu {
    
    var hoverColor : UIColor = UIColor.green
    var cursor: SKShapeNode? = nil
    
    /// Describes on which hight we enter hover and selection states
    let tapThreshold: (hover: Float, enter: Float, leave: Float) = (hover: 0.06, enter: 0.01, leave: 0.01)
    
    private var isInTapState = false
    
    required init(menu: Menu, path: [Int]){
        super.init(menu: menu, path: path)
        
        self.constraints = []
        
        //Rotate it to lie on a horizontal surface
        self.eulerAngles.x =  -.pi / 2
        
        self.outerRadius = 0.1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawMenu() {
        super.drawMenu()
        
        //Occlusion of other objects should be allowed such that the user can identify the position of the menu a bit better
        self.geometry?.firstMaterial?.readsFromDepthBuffer = true
        self.renderingOrder -= 1000
        
       
        cursor = SKShapeNode(circleOfRadius: shadowRadius * resolutionFactor)
        cursor?.strokeColor = .clear
        cursorVisible(visible: false)
        cursor!.position = CGPoint(x: self.skScene!.frame.width / 2, y: self.skScene!.frame.height / 2)
        self.skScene?.addChild(cursor!)
            
    }
    let shadowRadius: CGFloat = 0.002
    
    private func cursorVisible(visible: Bool){
        cursor!.fillColor = visible ? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.3981349032) : .clear
    }
    
    // MARK: Item Highlighting and Selection
    
    /// Does not do anything. Ignores the conventional selection methods in this menu implementation.
    override func objectSelected(_ node: Selectable, intersectionAt intersection: SCNVector3, cursor: AREvent) {}
    
    
    /**
     Determines whether a selection is happening. Also checks whether an item needs to be highlighted (on pen hover or after entering the selection area).
     
     - parameters:
        - penTip: The pen tip's SCNNode.
        - sceneView: Not used in this implementation.
    */
    override func updateMenu(penTip: SCNNode?, sceneView: SCNView) {
        
        guard let tipWorldPosition = penTip?.worldPosition else { return }
        let localTipPosition = self.convertPosition(tipWorldPosition, from: nil)
        
        if CGPoint(x: CGFloat(localTipPosition.x), y: CGFloat(localTipPosition.y)).length() < self.outerRadius {
            
            // Reposition the shadow cursor
            var newCursorPosition = CGPoint(x: CGFloat(localTipPosition.x), y: -CGFloat(localTipPosition.y))
            newCursorPosition = newCursorPosition * self.resolutionFactor
            newCursorPosition = newCursorPosition + CGPoint(x: self.skScene!.frame.width / 2, y: self.skScene!.frame.height / 2)
            self.cursor?.position = newCursorPosition
            
            self.cursorVisible(visible: true)
        } else {
            self.cursorVisible(visible: false)
        }
        
        // Pen tip is near enough to enter the selection state
        if localTipPosition.z < self.tapThreshold.enter {
            self.isInTapState = true
        }
        
        // Highlight a menu item if pen tip is near enough
        if localTipPosition.z < self.tapThreshold.hover {
            print(localTipPosition.z)
            self.highlightItems(position: localTipPosition)
        } else {
            self.highlightedItem = nil
        }
        
        // Is the selection triggered?
        if self.isInTapState && localTipPosition.z > self.tapThreshold.leave {
            if let selectedItemIndex = self.highlightedItem?.index {
                if selectedItemIndex < 0 {
                    self.stepBack()
                } else {
                    self.menuDelegate?.menuItemSelected(owner: self.owner,
                                                        label: self.menu.subMenus[selectedItemIndex].label,
                                                        indexPath: self.menu.subMenus[selectedItemIndex].path,
                                                        isLeaf: self.menu.subMenus[selectedItemIndex].isLeaf)
                    self.closeMenu(asAbort: false)
                }
                self.highlightedItem = nil
            } else {
                // No item was highlighted
                self.closeMenu()
            }
            self.isInTapState = false
        }
    }
    
    /// Determines depending on the local x and y position of the pen tip which item needs to be hightlighted.
    func highlightItems(position: SCNVector3) {
        let length = CGPoint(x: CGFloat(position.x), y: CGFloat(position.y)).length()
        
        if length >= self.innerRadius && length <= self.outerRadius {
            
            let angle = CGPoint(x: CGFloat(position.x), y: CGFloat(position.y)).angle()
            let index = menu.count - 1 - Int((angle / (2 * .pi)) * CGFloat(menu.subMenus.count))
            self.highlightedItem = (index: index, item: items[index]!)
            
            // Change highlight when hovering
            if !isInTapState {
                self.highlightedItem?.item.fillColor = self.hoverColor
            }
            
        } else if let bb = self.backButton, length < self.innerRadius{
            self.highlightedItem = (index: -1, item: bb)
        } else {
            self.highlightedItem = nil
        }
    }
    
}
