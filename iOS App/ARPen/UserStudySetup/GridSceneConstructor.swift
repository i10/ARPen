import Foundation
import ARKit

struct GridSceneConstructor : ARPenSceneConstructor {
    
    //    let numberOfStudyNodes = 64
    
    typealias CubeDimensions = (width: Double, height: Double, depth: Double)
    
    func preparedARPenNodes<T:ARPenStudyNode>(withScene scene : PenScene, andView view: ARSCNView, andStudyNodeType studyNodeClass: T.Type) -> (superNode: SCNNode, studyNodes: [ARPenStudyNode]) {
        var studyNodes : [ARPenStudyNode] = []
        let superNode = SCNNode()
        
        let cubesPerDimension: (x: Int, y: Int, z: Int) = (4,4,1)
        let cubeVolume: CubeDimensions = (0.4, 0.4, 0.1)
        let dimensionOfBox = 0.03
        
        let cubeCellWidth = cubeVolume.width / Double(cubesPerDimension.x)
        let cubeCellHeight = cubeVolume.height / Double(cubesPerDimension.y)
        let cubeCellDepth = cubeVolume.depth / Double(cubesPerDimension.z)
        
        let widthRange = (-cubeCellWidth / 2 + dimensionOfBox / 2 + 0.005, cubeCellWidth / 2 - dimensionOfBox / 2 - 0.005)
        let heightRange = (-cubeCellHeight / 2 + dimensionOfBox / 2 + 0.005, cubeCellHeight / 2 - dimensionOfBox / 2 - 0.005)
        let depthRange = (-cubeCellDepth / 2 + dimensionOfBox / 2 + 0.005, cubeCellDepth / 2 - dimensionOfBox / 2 - 0.005)
        
        let x = -cubeVolume.width / 2
        let y = cubeCellHeight
        let z =  -cubeVolume.depth / 2
        
        var arPenStudyNode : ARPenStudyNode
        
        for ix in 0 ..< cubesPerDimension.x {

            for iy in 0 ..< cubesPerDimension.y {
                
                for iz in 0 ..< cubesPerDimension.z {
                    
                    let randomDoubleForX = drand48()
                    let randomDoubleForY = drand48()
                    let randomDoubleForZ = drand48()
                    
                    
                    let xPositionOffset = widthRange.0 + (randomDoubleForX * (widthRange.1 - widthRange.0))
                    let yPositionOffset = heightRange.0 + (randomDoubleForY * (heightRange.1 - heightRange.0))
                    let zPositionOffset = depthRange.0 - 0.005//depthRange.0 + (randomDoubleForZ * (depthRange.1 - depthRange.0))
                    
                    
                    arPenStudyNode = studyNodeClass.init(withPosition: SCNVector3Make(Float(x + xPositionOffset + Double(ix) * cubeCellWidth), Float(y + yPositionOffset + Double(iy) * cubeCellHeight), Float(z + zPositionOffset + Double(iz) * cubeCellDepth)), andDimension: Float(dimensionOfBox))
                    studyNodes.append(arPenStudyNode)
                    
                    
                }
                
            }
            
        }
        
        studyNodes.shuffle()
        studyNodes.forEach({superNode.addChildNode($0)})
        return (superNode, studyNodes)
    }
    
    
}
