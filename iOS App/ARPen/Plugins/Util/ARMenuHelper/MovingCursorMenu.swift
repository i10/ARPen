//
//  MovingCursorMenu.swift
//  ARPen
//
//  Created by Philipp Wacker on 30.09.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import SpriteKit
import ARKit

class MovingCursorMenu: MidairPieMenu {

    var cursorRadius: CGFloat = 0.005
    var cursorColor = #colorLiteral(red: 0.5347076058, green: 0.8940258026, blue: 0.9999745488, alpha: 1)

//    override var outerRadius: CGFloat {
//        didSet {
//            cursorRadius *= (outerRadius / oldValue)
//        }
//    }

    /// Node which is used to determine how the cursor moves
    var referenceNode: SCNNode? = nil
    var cursor: SKShapeNode? = nil

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(menu: Menu, path: [Int]) {
        super.init(menu: menu, path: path)
    }

    override func objectSelected(_ node: Selectable, intersectionAt intersection: SCNVector3, cursor: AREvent) {}

    func selectItem(){
        if let itemIndex = highlightedItem?.index {
            if itemIndex < 0 {
                stepBack()
            } else {
                menuDelegate?.menuItemSelected(owner: owner, label: menu.subMenus[itemIndex].label, indexPath: menu.subMenus[itemIndex].path, isLeaf: menu.subMenus[itemIndex].isLeaf)
                closeMenu(asAbort: false)
            }
        }
    }

    override func drawMenu() {
        super.drawMenu()

        cursor = SKShapeNode(circleOfRadius: cursorRadius * resolutionFactor)
        cursor!.fillColor = self.cursorColor
        cursor!.strokeColor = self.strokeColor
        cursor!.position = CGPoint(x: self.skScene!.frame.width / 2, y: self.skScene!.frame.height / 2)
        self.skScene?.addChild(cursor!)

    }

    ///Init projection point on the screen from which the menu's cursor will be controlled
    var initProjection: CGPoint? = nil

    override func updateMenu(penTip: SCNNode?, sceneView: SCNView){
        //Scale menu
        let scale = 1 / (Float(self.initDistance) / (sceneView.pointOfView!.worldPosition - self.worldPosition).length())
        self.scale = SCNVector3(scale, scale, scale)

            if let origin = self.initProjection {
                var plane = sceneView.pointOfView!.simdWorldTransform

                //Ugly code to rotate and position the plane :D
                let node = SCNNode()
                node.simdWorldTransform = plane
                node.worldPosition = self.worldPosition
                node.eulerAngles.x += .pi / 2
                plane = node.simdWorldTransform

                //Project screen point to 3D world
                if let hit = (sceneView as! ARSCNView).unprojectPoint(origin, ontoPlane: plane) {
                    let localPoint = self.convertPosition(SCNVector3(hit.x, hit.y, hit.z), from: nil)
                    var newCursorPosition = CGPoint(x: CGFloat(localPoint.x), y: -CGFloat(localPoint.y))
                    // Cursor should not leave the menu
                    if newCursorPosition.length() > self.outerRadius {
                        newCursorPosition = newCursorPosition.toLengthOf(self.outerRadius)
                    }
                    newCursorPosition = newCursorPosition * self.resolutionFactor
                    newCursorPosition = newCursorPosition + CGPoint(x: self.skScene!.frame.width / 2, y: self.skScene!.frame.height / 2)
                    self.cursor?.position = newCursorPosition
                }
            } else {
                let projectedPencilPosition = sceneView.projectPoint(self.worldPosition)
                self.initProjection = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
            }
            self.highlightItems()
    }

    func highlightItems() {

        let center = CGPoint(x: skScene!.frame.width / 2, y: skScene!.frame.height / 2)
        let angle = (self.cursor!.position - CGPoint(x: self.skScene!.frame.width / 2, y: self.skScene!.frame.height / 2)).angle()
        let index = Int((angle / (2 * .pi)) * CGFloat(menu.subMenus.count))

        if (cursor!.position - center).length() > self.innerRadius * self.resolutionFactor {
            self.highlightedItem = (index: index, item: items[index]!)
        } else {
            self.highlightedItem = (index: -1, item: backButton!)
        }
    }
}
