//
//  ARMenus.swift
//  ARPen
//
//  Created by Oliver Nowak on 19.03.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import ARKit

class ARMenusPlugin: Plugin, MenuDelegate {
    
    var pluginImage : UIImage? = UIImage.init(named: "PaintPlugin")
    var pluginIdentifier: String = "ARMenus"
    var currentView: ARSCNView?
    
    //You need to set this to nil when switching to another plugin!
    var currentScene: PenScene? {
        didSet {
            if currentScene != nil {
                targetNode = SCNNode(geometry: SCNBox(width: 0.02, height: 0.02, length: 0.02, chamferRadius: 0.0))
                targetNode!.position.z -= 0.3
                currentScene!.drawingNode.addChildNode(targetNode!)
            } else {
                targetNode?.removeFromParentNode()
            }
        }
    }
    
    let menu = Menu(label: "Properties", subMenus:
        Menu(label: "color", leafs: "red", "orange", "yellow", "green", "blue", "violet"),
                    Menu(label: "shape", leafs: "cube", "sphere", "cone"),
                    Menu(label: "transparency", leafs: "0%","25%", "50%", "75%")
    )
    
    var targetNode: SCNNode? = nil
    
    var openMenuNode: ARMenu? {
        didSet {
            if openMenuNode == nil { return }
            openMenuNode?.menuDelegate = self
        }
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentView = view
        self.currentScene = scene
        self.currentScene!.pencilPoint.geometry?.firstMaterial?.readsFromDepthBuffer = false
        self.currentScene!.pencilPoint.renderingOrder = 120
    }
    
    func deactivatePlugin(){
        self.currentScene?.pencilPoint.geometry?.firstMaterial?.readsFromDepthBuffer = true
        self.currentScene?.pencilPoint.renderingOrder = 0
        openMenuNode?.closeMenu(asAbort: true)
        targetNode?.removeFromParentNode()
        self.currentView = nil
        self.currentScene = nil
    }
    
    
    var isPressed = false
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        guard scene.markerFound else {
            return
        }
        let pressed = buttons[Button.Button1]! || buttons[Button.Button2]!
        let firstClick = !isPressed && pressed
        isPressed = pressed
        if !firstClick { return }
        
        let hits = hitTest(pointerPosition: scene.pencilPoint.position)
        if hits.isEmpty {
            openMenuNode?.closeMenu(asAbort: true)
        } else {
            let result = hits.first
            if let menu = result!.node as? MidairPieMenu{
                menu.nodeSelected(menu, withIntersectionAt: result!.localCoordinates, cursor: ARCursor(inputType: .ARPen, cursorLocation: menu.convertPosition(scene.pencilPoint.position, from: scene.rootNode)))
            } else {
                openMenuNode?.closeMenu(asAbort: true)
                if result?.node != targetNode {
                    return
                }
                let menuNode = MidairPieMenu(menu: menu, path: [])
                
                
                let billboardConstraint = SCNBillboardConstraint()
                billboardConstraint.freeAxes = SCNBillboardAxis(arrayLiteral: SCNBillboardAxis.X, SCNBillboardAxis.Y)
                menuNode.constraints = [billboardConstraint]
                menuNode.drawMenu()
                var direction = currentView!.pointOfView!.worldPosition - targetNode!.worldPosition
                direction = direction.normalize() / 100 * 1.5
                menuNode.position = direction
                menuNode.geometry?.firstMaterial?.readsFromDepthBuffer = false
                menuNode.renderingOrder = 100
                targetNode?.addChildNode(menuNode)
                openMenuNode = menuNode
            }
        }
    }
    
    func hitTest(pointerPosition: SCNVector3) -> [SCNHitTestResult] {
        guard let sceneView = self.currentView  else { return [] }
        let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
        let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
        
        //cast a ray from that position and find the first ARPenNode
        let hitResults = sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
        
        return hitResults.filter( { $0.node != currentScene?.pencilPoint } )
    }
    
    func menuItemSelected(owner: SCNNode, label: String, indexPath: [Int], isLeaf: Bool) {
        if !isLeaf { return }
        print(label)
        openMenuNode = nil
        
        switch indexPath[0] {
        case 0: changeColor(colorCode: indexPath[1])
        case 1: changeShape(shapeCode: indexPath[1])
        default:
            changeTransparency(transparencyCode: indexPath[1])
        }
        
    }
    
    func changeColor(colorCode: Int){
        let alpha = (targetNode?.geometry?.firstMaterial?.diffuse.contents as! UIColor).cgColor.alpha
        targetNode?.geometry?.firstMaterial?.diffuse.contents = getColor(colorCode: colorCode).withAlphaComponent(alpha)
    }
    
    func getColor(colorCode: Int) -> UIColor {
        let color: UIColor
        switch colorCode {
        case 0:
            color = #colorLiteral(red: 0.8000000119, green: 0.02745098062, blue: 0.1176470593, alpha: 1)
        case 1:
            color = #colorLiteral(red: 0.9647058845, green: 0.6588235497, blue: 0, alpha: 1)
        case 2:
            color = #colorLiteral(red: 1, green: 0.9294117689, blue: 0, alpha: 1)
        case 3:
            color = #colorLiteral(red: 0.3411764801, green: 0.6705882549, blue: 0.1529411823, alpha: 1)
        case 4:
            color = #colorLiteral(red: 0, green: 0.3294117749, blue: 0.6235294342, alpha: 1)
        case 5:
            color = #colorLiteral(red: 0.4784313738, green: 0.4352941215, blue: 0.6745098233, alpha: 1)
        default:
            color = #colorLiteral(red: 0.8000000119, green: 0.02745098062, blue: 0.1176470593, alpha: 1)
        }
        return color
    }
    
    func changeTransparency(transparencyCode: Int){
        targetNode?.geometry?.firstMaterial?.diffuse.contents = (targetNode?.geometry?.firstMaterial?.diffuse.contents as! UIColor).withAlphaComponent(1.0 - CGFloat(transparencyCode) * 0.25)
    }
    
    func changeShape(shapeCode: Int){
        let shape: SCNGeometry
        switch shapeCode {
        case 0:
            shape = SCNBox(width: 0.02, height: 0.02, length: 0.02, chamferRadius: 0)
        case 1:
            shape = SCNSphere(radius: 0.01)
        case 2:
            shape = SCNCone(topRadius: 0.005, bottomRadius: 0.02, height: 0.02)
        default:
            shape = SCNBox(width: 0.02, height: 0.02, length: 0.02, chamferRadius: 0)
        }
        shape.firstMaterial?.diffuse.contents = targetNode!.geometry?.firstMaterial?.diffuse.contents
        
        targetNode?.geometry = shape
    }
    
    func menuSteppedBack(owner: SCNNode, to depth: Int) {}
    func menuDidClose(owner: SCNNode) {
        openMenuNode = nil
    }
}
