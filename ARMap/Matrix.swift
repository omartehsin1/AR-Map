//
//  Matrix.swift
//  ARMap
//
//  Created by David Gonzalez on 2019-03-05.
//  Copyright © 2019 David Gonzalez. All rights reserved.
//

import Foundation
import CoreLocation
import GLKit

class Matrix {
    
    //      column 0  column 1  column 2  column 3
    //        cosθ      0       sinθ        0    
    //         0        1        0          0     
    //       −sinθ      0       cosθ        0     
    //         0        0        0          1    
    
    static func rotateAroundY(with matrix: matrix_float4x4, for degrees: Float) -> matrix_float4x4 {
        var matrix : matrix_float4x4 = matrix
        
        matrix.columns.0.x = cos(degrees)
        matrix.columns.0.z = -sin(degrees)
        
        matrix.columns.2.x = sin(degrees)
        matrix.columns.2.z = cos(degrees)
        return matrix.inverse
    }
    
    //     column 0  column 1  column 2  column 3
    //         1        0         0       X          x         x + X*w  
    //         0        1         0       Y      x   y    =    y + Y*w  
    //         0        0         1       Z          z         z + Z*w  
    //         0        0         0       1          w            w    
    
    static func translationMatrix(with matrix: matrix_float4x4, for translation : vector_float4) -> matrix_float4x4 {
        var matrix = matrix
        matrix.columns.3 = translation
        return matrix
    }
    
    static func transformMatrix(for matrix: simd_float4x4, originLocation: CLLocation, location: CLLocation) -> simd_float4x4 {
        let distance = Float(location.distance(from: originLocation))
        let heading = originLocation.headingInRadians(location)
        let position = vector_float4(0.0, 0.0, -distance, 0.0)
        let translationMatrix = Matrix.translationMatrix(with: matrix_identity_float4x4, for: position)
        let rotationMatrix = Matrix.rotateAroundY(with: matrix_identity_float4x4, for: Float(heading))
        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
        return simd_mul(matrix, transformMatrix)
    }
}

