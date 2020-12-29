import Foundation
import SpriteKit
import ARKit

class StudyPlugin: Plugin, PenDelegate, TouchDelegate, SelectionDelegate, UserStudyRecordPluginProtocol {
    
    var recordManager: UserStudyRecordManager!
    
    var dataRecorder: DataRecorder?
    
    //----------------------------------------------------------------------------------
    //MARK: Study objects
    
    /// Current open ARMenu
    internal var arMenu: ARMenu? = nil
    
    /// Holds the study nodes
    var sceneConstructionResults: (superNode: SCNNode, studyNodes: [ARPenStudyNode])? = nil
    /// Stores the target item positions
    var targetItemPosition: [Int] = []
    /// Indicates the target emoji
    var targetLabelNode: SKShapeNode? = nil
    /// Reference to the current ARPenBoxNode and the current index position.
    private var target: (index: Int, node: SelectableNode)? = nil {
        didSet {
            (oldValue?.node as? ARPenBoxNode)?.isActiveTarget = false
            (self.target?.node as? ARPenBoxNode)?.isActiveTarget = true
            oldValue?.node.menu = nil
            
            target?.node.menu = MenuContentCreater.shared.generateMenu()
            
            if target != nil {
                (targetLabelNode?.children.first as? SKLabelNode)?.text = getTargetEmoji()
            }
        }
    }
    
    /// In the test phase no data should be recorded
    var inTestPhase = false {
        didSet {
            self.sceneConstructionResults?.studyNodes.forEach({$0.inTrialState = inTestPhase})
            if !inTestPhase {
                setupFirstTarget()
            }
            switchToTestPhase(inTestPhase)
        }
    }
    
    var isPenTipHidden: Bool = false {
        didSet {
            self.pluginManager?.penScene.pencilPoint.isHidden = self.isPenTipHidden
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------
    //MARK: Setup and deactivate plugin
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        
        let sceneConstructor = ARPenGridSceneConstructor.init()
        self.sceneConstructionResults = sceneConstructor.preparedARPenNodes(withScene: pluginManager!.penScene, andView: pluginManager!.sceneView, andStudyNodeType: ARPenBoxNode.self)
        self.pluginManager?.penScene.drawingNode.addChildNode(self.sceneConstructionResults!.superNode)
        
        // Add target node references twice to the array such that every node is visited twice in the study
        for node in self.sceneConstructionResults?.studyNodes.shuffled() ?? [] {
            sceneConstructionResults?.studyNodes.append(node)
            
            //Since we are iterating anyway, also add the selectionDelegate here
            node.selectionDelegate = self
            node.setMenu(Menu(), menuItemSelected: itemSelected(node:label:indexPath:isLeaf:), didStepBack: didStepBack(node:to:), menuDidClose: menuDidClose(node:))
        }
        //self.sceneConstructionResults?.superNode.position.z -= 0.4
        
        self.inTestPhase = true
        self.setupFirstTarget()
        
        createOverlay()
        
        dataRecorder = DataRecorder(observedPlugin: self)
    }
    
    /// Generates new item order and sets the first target
    private func setupFirstTarget() {
        // Determine the target menu item order (4 repetitions for each menu item)
        self.targetItemPosition = [0,1,2,3,4,5,6,7].shuffled()
        for _ in 0 ... 2 { self.targetItemPosition.append(contentsOf: [0,1,2,3,4,5,6,7].shuffled()) }
        
        self.setTarget(to: 0)
        self.addUnmeasuredTarget()
    }
    
    override func deactivatePlugin() {
        self.arMenu?.closeMenu(asAbort: true)
        pluginManager?.penScene.drawingNode.childNodes.forEach({$0.removeFromParentNode()})
        self.sceneConstructionResults?.superNode.removeFromParentNode()
        
        self.sceneConstructionResults = nil
        arMenu = nil
        dataRecorder = nil
        
        self.targetLabelNode?.removeFromParent()
        //self.pluginManager?.sceneView.overlaySKScene = nil
        
        super.deactivatePlugin()
    }
    
    internal func createOverlay(){
        let skScene = SKScene(size: CGSize(width: 2688, height: 1242))
        skScene.isUserInteractionEnabled = false
        
        let targetLabelNode = SKLabelNode(text: target != nil ? getTargetEmoji() : "😅")
        targetLabelNode.fontSize = 150
        targetLabelNode.verticalAlignmentMode = .center
        targetLabelNode.horizontalAlignmentMode = .center
        
        let backgroundNode = SKShapeNode(circleOfRadius: targetLabelNode.frame.width / 1.5)
        backgroundNode.fillColor = .white
        backgroundNode.position = CGPoint(x: 2688 - targetLabelNode.frame.width, y: 1242 - targetLabelNode.frame.height - 10)
        backgroundNode.addChild(targetLabelNode)
        
        self.targetLabelNode = backgroundNode
        
        skScene.addChild(self.targetLabelNode!)
        
        self.pluginManager?.sceneView.overlaySKScene = skScene
    }
    
    private func renderPenTipFirst(_ renderFirst: Bool) {
        if let tip = self.pluginManager?.penScene.pencilPoint {
            tip.renderingOrder += renderFirst ? 30000 : -30000
            tip.geometry?.firstMaterial?.readsFromDepthBuffer = !renderFirst
        }
    }
    
    func switchToTestPhase(_ switchToTestPhase: Bool){
        let nodeName = "start sign"
        
        if switchToTestPhase {
            let startSign = ARPenPlaneNode(withPosition: SCNVector3Zero, andDimension: 1)
            startSign.geometry = SCNPlane(width: 0.1, height: 0.02)
            let signScene = SKScene(size: CGSize(width: 500, height: 100))
            let signNode = SKLabelNode(text: "Start recording")
            signNode.fontSize = 75
            signNode.verticalAlignmentMode = .center
            signNode.horizontalAlignmentMode = .center
            signNode.position = CGPoint(x: signScene.frame.width / 2, y: signScene.frame.height / 2)
            signNode.yScale *= -1
            
            signScene.backgroundColor = .orange
            signScene.addChild(signNode)
            startSign.geometry?.firstMaterial?.diffuse.contents = signScene
            
            startSign.name = nodeName
            startSign.position = SCNVector3(0.20, 0, 0)
            startSign.eulerAngles.x -= .pi / 2
            startSign.geometry?.firstMaterial?.isDoubleSided = true
            startSign.selectionDelegate = self
            
            self.pluginManager?.penScene.drawingNode.addChildNode(startSign)
        } else {
            self.pluginManager?.penScene.drawingNode.childNode(withName: nodeName, recursively: true)?.removeFromParentNode()
        }
    }
    
    func finishedTreatment(){
        self.pluginManager?.allowPenInput = false
        self.pluginManager?.allowTouchInput = false
        
        
        guard let scene = self.pluginManager?.sceneView.overlaySKScene else { return }
        
        let backgroundNode = SKShapeNode(rect: CGRect(x: scene.frame.width * 0.125, y: scene.frame.height * 0.125, width: scene.frame.width * 0.75, height: scene.frame.height * 0.75), cornerRadius: 10)
        backgroundNode.fillColor = .white
        
        let doneSign = SKLabelNode(text: "You're done!\n Ask the conductor how to continue.")
        doneSign.fontSize = 60
        doneSign.fontColor = .black
        doneSign.position = CGPoint(x: scene.frame.width / 2, y: scene.frame.height / 2)
        doneSign.verticalAlignmentMode = .center
        doneSign.horizontalAlignmentMode = .center
        
        backgroundNode.addChild(doneSign)
        scene.addChild(backgroundNode)
    }
    
    //-----------------------------------------------------------------------------------------
    //MARK: Setting target
    
    private func setTarget(to index: Int){
        guard let nodes = self.sceneConstructionResults?.studyNodes else {
            target = nil
            return
        }
        
        if index < nodes.count {
            target = (index, nodes[index])
        } else {
            self.target = nil
            self.inTestPhase = true
            
            finishedTreatment()
        }
    }
    
    private func nextTarget() {
        if let index = target?.index {
            setTarget(to: index + 1)
        }
        
        // Number of trials should not be limited
        if self.inTestPhase && self.target == nil{
            setTarget(to: 0)
        }
    }
    
    func addUnmeasuredTarget() {
        if inTestPhase { return }
        
        guard let randomTarget = self.sceneConstructionResults?.studyNodes[Int.random(in: 2 ..< 15)] else { return }
        randomTarget.name = "ignore"
        targetItemPosition.insert(Int.random(in: 0 ..< 8), at: target!.index)
        self.sceneConstructionResults?.studyNodes.insert(randomTarget, at: target!.index)
        setTarget(to: target!.index)
    }
    
    private func getTargetEmoji() -> String? {
        guard let tNode = self.target else { return nil }
        return tNode.node.menu?.subMenus[self.targetItemPosition[tNode.index]].label
    }
    
    func repeatTarget() {
        if arMenu != nil {
            arMenu!.closeMenu(asAbort: true)
        }
        if target?.index == 0 { return }
        dataRecorder?.stopMeasure(saveDataPoint: false)
        
        if target?.node.name == "ignore" {
            target?.node.name = nil
            self.sceneConstructionResults?.studyNodes.remove(at: target!.index)
            self.targetItemPosition.remove(at: target!.index)
        }
        
        let index = (target!.index) - 1
        
        if recordManager.currentActiveUserID != nil{
            recordManager.deleteLastRecord(forID: recordManager.currentActiveUserID!)
        }
        
        setTarget(to: index)
        addUnmeasuredTarget()
    }
    
    //-----------------------------------------------------------------------------------------------------------
    //MARK: Measurement methods
    
    private func startMeasure(){
        if inTestPhase || target?.node.name == "ignore" { return }
        
        dataRecorder?.startMeasure()
    }
    
    private func measureOnMenuOpened(){
        if inTestPhase || target?.node.name == "ignore" { return }
        
        dataRecorder?.measureOnMenuOpen()
    }
    
    private func measureOnItemSelection(item: Int){
        if inTestPhase || target?.node.name == "ignore" { return }
        
        dataRecorder?.measureOnItemSelection(itemPosition: item, targetPosition: self.targetItemPosition[self.target!.index])
        //print(target!.index)
    }
    
    private func measureSelectionFailed(reason: String, itemPosition: Int = -5) {
        if inTestPhase || target?.node.name == "ignore" { return }
        
        switch reason {
        case "wrong item correct node":
            dataRecorder?.wrongItemCorrectNode(item: itemPosition, targetPosition: self.targetItemPosition[self.target!.index])
        case "wrong item wrong node":
            dataRecorder?.wrongItemWrongNode(item: itemPosition, targetPosition: self.targetItemPosition[self.target!.index])
        case "wrong node":
            dataRecorder?.wrongNode()
        case "outside":
            dataRecorder?.outside()
        case "step back":
            dataRecorder?.deadZone()
        default:
            break
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------
    //MARK: Selection and Menu Delegates
    
    func objectSelected(_ node: Selectable, intersectionAt intersection: SCNVector3, cursor: AREvent) {
        if cursor.eventType == .Began { return }
        var didWeJustOpenedAMenu = false
        
        if (node as! SCNNode).name == "start sign" {
            self.inTestPhase = false
        }
        else if (node as! SelectableNode) == target!.node {
            arMenu = (node as! SelectableNode).openContextMenu()
            didWeJustOpenedAMenu = true
            measureOnMenuOpened()
        }
        else if self.arMenu != nil {
            MenuManager.shared.closeMenu()
        }
        else {
            // Not target node:
            // Create a menu which does not include the targetEmoji
            var menu = MenuContentCreater.shared.generateMenu()
            var menuContainsTargetEmoji = true
            
            while menuContainsTargetEmoji {
                menuContainsTargetEmoji = false
                for subMenu in menu.subMenus {
                    if subMenu.label == getTargetEmoji() {
                        menuContainsTargetEmoji = true
                        break
                    }
                }
                
                //Retry
                if menuContainsTargetEmoji {
                    menu = MenuContentCreater.shared.generateMenu()
                }
            }
            
            (node as! SelectableNode).menu = menu
            arMenu = (node as! SelectableNode).openContextMenu()
            didWeJustOpenedAMenu = true
            measureSelectionFailed(reason: "wrong node")
            measureOnMenuOpened()
        }
        
        if didWeJustOpenedAMenu {
            renderPenTipFirst(true)
        }
    }
    
    func itemSelected(node: SCNNode?, label: String, indexPath: [Int], isLeaf: Bool) {
        if label == getTargetEmoji() {
            self.measureOnItemSelection(item: indexPath.last ?? -5)
        } else if node == target?.node {
            measureSelectionFailed(reason: "wrong item correct node", itemPosition: indexPath.last ?? -5)
        } else {
            measureSelectionFailed(reason: "wrong item wrong node", itemPosition: indexPath.last ?? -5)
        }
        
        nextTarget()
        startMeasure()
        
        self.arMenu = nil
        renderPenTipFirst(false)
        
        if node?.name == "ignore" {
            node!.name = nil
            self.target?.index -= 1
            self.targetItemPosition.remove(at: target!.index)
            self.sceneConstructionResults?.studyNodes.remove(at: target!.index)
            self.setTarget(to: self.target!.index)
        }
    }
    
    func menuDidClose(node: SCNNode?) {
        self.arMenu = nil
        renderPenTipFirst(false)
        
        if node == target?.node {
            measureSelectionFailed(reason: "outside")
        }
    }
    
    /// Holds the curretly highlighted node. This means that the pen tip occludes the object
    private var hightlightedNode: ARPenStudyNode? = nil {
        didSet {
            oldValue?.highlighted = false
            self.hightlightedNode?.highlighted = true
        }
    }
    
    func didStepBack(node: SCNNode?, to depth: Int) {
        self.arMenu = nil
        if node == target?.node {
            measureSelectionFailed(reason: "step back")
        }
    }
    
    func onIdleMovement(to position: SCNVector3) {
        if arMenu == nil && !isPenTipHidden {
            DispatchQueue(label: "Target node highlighting queue").async {
                if let pluginManager = self.pluginManager {
                    let projectedPencilPosition = pluginManager.sceneView.projectPoint(pluginManager.penScene.pencilPoint.position)
                    let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
                    let hitResults = pluginManager.sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
                    self.hightlightedNode = hitResults.filter({$0.node is SelectableNode && $0.node is ARPenStudyNode}).first?.node as? ARPenStudyNode
                } else {
                    self.hightlightedNode = nil
                }
            }
        }
    }

    func onPenClickStarted(at position: SCNVector3, startedButton: Button) {}
    func onPenClickEnded(at position: SCNVector3, releasedButton: Button) {}
    func onPenMoved(to position: SCNVector3, clickedButtons: [Button]) {}
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
}
