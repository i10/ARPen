import Foundation
import CoreMotion

class DataRecorder {
    
    unowned var observedPlugin: StudyPlugin
    var recordManager: UserStudyRecordManager!
    
    private var timer: Timer? = nil
    private var motionManager: CMMotionManager = CMMotionManager()
    
    private var currentMeasurement: POI? = nil
    private var startTime: Date? = nil
    private var menuOpenTime: Date? = nil
    private var lastDevicePosition: SCNVector3? = nil
    private var lastDeviceOrientation: SCNVector3? = nil
    
    init(observedPlugin: StudyPlugin) {
        self.observedPlugin = observedPlugin
    }
    
    deinit {
        self.motionManager.stopDeviceMotionUpdates()
        self.timer?.invalidate()
    }
    
    func stopMeasure(saveDataPoint: Bool = true) {
        print("stop measuring")
        self.motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
        if saveDataPoint {
            saveMeasurement()
        }
    }
    
    func startMeasure(){
        print("measure start")
        currentMeasurement = POI()
        startTime = Date()
    }
    
    func wrongItemCorrectNode(item: Int, targetPosition: Int) {
        print("measure wrong item correct node")
        self.currentMeasurement?.failItemCorrectNode = 1
        measureOnItemSelection(itemPosition: item, targetPosition: targetPosition)
    }
    
    func wrongItemWrongNode(item: Int, targetPosition: Int) {
        print("measure wrong item wrong node")
        self.currentMeasurement?.failItemWrongNode = 1
        measureOnItemSelection(itemPosition: item, targetPosition: targetPosition)
    }
    
    func wrongNode() {
        print("measure wrong node")
        self.currentMeasurement?.wrongNode += 1
        resetToBeforeMenuOpening()
    }
    
    func deadZone(){
        print("measure dead zone")
        self.currentMeasurement?.failDeadZone += 1
        resetToBeforeMenuOpening()
    }
    
    func outside() {
        print("measure outside")
        self.currentMeasurement?.failOutSide += 1
        resetToBeforeMenuOpening()
    }
    
    func measureOnMenuOpen(){
        print("measure open")
        
        self.menuOpenTime = Date()
        self.currentMeasurement?.timeToOpenMenu = menuOpenTime!.timeIntervalSince(startTime!)
        self.motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)
        timer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true, block: { _ in
            self.updateMovement()
        })
    }
    
    func measureOnItemSelection(itemPosition: Int, targetPosition: Int){
        print("measure item")
        self.currentMeasurement?.timeToSelectItem = Date().timeIntervalSince(self.menuOpenTime!)
        self.currentMeasurement?.itemPosition = itemPosition
        self.currentMeasurement?.targetItemPosition = targetPosition
        stopMeasure()
    }
    
    func resetToBeforeMenuOpening() {
        currentMeasurement!.translationX = 0
        currentMeasurement!.translationY = 0
        currentMeasurement!.translationZ = 0
        currentMeasurement!.translationXAbsolute = 0
        currentMeasurement!.translationYAbsolute = 0
        currentMeasurement!.translationZAbsolute = 0
        currentMeasurement!.rotationAroundX = 0
        currentMeasurement!.rotationAroundY = 0
        currentMeasurement!.rotationAroundZ = 0
        currentMeasurement!.rotationAroundXAbsolute = 0
        currentMeasurement!.rotationAroundYAbsolute = 0
        currentMeasurement!.rotationAroundZAbsolute = 0
    }
    
    func updateMovement(){
        guard let  device = observedPlugin.pluginManager?.sceneView.pointOfView else { return }
        guard let deviceMotion = motionManager.deviceMotion else { return }
        
        var rotation = SCNVector3(deviceMotion.attitude.roll.radiansToDegrees, deviceMotion.attitude.yaw.radiansToDegrees, deviceMotion.attitude.pitch.radiansToDegrees)
        if rotation.z < 0 { rotation.z += 360}
        if rotation.y < 0 { rotation.y += 360}
        if rotation.x < 0 { rotation.x += 360}
        
        let position = device.convertVector(device.worldPosition, from: nil)
        
        
        
        if lastDevicePosition != nil && lastDeviceOrientation != nil && currentMeasurement != nil {
            
            let movement = position - lastDevicePosition!
            lastDevicePosition = position
            
            var rotationDifference = rotation - lastDeviceOrientation!
            if abs(rotationDifference.x) > 180 {
                rotationDifference.x = 360.0 * (rotationDifference.x >= 0 ? 1.0 : -1) - rotationDifference.x
            }
            if abs(rotationDifference.y) > 180 {
                rotationDifference.y = 360.0 * (rotationDifference.y >= 0 ? 1.0 : -1) - rotationDifference.y
            }
            if abs(rotationDifference.z) > 180 {
                rotationDifference.z = 360.0 * (rotationDifference.z >= 0 ? 1.0 : -1) - rotationDifference.z
            }
            lastDeviceOrientation = rotation
            
            currentMeasurement!.translationX += movement.x
            currentMeasurement!.translationY += movement.y
            currentMeasurement!.translationZ += movement.z
            currentMeasurement!.translationXAbsolute += movement.x.magnitude
            currentMeasurement!.translationYAbsolute += movement.y.magnitude
            currentMeasurement!.translationZAbsolute += movement.z.magnitude
            currentMeasurement!.rotationAroundX += rotationDifference.x
            currentMeasurement!.rotationAroundY += rotationDifference.y
            currentMeasurement!.rotationAroundZ += rotationDifference.z
            currentMeasurement!.rotationAroundXAbsolute += rotationDifference.x.magnitude
            currentMeasurement!.rotationAroundYAbsolute += rotationDifference.y.magnitude
            currentMeasurement!.rotationAroundZAbsolute += rotationDifference.z.magnitude
            
//            print("\(rotation.x), \(rotation.y), \(rotation.z)")
//            print("\(currentMeasurement!.rotationAroundXAbsolute), \(currentMeasurement!.rotationAroundYAbsolute), \(currentMeasurement!.rotationAroundZAbsolute)")
        } else {
            lastDevicePosition = position
            lastDeviceOrientation = rotation
        }
    }
    
    private func saveMeasurement() {
        
        let targetMeasurementDict: [String : String] = ["success": String(describing: currentMeasurement!.success),
                                                        "timeToOpenMenu": String(describing: currentMeasurement!.timeToOpenMenu),
                                                        "timeToSelectItem": String(describing: currentMeasurement!.timeToSelectItem),
                                                        "translationX": String(describing: currentMeasurement!.translationX),
                                                        "translationY": String(describing: currentMeasurement!.translationY),
                                                        "translationZ": String(describing: currentMeasurement!.translationZ),
                                                        "translationXAbsolute": String(describing: currentMeasurement!.translationXAbsolute),
                                                        "translationYAbsolute": String(describing: currentMeasurement!.translationYAbsolute),
                                                        "translationZAbsolute": String(describing: currentMeasurement!.translationZAbsolute),
                                                        "rotationAroundX": String(describing: currentMeasurement!.rotationAroundX),
                                                        "rotationAroundY": String(describing: currentMeasurement!.rotationAroundY),
                                                        "rotationAroundZ": String(describing: currentMeasurement!.rotationAroundZ),
                                                        "rotationAroundXAbsolute": String(describing: currentMeasurement!.rotationAroundXAbsolute),
                                                        "rotationAroundYAbsolute": String(describing: currentMeasurement!.rotationAroundYAbsolute),
                                                        "rotationAroundZAbsolute": String(describing: currentMeasurement!.rotationAroundZAbsolute),
                                                        "wrongNode": String(describing: currentMeasurement!.wrongNode),
                                                        "failOutSide": String(describing: currentMeasurement!.failOutSide),
                                                        "failDeadZone": String(describing: currentMeasurement!.failDeadZone),
                                                        "failItemCorrectNode": String(describing: currentMeasurement!.failItemCorrectNode),
                                                        "failItemWrongNode": String(describing: currentMeasurement!.failItemWrongNode),
                                                        "itemPosition": String(describing: currentMeasurement!.itemPosition),
                                                        "targetItemPosition": String(describing: currentMeasurement!.targetItemPosition)]
        observedPlugin.recordManager.addNewRecord(withIdentifier: self.observedPlugin.pluginIdentifier, andData: targetMeasurementDict)
        
//        print("success: \( String(describing: currentMeasurement!.success))")
//        print("timeToOpenMenu: \( String(describing: currentMeasurement!.timeToOpenMenu))")
//        print("timeToSelectItem: \( String(describing: currentMeasurement!.timeToSelectItem))")
//        print("translationX: \( String(describing: currentMeasurement!.translationX))")
//        print("translationY: \( String(describing: currentMeasurement!.translationY))")
//        print("translationZ: \( String(describing: currentMeasurement!.translationZ))")
//        print("translationXAbsolute: \( String(describing: currentMeasurement!.translationXAbsolute))")
//        print("translationYAbsolute: \( String(describing: currentMeasurement!.translationYAbsolute))")
//        print("translationZAbsolute: \( String(describing: currentMeasurement!.translationZAbsolute))")
//        print("rotationAroundX: \( String(describing: currentMeasurement!.rotationAroundX))")
//        print("rotationAroundY: \( String(describing: currentMeasurement!.rotationAroundY))")
//        print("rotationAroundZ: \( String(describing: currentMeasurement!.rotationAroundZ))")
//        print("rotationAroundXAbsolute: \( String(describing: currentMeasurement!.rotationAroundXAbsolute))")
//        print("rotationAroundYAbsolute: \( String(describing: currentMeasurement!.rotationAroundYAbsolute))")
//        print("rotationAroundZAbsolute: \( String(describing: currentMeasurement!.rotationAroundZAbsolute))")
//        print("wrongNode: \( String(describing: currentMeasurement!.wrongNode))")
//        print("failOutSide: \( String(describing: currentMeasurement!.failOutSide))")
//        print("failDeadZone: \( String(describing: currentMeasurement!.failDeadZone))")
//        print("failItemCorrectNode: \( String(describing: currentMeasurement!.failItemCorrectNode))")
//        print("failItemWrongNode: \( String(describing: currentMeasurement!.failItemWrongNode))")
//        print("itemPosition: \( String(describing: currentMeasurement!.itemPosition))")
    }
    
    
    private struct POI {
        var menuType: String = ""
        var success: Int {
            get { return failItemWrongNode + failItemCorrectNode > 0 ? 0 : 1}
        }
        var timeToOpenMenu: Double = 0
        var timeToSelectItem: Double = 0
        var translationX: Float = 0
        var translationY: Float = 0
        var translationZ: Float = 0
        var translationXAbsolute: Float = 0
        var translationYAbsolute: Float = 0
        var translationZAbsolute: Float = 0
        var rotationAroundX: Float = 0
        var rotationAroundY: Float = 0
        var rotationAroundZ: Float = 0
        var rotationAroundXAbsolute: Float = 0
        var rotationAroundYAbsolute: Float = 0
        var rotationAroundZAbsolute: Float = 0
        var wrongNode: Int = 0 // 0,1
        var failOutSide = 0 // 0,1
        var failDeadZone = 0 // 0,1
        var failItemCorrectNode = 0 // 0,1
        var failItemWrongNode = 0 // 0,1
        var itemPosition: Int = -4
        var targetItemPosition: Int = -4
    }
}
