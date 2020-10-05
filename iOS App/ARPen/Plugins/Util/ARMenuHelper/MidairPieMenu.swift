import SpriteKit

class MidairPieMenu: SCNNode, ARMenu, Selectable {
    
    var menu: Menu
    var items: [Int:SKShapeNode] = [:]
    var backButton: SKShapeNode? = nil
    var path: [Int]
    
    var menuDelegate: MenuDelegate? = nil
    
    // Drawing properties
    var itemDistance: CGFloat = 0.000
    var innerRadius: CGFloat = 0.006
    var outerRadius: CGFloat = 0.045 {
        didSet {
            innerRadius *= (outerRadius / oldValue)
            drawMenu()
        }
    }
    var centerColor = #colorLiteral(red: 0.7997909188, green: 0.7997909188, blue: 0.7997909188, alpha: 1)
    var fillColor = UIColor.white
    var strokeColor = UIColor.black
    var lineWidth: CGFloat = 5
    var fontColor = UIColor.black
    var fontSize: CGFloat = 100
    var font = "Helvetica Neue"
    
    var highlightColor = UIColor.orange
    
    var skScene: SKScene? = nil
    
    var initDistance: CGFloat = 0.4

    let resolution: CGFloat = 1000
    var resolutionFactor: CGFloat {
        get { return self.resolution / (outerRadius * 2 + innerRadius)}
    }
    
    required init(menu: Menu, path: [Int]) {
        self.path = path
        self.menu = menu
        super.init()
        
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis(arrayLiteral: SCNBillboardAxis.X, SCNBillboardAxis.Y)
        self.constraints = [billboardConstraint]
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func objectSelected(_ node: Selectable, intersectionAt intersection: SCNVector3, cursor: AREvent) {
        let sliceIndex = getHitIndex(withIntersectionAt: intersection)
        if cursor.eventType == .Began { return }
        if sliceIndex == -1 { // dead zone
            stepBack()
        } else if sliceIndex == nil {
            closeMenu(asAbort: true)
        } else {
            menuDelegate?.menuItemSelected(owner: owner,
                                           label: menu.subMenus[sliceIndex!].label,
                                           indexPath: menu.subMenus[sliceIndex!].path,
                                           isLeaf: menu.subMenus[sliceIndex!].isLeaf)
            closeMenu(asAbort: false)
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
            if slice.value.path?.contains(CGPoint(x: CGFloat(intersection.x) * self.resolutionFactor, y: CGFloat(intersection.y) * self.resolutionFactor)) ?? false {
                return self.items.count - 1 - slice.key
            }
        }
        return nil
    }
    
    ///Scales the menu such that it always seems to have the same size & highlights hovered menu items
    func updateMenu(penTip: SCNNode?, sceneView: SCNView){
        DispatchQueue(label: "menu update queue").async {
            //Scaling
            let scale = 1 / (Float(self.initDistance) / (sceneView.pointOfView!.worldPosition - self.worldPosition).length())
            self.scale = SCNVector3(scale, scale, scale)
            
            //Highlight item
            let projectedPencilPosition = sceneView.projectPoint(penTip!.position)
            let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
            
            if let hit = sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue]).filter({$0.node == self}).first {
                let index = self.getHitIndex(withIntersectionAt: hit.localCoordinates)
                if index != nil{
                    if index! >= 0 {
                        self.highlightedItem = (index: index!, item: self.items[index!]!)
                    } else {
                        self.highlightedItem = (index: -1, item: self.backButton!)
                    }
                } else {
                    self.highlightedItem = nil
                }
            }
        }
    }
    
    var highlightedItem: (index: Int, item: SKShapeNode)? = nil {
        didSet {
            oldValue?.item.fillColor = (oldValue!.item == backButton!) ? self.centerColor : self.fillColor
            highlightedItem?.item.fillColor = self.highlightColor
        }
    }
    
    internal func drawMenu(){
        
        self.skScene = SKScene(size: CGSize(width: self.resolution, height: self.resolution))
        skScene!.backgroundColor = UIColor.clear
        
        backButton = drawCenter()
        backButton!.position = CGPoint(x: self.resolution / 2, y: self.resolution / 2)
        skScene!.addChild(backButton!)
        for i in 0 ..< menu.subMenus.count {
            let item = drawItem(itemIndex: i)
            item.position.x += self.resolution / 2
            item.position.y += self.resolution / 2
            items[i] = item
            skScene!.addChild(item)
        }
        let plane = SCNPlane(width: (outerRadius * 2 + innerRadius), height: (outerRadius * 2 + innerRadius))
        let material = SCNMaterial()
        material.isDoubleSided = false
        material.readsFromDepthBuffer = false
        material.diffuse.contents = skScene
        plane.materials = [material]
        
        
        self.renderingOrder += 1000
        self.geometry = plane
    }
    
    internal func drawCenter() -> SKShapeNode{
        let normalizedInnerRadius: CGFloat = (innerRadius - itemDistance) * self.resolutionFactor
        
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
        labelNode.fontSize = normalizedInnerRadius
        labelNode.fontName = font
        labelNode.fontColor = fontColor
        
        shape.addChild(labelNode)
        
        return shape
    }
    
    internal func drawItem(itemIndex: Int) -> SKShapeNode{
        let normalizedInnerRadius: CGFloat = innerRadius * self.resolutionFactor
        let normalizedOuterRadius: CGFloat = outerRadius * self.resolutionFactor
        
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
        
        shape.addChild(labelNode)
        
        return shape
    }
    
}
