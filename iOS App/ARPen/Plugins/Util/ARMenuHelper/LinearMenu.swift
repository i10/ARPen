import SpriteKit

class LinearMenu: SCNNode, ARMenu, Selectable {
    
    func objectSelected(_ node: Selectable, intersectionAt intersection: SCNVector3, cursor: AREvent) {}
    
    var menu: Menu
    var path: [Int]
    var menuDelegate: MenuDelegate?
    fileprivate var items: [Int:SKShapeNode] = [:]
    
    // Drawing properties
    var itemDistance: CGFloat = 0.0005
    var width: CGFloat = 0.2688
    var height: CGFloat = 0.1242
    var fillColor = UIColor.white
    var strokeColor = UIColor.black
    var lineWidth: CGFloat = 1
    var fontColor = UIColor.black
    var fontSize: CGFloat = 80
    var font = "Helvetica Neue"
    var backButtonColor = #colorLiteral(red: 0.7997909188, green: 0.7997909188, blue: 0.7997909188, alpha: 1)
    var backButtonFontSize: CGFloat = 80
    
    var skScene: SKScene? = nil
    private let resolutionFactor: CGFloat = 10000.0
    
    required init(menu: Menu, path: [Int]) {
        self.path = path
        self.menu = menu
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func menuTouchedAt(_ index: Int){
        if index <= -2 {
            closeMenu(asAbort: true)
            return
        }
        if index == -1 {
            stepBack()
            return
        }
        menuDelegate?.menuItemSelected(owner: owner, label: menu.subMenus[index].label, indexPath: menu.subMenus[index].path, isLeaf: true)
        closeMenu(asAbort: false)
    }
    
    
    
    func drawMenu() {
        
        self.skScene = LinearMenuScene(size: CGSize(width: width * resolutionFactor, height: height * resolutionFactor))
        self.skScene!.backgroundColor = UIColor.clear
        self.skScene?.isUserInteractionEnabled = true
        (self.skScene as! LinearMenuScene).menuTouchedAt = menuTouchedAt(_:)
        
        let backButton = createItem(itemIndex: -1, isBackButton: true)
        backButton.name = "-1"
        self.skScene!.addChild(backButton)
        for i in 0 ..< menu.subMenus.count {
            let item = createItem(itemIndex: i, isBackButton: false)
            item.name = "\(i)"
            items[i] = item
            self.skScene!.addChild(item)
        }
        let plane = SCNPlane(width: width, height: height)
        let material = SCNMaterial()
        material.isDoubleSided = false
        material.diffuse.contents = self.skScene!
        plane.materials = [material]
        
        self.geometry = plane
    }
    
    
    private func quadFunc(_ x: CGFloat) -> CGFloat{
        let correctedX = (x - self.skScene!.frame.height / 2) / self.resolutionFactor * 1000 //1000 to get millimeters
        return (-0.005 * pow(correctedX - 10, 2) + 115) / 1000 * self.resolutionFactor
    }
    
    /**
     
     - parameters:
        - itemIndex: Index of the menu item. If isBackButton is true, this value will be ignored.
        - isBackButton: States wheter this button is the back button or not
    */
    private func createItem(itemIndex: Int, isBackButton: Bool) -> SKShapeNode{
        let path = UIBezierPath()
        path.lineWidth = 1
        let centerPoint = CGPoint(x: -self.skScene!.frame.height, y: self.skScene!.frame.height / 2)
        path.move(to: centerPoint)
        var currentY: CGFloat = self.skScene!.frame.height / CGFloat(self.menu.subMenus.count) * CGFloat(itemIndex)
        var nextY: CGFloat = self.skScene!.frame.height / CGFloat(self.menu.subMenus.count) * CGFloat(itemIndex + 1)
        let currentX = quadFunc(currentY)
        let nextX = quadFunc(nextY)
        if isBackButton {
            currentY = self.skScene!.frame.height
            nextY = self.skScene!.frame.height / CGFloat(self.menu.subMenus.count) * CGFloat(self.menu.count)
            path.addLine(to: CGPoint(x: quadFunc(currentY), y: currentY))
            path.addLine(to: CGPoint(x: 0, y: currentY))
            path.addLine(to: centerPoint)
            path.close()
        } else {
            if itemIndex == 0 {
                path.addLine(to: CGPoint.zero)
            }
            path.addLine(to: CGPoint(x: currentX, y: currentY))
            path.addLine(to: CGPoint(x: nextX, y: nextY))
            path.addLine(to: centerPoint)
            path.close()
        }
        
        let shape = SKShapeNode(path: path.cgPath)
        shape.fillColor = isBackButton ? self.backButtonColor : fillColor
        shape.strokeColor = strokeColor
        shape.lineWidth = lineWidth
        
        /* Draw label */
        let label: String
        if isBackButton {
            label = "🔙"
        } else {
            label = menu.subMenus[itemIndex].label
        }
        let labelNode = SKLabelNode(text: label)
        if isBackButton {
            labelNode.horizontalAlignmentMode = .left
            labelNode.verticalAlignmentMode = .top
            labelNode.position = CGPoint(x: 2 * labelNode.frame.width, y: self.skScene!.frame.height - labelNode.frame.height * 1.5)
        }
        else {
            labelNode.horizontalAlignmentMode = .right
            labelNode.verticalAlignmentMode = .center
            labelNode.position = CGPoint(x: min(currentX, nextX) - labelNode.frame.width * 0.1, y: currentY + (nextY - currentY) / 2)
        }
        labelNode.fontSize = isBackButton ? backButtonFontSize : fontSize
        labelNode.fontName = font
        labelNode.fontColor = fontColor
        labelNode.isUserInteractionEnabled = false
        
        shape.addChild(labelNode)
        
        return shape
    }
    
    
    
    
}

class LinearMenuScene: SKScene {
    
    var menuTouchedAt: ((_ index: Int) -> Void)? = nil
    
    var highlightColor = UIColor.orange
    var fillColor = UIColor.white
    
    var highlightedItem: SKShapeNode? = nil {
        didSet {
            oldValue?.fillColor = self.fillColor
            highlightedItem?.fillColor = self.highlightColor
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        menuTouchedAt?(Int(highlightedItem?.name ?? "-2")!) //-2 outside
        highlightedItem = nil
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        highlight(touches)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        highlight(touches)
    }
    
    private func highlight(_ touches: Set<UITouch>){
        // Search for ShapeNode child for which the touch location is in it's drawn body
        for child in self.children {
            let location = touches.first?.location(in: child)
            if let shapeChild = child as? SKShapeNode, shapeChild.path?.contains(location!) ?? false, shapeChild.name != "markerIndicator" {
                highlightedItem = shapeChild
                return
            }
        }
        //No item found
        highlightedItem = nil
    }
    
}



