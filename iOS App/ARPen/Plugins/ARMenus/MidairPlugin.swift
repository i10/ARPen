import ARKit

class MidairPlugin: StudyPlugin{
    
    override init() {
        super.init()
        self.pluginImage = UIImage.init(named: "ARMenusMidAirPenPlugin")
        self.pluginIdentifier = "Mid-Air Pen"
        self.pluginGroupName = "ARMenus"
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        super.activatePlugin(withScene: scene, andView: view)
        
        pluginManager?.allowPenInput = true
        pluginManager?.allowTouchInput = false
        
        MenuManager.shared.menuType = .MidairPie
    }
    
    override func deactivatePlugin() {
        super.deactivatePlugin()
    }
    
    override func objectSelected(_ node: Selectable, intersectionAt intersection: SCNVector3, cursor: AREvent) {
        if cursor.eventType != .Ended { return }
        super.objectSelected(node, intersectionAt: intersection, cursor: cursor)
        if let m = arMenu as? MidairPieMenu {
            m.initDistance = CGFloat(((arMenu as! SCNNode).worldPosition - self.pluginManager!.sceneView.pointOfView!.worldPosition).length())
            
            //Resize the menu such that it fills the screen
            if let sceneView = self.pluginManager?.sceneView {
                
                let topPoint = CGPoint(x: 0 , y: Double(sceneView.frame.height))
                let bottomPoint = CGPoint(x: 0 , y: 0)
                
                // Create a plane which is parallel to the smartphone, has the same z coordinate as the menu and is then rotated around the x axis (according to sceneView.unprojectPoint)
                var plane = sceneView.pointOfView!.simdWorldTransform
                plane.columns.3.z = m.worldPosition.z
                //Ugly code to rotate the plane :D
                let node = SCNNode()
                node.simdWorldTransform = plane
                node.eulerAngles.x += .pi / 2
                plane = node.simdWorldTransform
                
                //Set the menu's radius accodring to the position of the projections
                guard let tPoint = sceneView.unprojectPoint(topPoint, ontoPlane: plane) else { return }
                guard let bPoint = sceneView.unprojectPoint(bottomPoint, ontoPlane: plane) else { return }
                m.outerRadius = CGFloat(SCNVector3(tPoint.x - bPoint.x, tPoint.y - bPoint.y, tPoint.z - bPoint.z).length() / 2 * 0.9)
            }
        }
    }
    
    override func onIdleMovement(to position: SCNVector3) {
        super.onIdleMovement(to: position)
        if let m = arMenu as? MidairPieMenu {
            m.updateMenu(penTip: self.pluginManager?.penScene.pencilPoint, sceneView: pluginManager!.sceneView)
        }
    }
    
    override func onPenClickEnded(at position: SCNVector3, releasedButton: Button) {
        super.onPenClickEnded(at: position, releasedButton: releasedButton)
    }
}
