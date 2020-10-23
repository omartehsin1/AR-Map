//
//  FloatExtension.swift
//  ARMap
//
//  Created by David on 2020-05-25.
//  Copyright © 2020 David. All rights reserved.
//

import UIKit

extension Float {
    func angleToCGPoint(width: CGFloat, height: CGFloat)-> CGPoint?{
        //Sides
        let widthSide = (atan((width/2) / (height/2)) * 180 / .pi) * 2
        let heightSide = (atan((height/2) / (width/2)) * 180 / .pi) * 2
        //angle points on possitive circle
        let northWestAngle = (atan((width/2) / (height/2)) * 180 / .pi)
        let southWestAngle = northWestAngle + heightSide
        let southEastAngleFromWest = southWestAngle + widthSide
        let northEastFromWest = southEastAngleFromWest + heightSide
        let threeSixty = northEastFromWest + northWestAngle
        //angle points on negative circle
        let negativeNorthEastAngle = -northWestAngle
        let negativeSouthEastAngle = -southWestAngle
        let negativeSouthWestAngle = -southEastAngleFromWest
        let negativeNorthWestAngle = -northEastFromWest
        let negativeTreeSixty = -threeSixty
        
        if (Int(negativeNorthEastAngle)...Int(northWestAngle)).contains(Int(self)) || (Int(negativeTreeSixty)...Int(negativeNorthWestAngle)).contains(Int(self)) || (Int(northEastFromWest)...Int(threeSixty)).contains(Int(self)){
            //top side
            let tanOfSelf = tan((self * .pi / 180))
            let angle = ((tanOfSelf) * Float(height/2))
            let x = width/2 + CGFloat(angle)
            return CGPoint(x: x, y: 0)
        } else if (Int(northWestAngle)...Int(southWestAngle)).contains(Int(self)) || (Int(negativeNorthWestAngle)...Int(negativeSouthWestAngle)).contains(Int(self)){
            //right side
            let tanOfSelf = tan((90 * .pi / 180) - (self * .pi / 180))
            let angle = ((tanOfSelf) * Float(width/2))
            let y = height/2 - CGFloat(angle)
            return CGPoint(x: width, y: y)
        } else if (Int(southWestAngle)...Int(southEastAngleFromWest)).contains(Int(self)) || (Int(negativeSouthWestAngle)...Int(negativeSouthEastAngle)).contains(Int(self)) {
            //botton side
            let tanOfSelf = tan((self * .pi / 180))
            let angle = ((tanOfSelf) * Float(height/2))
            let x = width/2 - CGFloat(angle)
            return CGPoint(x: x, y: height)
        } else if (Int(southEastAngleFromWest)...Int(northEastFromWest)).contains(Int(self)) || (Int(negativeSouthEastAngle)...Int(negativeNorthEastAngle)).contains(Int(self)) {
            //left side
            let tanOfSelf = tan((90 * .pi / 180) - (self * .pi / 180))
            let angle = ((tanOfSelf) * Float(width/2))
            let y = height/2 + CGFloat(angle)
            return CGPoint(x: 0, y: y)
        } else {
            return nil
        }
    }
}
