//
//  ARPenSceneConstructor.swift
//  ARPen
//
//  Created by Adrian Wagner on 30.07.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

protocol ARPenSceneConstructor {
    func preparedARPenNodes<T:ARPenStudyNode>(withScene scene : PenScene, andView view: ARSCNView, andStudyNodeType: T.Type) -> (superNode: SCNNode, studyNodes: [ARPenStudyNode])
}
