//
//  SCNPlaneExtension.swift
//  ARMap
//
//  Created by David on 2020-05-25.
//  Copyright © 2020 David. All rights reserved.
//

import Foundation
import SCNPath
import SceneKit
import ARKit

extension SCNPlane {
    func updateSize(toMatch anchor: ARPlaneAnchor) {
        self.width = CGFloat(anchor.extent.x)
        self.height = CGFloat(anchor.extent.z)
    }
}

