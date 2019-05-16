//
//  MidairPieMenu.swift
//  ARPen
//
//  Created by Oliver Nowak on 15.03.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import SpriteKit

class MidairPieMenu: SCNNode, ARMenu {
    
    var menu: Menu
    var subMenus: [ARMenu] = []
    var items: [Int:SKShapeNode] = [:]
    var path: [Int]
    
    var menuDelegate: MenuDelegate? = nil
    var selected: ((SCNNode, SCNVector3, ARCursor) -> Void)?
    
    // Drawing properties
    var itemDistance: CGFloat = 0.001
    var innerRadius: CGFloat = 0.01
    var outerRadius: CGFloat = 0.06
    var centerColor = #colorLiteral(red: 0.7997909188, green: 0.7997909188, blue: 0.7997909188, alpha: 1)
    var fillColor = UIColor.white
    var strokeColor = UIColor.black
    var lineWidth: CGFloat = 5
    var fontColor = UIColor.black
    var fontSize: CGFloat = 80
    var font = "Helvetica Neue"
    
    required init(menu: Menu, path: [Int]) {
        self.path = path
        self.menu = menu
        super.init()
        selected = nodeSelected(_:withIntersectionAt:cursor:)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func nodeSelected(_ node: SCNNode, withIntersectionAt position: SCNVector3, cursor: ARCursor) {
        guard let sliceIndex = getHitIndex(withIntersectionAt: position) else { return }
        if sliceIndex == -1 { // dead zone
            stepBack()
        } else {
            var newPath = self.path
            newPath.append(sliceIndex)
            if menu.subMenus[sliceIndex].isLeaf {
                menuDelegate?.menuItemSelected(owner: owner, label: menu.subMenus[sliceIndex].label, indexPath: newPath, isLeaf: true)
                closeMenu(asAbort: false)
            } else {
                if childNodes.count > 0 {
                    closeMenu(asAbort: true)
                    return
                }
                DispatchQueue.main.async {
                    let childMenu = MidairPieMenu(menu: self.menu.subMenus[sliceIndex], path: newPath)
                    childMenu.menuDelegate = self.menuDelegate
                    var direction = cursor.cursorLocation - position
                    direction = direction.normalize() / 100 * 1.5
                    childMenu.position = position + direction
                    childMenu.drawMenu()
                    childMenu.geometry?.firstMaterial?.readsFromDepthBuffer = false
                    childMenu.renderingOrder = 110
                    self.addChildNode(childMenu)
                    self.subMenus.append(childMenu)
                    self.menuDelegate?.menuItemSelected(owner: self.owner, label: self.menu.subMenus[sliceIndex].label, indexPath: newPath, isLeaf: false)
                }
                
            }
        }
    }
    
    private func getHitIndex(withIntersectionAt intersection: SCNVector3) -> Int? {
        if intersection.distance(vector: SCNVector3Zero) <= Float(innerRadius) {
            return -1
        }
        if intersection.distance(vector: SCNVector3Zero) > Float(outerRadius) {
            return nil
        }
        for slice in items {
            if slice.value.path?.contains(CGPoint(x: CGFloat(intersection.x) * 10000, y: CGFloat(intersection.y) * 10000)) ?? false {
                return self.items.count - 1 - slice.key
            }
        }
        return nil
    }
    
    internal func drawMenu(){
        let sceneWidth = (outerRadius * 2 + innerRadius) * 10000
        let scene = SKScene(size: CGSize(width: sceneWidth, height: sceneWidth))
        scene.backgroundColor = UIColor.clear
        
        let center = drawCenter()
        center.position = CGPoint(x: sceneWidth / 2, y: sceneWidth / 2)
        scene.addChild(center)
        for i in 0 ..< menu.subMenus.count {
            let item = drawItem(itemIndex: i)
            item.position.x += sceneWidth / 2
            item.position.y += sceneWidth / 2
            items[i] = item
            scene.addChild(item)
        }
        let plane = SCNPlane(width: sceneWidth / 10000, height: sceneWidth / 10000)
        let material = SCNMaterial()
        material.isDoubleSided = false
        material.diffuse.contents = scene
        plane.materials = [material]
        
        self.geometry = plane
    }
    
    private func drawCenter() -> SKShapeNode{
        let normalizedInnerRadius: CGFloat = (innerRadius - itemDistance) * 10000
        
        let path = UIBezierPath()
        path.lineWidth = 1
        path.addArc(withCenter: CGPoint.zero, radius: normalizedInnerRadius - lineWidth / 2, startAngle: 0, endAngle: 360.degreesToRadians, clockwise: true)
        path.close()
        
        let shape = SKShapeNode(path: path.cgPath)
        shape.fillColor = centerColor
        shape.strokeColor = strokeColor
        shape.lineWidth = lineWidth
        shape.position = CGPoint(x: shape.frame.width / 2, y: shape.frame.height / 2)
        
        /* Draw label */
        
        let labelNode = SKLabelNode(text: "🔙")
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.position = CGPoint.zero
        labelNode.yScale = -1
        labelNode.fontSize = fontSize
        labelNode.fontName = font
        labelNode.fontColor = fontColor
        
        shape.addChild(labelNode)
        
        return shape
    }
    
    private func drawItem(itemIndex: Int) -> SKShapeNode{
        let normalizedInnerRadius: CGFloat = innerRadius * 10000
        let normalizedOuterRadius: CGFloat = outerRadius * 10000
        
        let itemAngle: CGFloat = 2 * CGFloat.pi / CGFloat(menu.subMenus.count)
        
        let path = UIBezierPath()
        path.lineWidth = 1
        
        let startAngle = CGFloat(itemIndex) * itemAngle
        let endAngle = startAngle + itemAngle
        let innerSpaceAngle = innerRadius != 0 ? atan(itemDistance / 2 / innerRadius ) : 0
        let outerSpaceAngle = outerRadius != 0 ? atan(itemDistance / 2 / outerRadius) : 0
        let startingPoint = CGPoint(x: normalizedInnerRadius * cos(startAngle + innerSpaceAngle), y: normalizedInnerRadius * sin(startAngle + innerSpaceAngle))
        
        path.move(to: startingPoint)
        path.addArc(withCenter: CGPoint.zero, radius: normalizedInnerRadius, startAngle: startAngle + innerSpaceAngle, endAngle: endAngle - innerSpaceAngle, clockwise: true)
        path.addArc(withCenter: CGPoint.zero, radius: normalizedOuterRadius, startAngle: endAngle - outerSpaceAngle, endAngle: startAngle + outerSpaceAngle, clockwise: false)
        path.close()
        
        
        let shape = SKShapeNode(path: path.cgPath)
        shape.fillColor = fillColor
        shape.strokeColor = strokeColor
        shape.lineWidth = lineWidth
        
        let labelPoint = CGPoint(x: (normalizedOuterRadius + normalizedInnerRadius) / 2 * cos((endAngle + startAngle) / 2), y: (normalizedOuterRadius + normalizedInnerRadius) / 2 * sin((endAngle + startAngle) / 2))
        
        /* Draw label */
        
        let labelNode = SKLabelNode(text: menu.subMenus[itemIndex].label)
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.position = CGPoint(x: labelPoint.x, y: labelPoint.y)//CGPoint(x: shape.frame.midX, y: shape.frame.midY)
        labelNode.yScale = -1
        labelNode.fontSize = fontSize
        labelNode.fontName = font
        labelNode.fontColor = fontColor
        
        if let color = getColor(colorCode: menu.subMenus[itemIndex].label) {
            shape.fillColor = color
        } else {
            shape.addChild(labelNode)
        }
        
        return shape
    }
    
    func getColor(colorCode: String) -> UIColor?{
        let color: UIColor?
        switch colorCode {
        case "red":
            color = #colorLiteral(red: 0.8000000119, green: 0.02745098062, blue: 0.1176470593, alpha: 1)
        case "orange":
            color = #colorLiteral(red: 0.9647058845, green: 0.6588235497, blue: 0, alpha: 1)
        case "yellow":
            color = #colorLiteral(red: 1, green: 0.9294117689, blue: 0, alpha: 1)
        case "green":
            color = #colorLiteral(red: 0.3411764801, green: 0.6705882549, blue: 0.1529411823, alpha: 1)
        case "blue":
            color = #colorLiteral(red: 0, green: 0.3294117749, blue: 0.6235294342, alpha: 1)
        case "violet":
            color = #colorLiteral(red: 0.4784313738, green: 0.4352941215, blue: 0.6745098233, alpha: 1)
        default:
            color = nil
        }
        return color
    }
    
}

protocol ARMenu {
    
    ///Model of the menu visualization
    var menu: Menu { get set }
    
    /**
     Returns the node whose menu is shown
     */
    var owner: SCNNode { get }
    
    var subMenus: [ARMenu] { get set }
    var items: [Int:SKShapeNode] { get set }
    
    /// Describes the path from the root menu to this submenu
    var path: [Int] { get set }
    
    ///Menu delegate which needs to be set to pass menu events back to the owner node
    var menuDelegate: MenuDelegate? { get set }
    
    init(menu: Menu, path: [Int])
    
    func drawMenu()
    func closeMenu(asAbort: Bool)
}

extension ARMenu where Self: SCNNode {
    
    var owner: SCNNode {
        get {
            if self.parent is ARMenu {
                return (self.parent as! ARMenu).owner
            } else {
                return parent!
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
        if path.count > 0 {
            menuDelegate?.menuSteppedBack(owner: owner, to: path.count - 1)
            self.removeFromParentNode()
        } else {
            closeMenu()
        }
    }
}

protocol MenuDelegate {
    func menuItemSelected(owner: SCNNode, label: String, indexPath: [Int], isLeaf: Bool)
    func menuSteppedBack(owner: SCNNode, to depth: Int)
    func menuDidClose(owner: SCNNode)
}

class Menu {
    
    var subMenus: [Menu] = []
    var path: [Int] = [] {
        didSet { updatePathsForSubmenus() }
    }
    
    var label: String
    
    
    var count: Int {
        get { return subMenus.count }
    }
    
    init(label: String = "") {
        self.label = label
    }
    
    convenience init(label: String = "", subMenus: Menu...){
        self.init(label: label)
        for menu in subMenus { addSubmenus(submenus: menu) }
    }
    
    convenience init(label: String = "", leafs: String...){
        self.init(label: label)
        for leaf in leafs { addLeafs(leafs: leaf) }
    }
    
    convenience init(label: String = "", leafs: [String]){
        self.init(label: label)
        for leaf in leafs { addLeafs(leafs: leaf) }
    }
    
    func addSubmenus(submenus: Menu...) {
        for submenu in submenus {
            var path = self.path
            path.append(self.subMenus.count)
            path.append(contentsOf: submenu.path)
            submenu.path = path
            self.subMenus.append(submenu)
        }
    }
    
    func addSubmenus(submenus: [Menu]) {
        for submenu in submenus {
            var path = self.path
            path.append(self.subMenus.count)
            path.append(contentsOf: submenu.path)
            submenu.path = path
            self.subMenus.append(submenu)
        }
    }
    
    func addLeafs(leafs: String...){
        for leaf in leafs { addSubmenus(submenus: Menu(label: leaf)) }
    }
    
    func addLeafs(leafs: [String]){
        for leaf in leafs { addSubmenus(submenus: Menu(label: leaf)) }
    }
    
    private func updatePathsForSubmenus(){
        for (i, submenu) in self.subMenus.enumerated() {
            var path = self.path
            path.append(i)
            submenu.path = path
        }
    }
    
    var isLeaf: Bool {
        get{ return subMenus.isEmpty }
    }
    
    func getMenuWithPath(path: [Int]) -> Menu{
        if path.isEmpty {
            return self
        } else {
            var newPath = path
            let index = newPath.remove(at: 0)
            return subMenus[index].getMenuWithPath(path: newPath)
        }
        
    }
    
    
}

struct ARCursor {
    var inputType: ARInputType
    /// Location of the cursor. For ARInoutType.Touch the z location is 0.
    var cursorLocation: SCNVector3
}

enum ARInputType {
    case Touch
    case ARPen
}
