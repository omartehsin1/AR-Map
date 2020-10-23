//
//  Node.swift
//  
//  Created by David Gonzalez on 2019-03-05.
//  Copyright © 2019 David Gonzalez. All rights reserved.
//

import UIKit
import ARKit
import SCNPath
import SceneKit
import CoreLocation

class Node: SCNNode{
    
    var location: CLLocation?
    var anchor: ARAnchor?
    
    init( location: CLLocation? = nil){
        self.location = location
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addArrow(_ position: SCNVector3, _ direction: SCNVector3 ){
        if let arrowScene = SCNScene(named: "art.scnassets/Arrow.scn") {
            if let arrowNode = arrowScene.rootNode.childNodes.first{
                
                arrowNode.position = position
                arrowNode.position.y = 6
                //transforms direnction.x from degrees to radians.
                let directionX = ((direction.x) * (.pi/180))
                arrowNode.eulerAngles.x = directionX
                arrowNode.eulerAngles.y = direction.y * .pi / 180
                arrowNode.eulerAngles.z = 1.57
                //arrowNode.scale = SCNVector3(30.0, 30.0, 30.0)
                arrowNode.scale = SCNVector3(100.0, 100.0, 100.0)
                addChildNode(arrowNode)
            }
        }
    }
    
    func addGlove(size: CGFloat, color: UIColor? = nil){
        let geometry = SCNSphere(radius: size)
        geometry.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/8k_earth_daymap.jpg")
        let globe = SCNNode(geometry: geometry)
        addChildNode(globe)
    }
    
    func addTextNode(size: CGFloat, color: UIColor, text: String){
        
        let stepText = SCNText(string: text, extrusionDepth: 0.1)
        stepText.font = UIFont(name: "AvenirNext-Medium", size: size)
        stepText.firstMaterial?.diffuse.contents = color
        stepText.isWrapped = true
        let textNode = SCNNode(geometry: stepText)
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        textNode.constraints = [billboardConstraint]
        addChildNode(textNode)
    }
}

