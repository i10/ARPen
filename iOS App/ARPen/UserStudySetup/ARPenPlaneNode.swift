import Foundation
import SpriteKit

class ARPenPlaneNode: ARPenStudyNode {
    
    override var highlighted: Bool {
        didSet {
            changeColors()
        }
    }
    
    override func changeColors() {
        (self.geometry?.firstMaterial?.diffuse.contents as? SKScene)?.backgroundColor = self.geometry!.firstMaterial!.emission.intensity == 1 ? UIColor.magenta : UIColor.orange
        (self.geometry?.firstMaterial?.emission.contents as? SKScene)?.backgroundColor = UIColor.magenta
    }
    
}
