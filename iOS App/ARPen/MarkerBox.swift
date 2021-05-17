//
//  MarkerBox.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//
import SceneKit

/**
 The MarkerBox represents the Box on the ARPen. It simplifies some mathamtics.
 */
class MarkerBox: SCNNode {
    
    private var markerArray: [SCNNode]
    var penTipPositionHistory: [SCNVector3] = []
    var penLength: Double = 12
    
    static private var secureCoding = true
    override public class var supportsSecureCoding: Bool { return secureCoding }
    let positionFilter = PositionFilter(alphaValue: 0.5, gammaValue: 0.5, slerpFactor: 0.5)
    
    var currentModel = ARPenModelKeys.original
    
    /**
     * Describes in which landscape orientation the device is currently hold
     * If the device is hold in portrait orientation, the state keeps in the last landscape state
     */
    private var orientationState: DeviceOrientationState = .HomeButtonRight {
        didSet {
            //For each orientation the pen tip has to be calculated
            calculatePenTip(length: self.penLength, model: self.currentModel)
        }
    }
    
    override convenience init() {
        self.init(length: UserDefaults.standard.double(forKey: UserDefaultsKeys.penLength.rawValue),
                  model: ARPenModelKeys(rawValue: UserDefaults.standard.integer(forKey: UserDefaultsKeys.arPenModel.rawValue))!
        )
    }
    
    init(length: Double, model: ARPenModelKeys) {
        markerArray = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(),SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(),SCNNode(),SCNNode(),SCNNode(),SCNNode(),SCNNode(),SCNNode()]
        self.penLength = length
        self.currentModel = model
        super.init()
        
        self.name = "MarkerBox"
        
        //Observe device orientation. If orientation changes rotated() is called
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        //set orientationState to the current device orientation
        rotated()
        
        //Make pen tip calculation
        calculatePenTip(length: length, model: model)
    }
    
    func updatePenTipCalculations()
    {
        //set current pen length stored in user defaults
        self.penLength = Double(UserDefaults.standard.float(forKey: UserDefaultsKeys.penLength.rawValue))
        //set current arpen model stored in user defaults
        self.currentModel = ARPenModelKeys(rawValue: UserDefaults.standard.integer(forKey: UserDefaultsKeys.arPenModel.rawValue))!
        //check current device rotation (which triggers pen tip recalculation)
        rotated()
        self.calculatePenTip(length: self.penLength, model: self.currentModel)
    }
    
    @objc func rotated(){
        if UIDevice.current.orientation.rawValue == 4 {
            orientationState = .HomeButtonLeft
        } else if UIDevice.current.orientation.rawValue == 3 {
            orientationState = .HomeButtonRight
        }
    }
    
    func calculatePenTip(length: Double, model: ARPenModelKeys){
            //var penLength: Double = length //measured from center of the cube to the pen tip. In meters
            let cubeSideLength: Double = 0.03 //in meters
            let markerOffset: Double = 0.001 //x & y offset of marker from center of the cube's side. For "close" markers. In meters
            let markerOffsetSmall: Double = 0.0006 //x & y offset of marker from center of the cube's side. For "close" markers. In meters
            // translation values from the detected marker position to the pen tip
            var xTranslationCloseBack, yTranslationCloseBack, zTranslationCloseBack,//translation values for the sides of the cube closer to the stem of the pen -> "close" markers
                xTranslationAwayBack, yTranslationAwayBack, zTranslationAwayBack, //translation values for the sides of the cube away from the stem of the pen -> "away" markers
                xTranslationCloseFront, yTranslationCloseFront, zTranslationCloseFront,//translation values for the sides of the cube closer to the stem of the pen -> "close" markers
                xTranslationAwayFront, yTranslationAwayFront, zTranslationAwayFront, //translation values for the sides of the cube away from the stem of the pen -> "away" markers
                xTranslationCloseTopMid, yTranslationCloseTopMid, zTranslationCloseTopMid,//translation values for the sides of the cube closer to the stem of the pen -> "close" markers
                xTranslationAwayTopMid, yTranslationAwayTopMid, zTranslationAwayTopMid, //translation values for the sides of the cube away from the stem of the pen -> "away" markers
                xTranslationMidTip, yTranslationMidTip, zTranslationMidTip,
                xCHIARPen, yCHIARPen,       //CHI = CHI 2019, Glasgow
                xLMARPen, yLMARPen: Double  //LM = Laser Messe, Munich
            
            
            //angle between the stem of the pen and the floor when the cube is standing on the floor (=angle between the adjacent side and hypothenuse of the triangle of diagonal of one side (adjacent side) and length of cube side (opposite side))
            let angle = (35.26).degreesToRadians
            let angleMidTip = (54.74).degreesToRadians
            
            
            var backToTipLength: Double = 0
            var midToTipLength: Double = 0
            
            let frontToTipLength: Double = -0.031 //constant
            let topToMidLength: Double = 0.0370 //constant
            let frontToTippSmallLength: Double = -0.018 //constant
            
            
            xTranslationMidTip = 0
            yTranslationMidTip = 0
            zTranslationMidTip = 0
            
            switch (model) {
            case ARPenModelKeys.original:
                break
            case ARPenModelKeys.rBack:
                backToTipLength  = 0.140
            case ARPenModelKeys.rTop:
                midToTipLength   = 0.0635
            case ARPenModelKeys.rBackFront:
                backToTipLength  = 0.184
            case ARPenModelKeys.rBackTop:
                backToTipLength  = 0.140
                midToTipLength   = 0.0635
            case ARPenModelKeys.rTopFront:
                midToTipLength   = 0.108
            case ARPenModelKeys.rBackFrontSmall:
                backToTipLength  = 0.166
            default:
                backToTipLength  = 0.140
                midToTipLength   = 0.0635
            }
                
            //BACKMODELPART START
            if(model == ARPenModelKeys.rBack || model == ARPenModelKeys.rBackFront || model == ARPenModelKeys.rBackTop || model == ARPenModelKeys.rBackFrontSmall ){
                //calculation of translation values for the "close" markers. The calculations assume looking along the z Axis in positive direction (directly onto the marker)
                //for z, first move from position of the marker into the center of the cube (positive Z -> inside the cube)
                zTranslationCloseBack = 0.5 * cubeSideLength
                //second, apply translation to the z position of the pen tip (from the marker's coordinate system)
                zTranslationCloseBack -= (sin(angle) * backToTipLength)
                
                //for x, first correct the marker offset to move to the center of the cube's side
                xTranslationCloseBack = -markerOffset
                //second, apply translation to the x position of the pen tip (from the marker's coordinate system)
                xTranslationCloseBack -= ((cos(angle) * backToTipLength)/sqrt(2))
                //since the translations for y is the same as for x, copy the calculation
                yTranslationCloseBack = xTranslationCloseBack
                
                
                //calculation of translation values for the "away" markers. The calculations assume looking along the z Axis in positive direction (directly onto the marker)
                //for z, first move from position of the marker into the center of the cube (positive Z -> inside the cube)
                zTranslationAwayBack = 0.5 * cubeSideLength
                //second, apply translation to the z position of the pen tip (from the marker's coordinate system)
                zTranslationAwayBack += (sin(angle) * backToTipLength)
                
                //for x, apply translation to the x position of the pen tip (from the marker's coordinate system)
                xTranslationAwayBack = -(cos(angle) * backToTipLength)/sqrt(2)
                //since the translations for y is the same as for x, copy the calculation
                yTranslationAwayBack = xTranslationAwayBack
            } else {
                xTranslationCloseBack = -markerOffset
                yTranslationCloseBack = -markerOffset
                zTranslationCloseBack = 0
                xTranslationAwayBack = 0
                yTranslationAwayBack = 0
                zTranslationAwayBack = 0
            }
            //BACKMODELPART END
            
            
            
            //FRONTMODELPART START
            if(model == ARPenModelKeys.rFront || model == ARPenModelKeys.rBackFront || model == ARPenModelKeys.rTopFront ){
                //calculation of translation values for the "close" markers. The calculations assume looking along the z Axis in positive direction (directly onto the marker)
                //for z, first move from position of the marker into the center of the cube (positive Z -> inside the cube)
                zTranslationCloseFront = 0.5 * cubeSideLength
                //second, apply translation to the z position of the pen tip (from the marker's coordinate system)
                zTranslationCloseFront -= (sin(angle) * frontToTipLength)
                
                //for x, first correct the marker offset to move to the center of the cube's side
                xTranslationCloseFront = -markerOffset
                //second, apply translation to the x position of the pen tip (from the marker's coordinate system)
                xTranslationCloseFront -= ((cos(angle) * frontToTipLength)/sqrt(2))
                //since the translations for y is the same as for x, copy the calculation
                yTranslationCloseFront = xTranslationCloseFront
                
                
                //calculation of translation values for the "away" markers. The calculations assume looking along the z Axis in positive direction (directly onto the marker)
                //for z, first move from position of the marker into the center of the cube (positive Z -> inside the cube)
                zTranslationAwayFront = 0.5 * cubeSideLength
                //second, apply translation to the z position of the pen tip (from the marker's coordinate system)
                zTranslationAwayFront += (sin(angle) * frontToTipLength)
                
                //for x, apply translation to the x position of the pen tip (from the marker's coordinate system)
                xTranslationAwayFront = -(cos(angle) * frontToTipLength)/sqrt(2)
                //since the translations for y is the same as for x, copy the calculation
                yTranslationAwayFront = xTranslationAwayFront
            } else {
                xTranslationCloseFront = -markerOffset
                yTranslationCloseFront = -markerOffset
                zTranslationCloseFront = 0
                xTranslationAwayFront = 0
                yTranslationAwayFront = 0
                zTranslationAwayFront = 0
            }
            //FRONTMODELPART END
            
            //SMALLMODEL START
            if(model == ARPenModelKeys.rBackFrontSmall ){
                //calculation of translation values for the "close" markers. The calculations assume looking along the z Axis in positive direction (directly onto the marker)
                //for z, first move from position of the marker into the center of the cube (positive Z -> inside the cube)
                zTranslationCloseFront = 0.5 * cubeSideLength
                //second, apply translation to the z position of the pen tip (from the marker's coordinate system)
                zTranslationCloseFront -= (sin(angle) * frontToTippSmallLength)
                
                //for x, first correct the marker offset to move to the center of the cube's side
                xTranslationCloseFront = -markerOffsetSmall
                //second, apply translation to the x position of the pen tip (from the marker's coordinate system)
                xTranslationCloseFront -= ((cos(angle) * frontToTippSmallLength)/sqrt(2))
                //since the translations for y is the same as for x, copy the calculation
                yTranslationCloseFront = xTranslationCloseFront
                
                
                //calculation of translation values for the "away" markers. The calculations assume looking along the z Axis in positive direction (directly onto the marker)
                //for z, first move from position of the marker into the center of the cube (positive Z -> inside the cube)
                zTranslationAwayFront = 0.5 * cubeSideLength
                //second, apply translation to the z position of the pen tip (from the marker's coordinate system)
                zTranslationAwayFront += (sin(angle) * frontToTippSmallLength)
                
                //for x, apply translation to the x position of the pen tip (from the marker's coordinate system)
                xTranslationAwayFront = -(cos(angle) * frontToTippSmallLength)/sqrt(2)
                //since the translations for y is the same as for x, copy the calculation
                yTranslationAwayFront = xTranslationAwayFront
            }
            //SMALLMODEL END
            
            
            // TOPMODELPART START
            if(model == ARPenModelKeys.rTop || model == ARPenModelKeys.rBackTop || model == ARPenModelKeys.rTopFront ){
                //FIRST TRANSLATION
                zTranslationCloseTopMid = 0.5 * cubeSideLength
                zTranslationCloseTopMid -= topToMidLength * sin(angle)
                
                xTranslationCloseTopMid = -markerOffset
                xTranslationCloseTopMid -= (cos(angle) * topToMidLength)/sqrt(2)
                yTranslationCloseTopMid = xTranslationCloseTopMid
                
                zTranslationAwayTopMid = 0.5 * cubeSideLength
                zTranslationAwayTopMid += topToMidLength * sin(angle)
                xTranslationAwayTopMid = -(cos(angle) * topToMidLength)/sqrt(2)
                yTranslationAwayTopMid = xTranslationAwayTopMid
                
                //SECOND TRANSLATION
                zTranslationMidTip = midToTipLength * sin(angleMidTip)
                xTranslationMidTip = -(cos(angleMidTip) * midToTipLength)/sqrt(2)
                yTranslationMidTip = xTranslationMidTip
            } else {
                xTranslationCloseTopMid = -markerOffset
                yTranslationCloseTopMid = -markerOffset
                zTranslationCloseTopMid = 0
                xTranslationAwayTopMid = 0
                yTranslationAwayTopMid = 0
                zTranslationAwayTopMid = 0
                xTranslationMidTip = 0
                yTranslationMidTip = 0
                xTranslationMidTip = 0
            }
            //TOPMODELPART END
            
            
            
            // Calculate the translation vector for full-sized business card ARPen used for CHI 2019, Scotland, 2019.
            let markerOffsetFromBottomForCHIARPen: Double = 0.01975 // distance from the bottom of the card to the center of the marker
            let widthOfCHIARPen = 0.085
            let heightOfCHIARPen = 0.055
            
            xCHIARPen = 0.75 * widthOfCHIARPen // assuming marker center is at three-fourths of the card width
            yCHIARPen = heightOfCHIARPen - markerOffsetFromBottomForCHIARPen // height of the card is 5.5 cm
            
            // Calculate the translation vector for half-sized business card ARPen used for Laser Messe, Munich, 2019.
            let markerOffsetFromBottomForLaserMesseARPen: Double = 0.01375; // distance from the bottom of the card to the center of the marker
            let heightOfLaserMesseARPen = 0.0275;
            
            xLMARPen = 0.0713; // marker's center distance from the left edge of the card
            yLMARPen = heightOfLaserMesseARPen/2 - markerOffsetFromBottomForLaserMesseARPen;
            
            
            var i = 0
            for marker in markerArray {
                marker.name = "Marker #\(i+1)"
                marker.childNodes.first?.removeFromParentNode()
                
                let markerFace = MarkerFace(rawValue: i+1) ?? .notExpected
                guard markerFace != .notExpected else {
                    fatalError("markerArray shouldn't be longer than 6 elements!")
                }
                
                let point = SCNNode()
                point.name = "Point from #\(i+1)"
                
                //for rotation: for simplicity, take the top rotation as the basis. rotate other markers to fit the top orientation and then apply the same rotation to the pen tip
                let quaternionFromTopMarkerToPenTip = simd_quatf(angle: Float(-54.74.degreesToRadians), axis: float3(x: 0.707, y: -0.707, z: 0))
                switch (markerFace) {
                case (.B_back):
                    point.position = SCNVector3(xTranslationCloseBack, yTranslationCloseBack, zTranslationCloseBack)
                    point.eulerAngles = SCNVector3(x: 0, y: -Float.pi/2, z: -Float.pi/2)
                    //in case of HomeButtonLeft the orientation has to be rotated another 180 degrees after Rotation to top marker
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.B_top):
                    point.position = SCNVector3(xTranslationCloseBack, yTranslationCloseBack, zTranslationCloseBack)
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.B_right):
                    point.position = SCNVector3(xTranslationCloseBack, yTranslationCloseBack, zTranslationCloseBack)
                    point.eulerAngles = SCNVector3(x: Float.pi/2, y: 0, z: Float.pi/2)
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.B_bottom):
                    point.position = SCNVector3(xTranslationAwayBack, yTranslationAwayBack, zTranslationAwayBack)
                    point.eulerAngles.y = Float.pi
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.B_left):
                    point.position = SCNVector3(xTranslationAwayBack, yTranslationAwayBack, zTranslationAwayBack)
                    point.eulerAngles.x = -Float.pi/2
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.B_front):
                    point.position = SCNVector3(xTranslationAwayBack, yTranslationAwayBack, zTranslationAwayBack)
                    point.eulerAngles = SCNVector3(x: 0, y: Float.pi/2, z: Float.pi/2)
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.F_back):
                    point.position = SCNVector3(xTranslationCloseFront, yTranslationCloseFront, zTranslationCloseFront)
                    point.eulerAngles = SCNVector3(x: 0, y: -Float.pi/2, z: -Float.pi/2)
                    //in case of HomeButtonLeft the orientation has to be rotated another 180 degrees after Rotation to top marker
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.F_top):
                    point.position = SCNVector3(xTranslationCloseFront, yTranslationCloseFront, zTranslationCloseFront)
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.F_right):
                    point.position = SCNVector3(xTranslationCloseFront, yTranslationCloseFront, zTranslationCloseFront)
                    point.eulerAngles = SCNVector3(x: Float.pi/2, y: 0, z: Float.pi/2)
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.F_bottom):
                    point.position = SCNVector3(xTranslationAwayFront, yTranslationAwayFront, zTranslationAwayFront)
                    point.eulerAngles.y = Float.pi
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.F_left):
                    point.position = SCNVector3(xTranslationAwayFront, yTranslationAwayFront, zTranslationAwayFront)
                    point.eulerAngles.x = -Float.pi/2
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.F_front):
                    point.position = SCNVector3(xTranslationAwayFront, yTranslationAwayFront, zTranslationAwayFront)
                    point.eulerAngles = SCNVector3(x: 0, y: Float.pi/2, z: Float.pi/2)
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                case (.T_back):
                    point.position = SCNVector3(xTranslationCloseTopMid + zTranslationMidTip, yTranslationCloseTopMid + xTranslationMidTip, zTranslationCloseTopMid + yTranslationMidTip)
                    point.eulerAngles = SCNVector3(x: 0, y: -Float.pi/2, z: -Float.pi/2)
                    //in case of HomeButtonLeft the orientation has to be rotated another 180 degrees after Rotation to top marker
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.T_top):
                    point.position = SCNVector3(xTranslationCloseTopMid + xTranslationMidTip, yTranslationCloseTopMid + yTranslationMidTip, zTranslationCloseTopMid + zTranslationMidTip)
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.T_right):
                    point.position = SCNVector3(xTranslationCloseTopMid + xTranslationMidTip, yTranslationCloseTopMid + zTranslationMidTip, zTranslationCloseTopMid + yTranslationMidTip)
                    point.eulerAngles = SCNVector3(x: Float.pi/2, y: 0, z: Float.pi/2)
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.T_bottom):
                    point.position = SCNVector3(xTranslationAwayTopMid + xTranslationMidTip, yTranslationAwayTopMid + yTranslationMidTip, zTranslationAwayTopMid - zTranslationMidTip)
                    point.eulerAngles.y = Float.pi
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.T_left):
                    point.position = SCNVector3(xTranslationAwayTopMid + xTranslationMidTip, yTranslationAwayTopMid + zTranslationMidTip, zTranslationAwayTopMid - yTranslationMidTip)
                    point.eulerAngles.x = -Float.pi/2
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.T_front):
                    point.position = SCNVector3(xTranslationAwayTopMid + zTranslationMidTip, yTranslationAwayTopMid + yTranslationMidTip, zTranslationAwayTopMid - xTranslationMidTip)
                    point.eulerAngles = SCNVector3(x: 0, y: Float.pi/2, z: Float.pi/2)
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                case (.S_back):
                    point.position = SCNVector3(xTranslationCloseFront, yTranslationCloseFront, zTranslationCloseFront)
                    point.eulerAngles = SCNVector3(x: 0, y: -Float.pi/2, z: -Float.pi/2)
                    //in case of HomeButtonLeft the orientation has to be rotated another 180 degrees after Rotation to top marker
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.S_top):
                    point.position = SCNVector3(xTranslationCloseFront, yTranslationCloseFront, zTranslationCloseFront)
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.S_right):
                    point.position = SCNVector3(xTranslationCloseFront, yTranslationCloseFront, zTranslationCloseFront)
                    point.eulerAngles = SCNVector3(x: Float.pi/2, y: 0, z: Float.pi/2)
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.S_bottom):
                    point.position = SCNVector3(xTranslationAwayFront, yTranslationAwayFront, zTranslationAwayFront)
                    point.eulerAngles.y = Float.pi
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.S_left):
                    point.position = SCNVector3(xTranslationAwayFront, yTranslationAwayFront, zTranslationAwayFront)
                    point.eulerAngles.x = -Float.pi/2
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                    point.simdLocalRotate(by: quaternionFromTopMarkerToPenTip)
                case (.S_front):
                    point.position = SCNVector3(xTranslationAwayFront, yTranslationAwayFront, zTranslationAwayFront)
                    point.eulerAngles = SCNVector3(x: 0, y: Float.pi/2, z: Float.pi/2)
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                case (.CHIARPen):
                    point.position = SCNVector3(-xCHIARPen, -yCHIARPen, 0)
                    point.eulerAngles = SCNVector3(x: 0, y: -Float.pi/2, z: Float(-135.degreesToRadians))
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                case (.laserMesseARPen):
                    point.position = SCNVector3(-xLMARPen, -yLMARPen, 0)
                    point.eulerAngles = SCNVector3(x: 0, y: -Float.pi/2, z: Float(-135.degreesToRadians))
                    if orientationState == .HomeButtonLeft {
                        point.eulerAngles.z += Float.pi
                    }
                default:
                    break
                }
                
                //Invert the coordinates in landscape homebutton left
                if orientationState == .HomeButtonLeft {
                    point.position.x *= -1
                    point.position.y *= -1
                }
                
                marker.addChildNode(point)
                if !self.childNodes.contains(marker){
                    self.addChildNode(marker)
                }
                
                i += 1
            }
        }
    
    /**
     Sets the position and rotation (in euler angles) for a specific ID.
     */
    func set(position: SCNVector3, rotation: SCNVector3, forID id: MarkerFace) {
        self.markerArray[id.rawValue-1].position = position
        self.markerArray[id.rawValue-1].eulerAngles = rotation
        
        //If orientation is Landscape with home button left we have to revert x and y axis and marker orientation
        if orientationState == .HomeButtonLeft {
            self.markerArray[id.rawValue-1].position.x *= -1
            self.markerArray[id.rawValue-1].position.y *= -1
            
            self.markerArray[id.rawValue-1].eulerAngles.x *= -1
            self.markerArray[id.rawValue-1].eulerAngles.y *= -1
        }
    }
    
    /**
     Determine the position of the pin point by ONLY considering the specified IDs
     - parameter ids: A list of marker IDs that are used to determine the position
     */
    func positionWith(ids: [MarkerFace]) -> SCNNode {
        //hold the computed pen tip properties for each marker -> can be averaged to return pen tip node
        var penTipPosition = SCNVector3Zero
        var penTipOrientation = simd_quatf.init(ix: 0, iy: 0, iz: 0, r: 1)
        var mutableIds : [MarkerFace] = ids
        
        if mutableIds.count == 3 {
            let allowedDeviation: Float = 1.2 //Don't forget that some markers are not perfectly in the middle of the cube's face!
            
            //Calculate distances
            let distance12 = markerArray[0].position.distance(vector: markerArray[1].position)
            let distance13 = markerArray[0].position.distance(vector: markerArray[2].position)
            let distance23 = markerArray[1].position.distance(vector: markerArray[2].position)
            
            //If distance of one marker to another one deviates too much from the other inter-marker distances, this point is removed from calculation
            if distance12 > allowedDeviation * distance23 && distance13 > allowedDeviation * distance23 {
                //Point 1 offsetted
                mutableIds.remove(at: 0)
            } else if distance12 > allowedDeviation * distance13 && distance23 > allowedDeviation * distance13 {
                //Point 2 offsetted
                mutableIds.remove(at: 1)
            } else if distance13 > 1.3 * distance12 && distance23 > 1.3 * distance12 {
                //Point 3 offsetted
                mutableIds.remove(at: 2)
            }
        }
        
        //average orientation between seen markers (averaging of rotation adapted from: https://answers.unity.com/questions/815266/find-and-average-rotations-together.html)
        var counter : Float = 0
        for id in mutableIds {
            let candidateNode = SCNNode()
            let transform = self.markerArray[id.rawValue-1].childNodes.first!.convertTransform(SCNMatrix4Identity, to: nil)
            
            candidateNode.transform = transform
            penTipPosition += candidateNode.position
            
            counter += 1
            penTipOrientation = simd_slerp(penTipOrientation, candidateNode.simdOrientation, 1.0/counter)
        }
        
        penTipPosition /= Float(mutableIds.count)
        
        //apply smoothing to pen position & orientation
        penTipPosition = self.positionFilter.filteredPositionAfter(newPosition: penTipPosition)
        penTipOrientation = self.positionFilter.filteredOrientationAfter(newOrientation: penTipOrientation)
        
        let returnNode = SCNNode()
        returnNode.position = penTipPosition
        returnNode.simdOrientation = penTipOrientation
        return returnNode
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.markerArray = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(),SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(),SCNNode(),SCNNode(),SCNNode(),SCNNode(),SCNNode(),SCNNode()]
        super.init(coder: aDecoder)
    }
    
    private enum DeviceOrientationState {
        case HomeButtonLeft
        case HomeButtonRight
    }
    
}

/**
 The MarkerFace enum maps the marker-ids from OpenCV to the
 respective faces of the physical marker-box when it is placed in default position.
 Default position: cube placed down with the pen pointing away from you towards top right. (See https://github.com/i10/ARPen/blob/master/Documentation/images/Default_Position.jpg)
 */
enum MarkerFace: Int {
    case B_back = 1, B_top, B_right, B_bottom, B_left, B_front
    case CHIARPen = 7
    case laserMesseARPen = 8
    case F_back = 9, F_top, F_right, F_bottom, F_left, F_front
    case T_back = 15, T_top, T_right, T_bottom, T_left, T_front
    case S_back = 21, S_top, S_right, S_bottom, S_left, S_front
    case notExpected = 0
}
