//
//  ExtensioToCoreLocation.swift
//  ARMap
//
//  Created by David Gonzalez on 2019-03-05.
//  Copyright © 2019 David Gonzalez. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import SceneKit

extension CLLocationCoordinate2D {
    
    static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D)-> Bool{
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
 
    func directionCoordinate(with heading: Double, and distance: Double) -> CLLocationCoordinate2D {
        
        let distanceRadiansLatitude = distance / LocationConstants.metersPerRadianLat
        let distanceRaidansLongitude = distance / LocationConstants.metersPerRadianLon
        let lat1 = self.latitude.degreesToRadians()
        let lon1 = self.longitude.degreesToRadians()
        let lat2 = asin(sin(lat1) * cos(distanceRadiansLatitude) + cos(lat1) * sin(distanceRadiansLatitude) * cos(heading))
        let lon2 = lon1 + atan2(sin(heading) * sin (distanceRaidansLongitude) * cos(lat1), cos(distanceRaidansLongitude) - sin(lat1) * sin(lat2))
        return CLLocationCoordinate2D(latitude: lat2.radiansToDegrees(), longitude: lon2.radiansToDegrees())
    }
    
    static func getPathLocations(currentLocation: CLLocation, nextLocation: CLLocation) -> [CLLocationCoordinate2D]{
        let standardSpace: Double = 4
        let spacePerNodeInMeters = standardSpace
        var distance = nextLocation.distance(from: currentLocation)
        var distances = [CLLocationCoordinate2D]()
        let heading = currentLocation.headingInRadians(nextLocation)
        while distance > standardSpace {
            distance = distance - Double(spacePerNodeInMeters)
            let newLocation = currentLocation.coordinate.directionCoordinate(with: heading, and: distance)
            
            if !distances.contains(where: { (location) -> Bool in
                return location == newLocation
            }){
                distances.append(newLocation)
            }
        }
        return distances
    }
}

extension CLLocation{
    
    func headingInRadians(_ nextLocation: CLLocation) -> Double{
        let long1 = self.coordinate.longitude.degreesToRadians()
        let lat1 = self.coordinate.latitude.degreesToRadians()
        let long2 = nextLocation.coordinate.longitude.degreesToRadians()
        let lat2 = nextLocation.coordinate.latitude.degreesToRadians()
        
        let long = long2 - long1
        let y = sin(long) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(long)
        let radiansHeading = atan2(y, x)
        return radiansHeading
    }
    //retrieve the location out of and array of locations you are closest to.
    static func bestLocationEstimate(locations: [CLLocation]) -> CLLocation {
        let sortedLocationEstimates = locations.sorted(by: {
            if $0.horizontalAccuracy == $1.horizontalAccuracy {
                return $0.timestamp > $1.timestamp
            }
            return $0.horizontalAccuracy < $1.horizontalAccuracy
        })
        return sortedLocationEstimates.first!
    }
}

extension MKRoute.Step{
    func getLocation() -> CLLocation{
        return CLLocation(latitude: polyline.coordinate.latitude, longitude: polyline.coordinate.longitude)
    }
}

extension Double {
    func degreesToRadians() -> Double {
        return self * .pi / 180.0
    }
    func radiansToDegrees() -> Double {
        return self * 180.0 / .pi
    }
}

struct LocationConstants {
    static let metersPerRadianLat: Double = 6373000.0
    static let metersPerRadianLon: Double = 5602900.0
}

extension SCNVector3 {
    static func positionForNode(transform: matrix_float4x4)-> SCNVector3{
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
}
