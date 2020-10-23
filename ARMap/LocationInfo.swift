//
//  LocationInfo.swift
//  ARMap
//
//  Created by David Gonzalez on 2019-03-05.
//  Copyright © 2019 David Gonzalez. All rights reserved.
//

import Foundation
import MapKit

struct LocationInfo{
    var pathParts: [[CLLocationCoordinate2D]]
    var steps: [MKRoute.Step]
    var destinationLocation: CLLocation!
}
