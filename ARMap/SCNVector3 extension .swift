//
//  SCNVector3 extension .swift
//  ARMap
//
//  Created by David on 2020-04-30.
//  Copyright © 2020 David. All rights reserved.
//

import Foundation
import SceneKit

extension SCNVector3 {
    
    /// Returns the magnitude of the vector
    var length: Float {
        return sqrtf(self.lenSq)
    }
    
    /// Angle change between two vectors
    /// - Parameter vector: vector to compare
    /// - Returns: angle between the vectors
    func angleChange(to vector: SCNVector3) -> Float {
        let dot = self.normalized().dot(vector: vector.normalized())
        return acos(dot / sqrt(self.lenSq * vector.lenSq))
    }
    
    /// Returns the squared magnitude of the vector
    var lenSq: Float {
        return x*x + y*y + z*z
    }
    
    /// Normalizes the SCNVector
    /// - Returns: SCNVector3 of length 1.0
    func normalized() -> SCNVector3 {
        return self / self.length
    }
    
    /// Sets the magnitude of the vector
    /// - Parameter to: value to set it to
    /// - Returns: A vector pointing in the same direction but set to a fixed magnitude
    func setLength(to vector: Float) -> SCNVector3 {
        return self.normalized() * vector
    }
    
    /// Scalar distance between two vectors
    /// - Parameter vector: vector to compare
    /// - Returns: Scalar distance
//    func distance(vector: SCNVector3) -> Float {
//        return (self - vector).length
//    }
    
    /// Dot product of two vectors
    /// - Parameter vector: vector to compare
    /// - Returns: Scalar dot product
    func dot(vector: SCNVector3) -> Float {
        return x * vector.x + y * vector.y + z * vector.z
    }
    
    /// Given an origin to the next point, rotate along X/Z plane by radian amount
    /// - parameter by: Value in radians for the point to be rotated by
    /// - returns: New SCNVector3 that has the rotation applied
    func rotate(about nextPoint: SCNVector3, by rotation: Float) -> SCNVector3 {
        
        let pointRepositionedXZ = [nextPoint.x - self.x, nextPoint.z - self.z]
        let rotate = rotation * 180 / .pi
        let yOverX = pointRepositionedXZ[1]/pointRepositionedXZ[0]
        let angle = atan(yOverX)
        
        var xAngle:Float = 0.0
        if pointRepositionedXZ[0] < 0 {
            if angle < 0 {
                if yOverX <= -1 {
                    xAngle = -(angle * 180 / .pi) + rotate //90
                } else {
                    xAngle = (angle * 180 / .pi) + rotate //90
                }
            } else {
                xAngle =  -(angle * 180 / .pi) + rotate //90
            }
        } else if pointRepositionedXZ[0] >= 0 {
            if angle < 0 {
                xAngle = -((angle * 180 / .pi) + rotate) //90
            } else {
                xAngle =  (angle * 180 / .pi) + rotate //90
            }
        }
        return SCNVector3(
            x: xAngle,
            y: self.y,
            z: nextPoint.z
        )
    }
    
    //Return the direction of a vector
    func direction(vector: SCNVector3)-> Float{
        if vector.x > 0 && vector.z > 0 { //++
            return 90 + self.x
        } else if vector.x > 0 && vector.z < 0 { //+-
            return 360 - abs(self.x)
        } else if vector.x < 0 && vector.z > 0 { //-+
            return 180 - abs(self.x)
        } else if vector.x < 0 && vector.z < 0 { //--
            return 180 + abs(self.x)
        } else {
            return 1.01
        }
    }
}

// SCNVector3 operator functions
func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3Make(vector.x * scalar, vector.y * scalar, vector.z * scalar)
}

func *= (vector: inout SCNVector3, scalar: Float) {
    vector = (vector * scalar)
}

func / (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x / right.x, left.y / right.y, left.z / right.z)
}

func / (vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3Make(vector.x / scalar, vector.y / scalar, vector.z / scalar)
}
