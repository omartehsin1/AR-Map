//
//  MapViiewController.swift
//  ARMap
//
//  Created by David Gonzalez on 2019-03-05.
//  Copyright © 2019 David Gonzalez. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import ARKit

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
    func createDirectionToDestintation(destCoordinates: CLLocationCoordinate2D)
}

class MapViiewController: UIViewController {
    @IBOutlet var searchBarMap: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var goToARView: UIButton! {
        didSet {
            if let image  = UIImage(named: "location"){
                goToARView.setImage(image, for: .normal)
            }
        }
    }
    
    let iconImage = UIImageView(image: UIImage(named: "map"))
    
    let splashView = UIView()
    
    var regionRadius: CLLocationDistance = 400
    
    let locationManager = CLLocationManager()
    var currentCoordinate = CLLocation()
    
    private var steps = [MKRoute.Step](){
        didSet{
            goToARView.isEnabled = !steps.isEmpty
        }
    }
    private var polylines = [MKPolyline]()
    private var route = MKRoute()
    private var currentPathPart = [[CLLocationCoordinate2D]]()
    private var pathIndicators = [[CLLocationCoordinate2D]]()
    
    var directionsArray: [MKDirections] = []
    var resultSearchController : UISearchController? = nil
    
    var selectedPin:MKPlacemark? = nil
    var selectedOverlay : MKOverlayRenderer? = nil
    
    //var locationSearchTableVC : LocationSearchTable? //used?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        //get current location
        guard let myLocation = locationManager.location else {return}
        currentCoordinate = myLocation
        
        setUpimageToAnimate()
        
        //Center the map.
        centerMapOnLocation(location: currentCoordinate.coordinate, distance: regionRadius)
        setUpBarResultsSearchController()
    }
    
    private func setUpimageToAnimate(){
        //Setup view image to animate
        view.addSubview(splashView)
        splashView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        iconImage.contentMode = .scaleAspectFit
        splashView.addSubview(iconImage)
        iconImage.frame = CGRect(x: splashView.frame.midX - 35, y: splashView.frame.midY - 35, width: 70, height: 70)
        
    }
    
    func setUpBarResultsSearchController(){
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        searchBar.delegate = self
        navigationItem.titleView = resultSearchController?.searchBar
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.obscuresBackgroundDuringPresentation = true
        definesPresentationContext = true
    }
    
    //MARK: - Animation
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if view.subviews.contains(splashView) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.scaleDownAnimation()
            }
        }
    }
    
    func scaleDownAnimation() {
        
        //first part of the animation
        UIView.animate(withDuration: 0.5, animations: {
            self.iconImage.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }) { (success) in
            self.scaleUpAnimation()
        }
    }
    
    func scaleUpAnimation() {
        UIView.animate(withDuration: 0.6, delay: 0.4, options: .curveEaseIn, animations: {
            self.iconImage.transform = CGAffineTransform(scaleX: 10, y: 10)
        }) { (success) in
            self.removeSplashScreen()
        }
    }
    
    func removeSplashScreen() {
        splashView.removeFromSuperview()
    }
    
    //MARK: - Behavior
    
    func centerMapOnLocation(location: CLLocationCoordinate2D, distance: CLLocationDistance){
        let coordinateRegion = MKCoordinateRegion.init(center: location, latitudinalMeters: distance, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
    }
    
    func clearData(){
        // Clears the variables
        steps = []
        mapView.removeOverlay(route.polyline)
        route = MKRoute()
        currentPathPart = [[]]
    }
    
    private func getLocation() {
        for (index, step) in steps.enumerated() {
            setPathFromStep(step, and: index)
        }
    }
    
    //MARK: - Get Parts of Path
    
    private func setPathFromStep(_ pathStep: MKRoute.Step, and index: Int){
        if index > 0 {
            getPathPart(for: index, and: pathStep)
        } else {
            getFirstPath(for: pathStep)
        }
    }
    
    private func getFirstPath(for pathStep: MKRoute.Step){
        let nextLocation = CLLocation(latitude: pathStep.polyline.coordinate.latitude, longitude: pathStep.polyline.coordinate.longitude)
        let middleSteps = CLLocationCoordinate2D.getPathLocations(currentLocation: currentCoordinate, nextLocation: nextLocation)
        pathIndicators.append(middleSteps)
    }
    
    private func getPathPart(for index: Int, and pathStep: MKRoute.Step) {
        let previousIndex = index - 1
        let previousStep = steps[previousIndex]
        let previousLocation = CLLocation(latitude: previousStep.polyline.coordinate.latitude, longitude: previousStep.polyline.coordinate.longitude)
        
        let nextLocation = CLLocation(latitude: pathStep.polyline.coordinate.latitude, longitude: pathStep.polyline.coordinate.longitude)
        
        let middleSteps = CLLocationCoordinate2D.getPathLocations(currentLocation: previousLocation, nextLocation: nextLocation)
            currentPathPart.append(middleSteps)
    }
    
    func resetMapView(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel() }
    }
    
    // MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController = segue.destination as! ARMapViewController
        // Pass the selected object to the next view controller.
        viewController.pathSteps = currentPathPart
        viewController.myRoute = route
    }
}

extension MapViiewController: CLLocationManagerDelegate, UISearchBarDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        guard let currentLocation = locations.first else {return}
        currentCoordinate = currentLocation
//        mapView.userTrackingMode = .followWithHeading
//        mapView.setUserTrackingMode(.followWithHeading, animated: true)
    }
}

extension MapViiewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        //Display line on 2D map
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 3
            
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.purple
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        
        
        pinView?.leftCalloutAccessoryView = button
        return pinView
    }
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
    }
}

extension MapViiewController: HandleMapSearch {
    func createDirectionToDestintation(destCoordinates: CLLocationCoordinate2D) {
        clearData()
        guard let myLocation = locationManager.location else {return}
        currentCoordinate = myLocation
        
        let sourcePlacemark = MKPlacemark(coordinate: currentCoordinate.coordinate)
        let destPlacemark = MKPlacemark(coordinate: destCoordinates)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destItem = MKMapItem(placemark: destPlacemark)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceItem
        directionRequest.destination = destItem
        directionRequest.transportType = .walking
        directionRequest.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            if error != nil {
                //issue: replace it with error log and alert message
                //print("Error2: \(String(describing: error))")
            } else {
                guard let response = response else {return}
                //print("Routes total:\(response.routes.count)")
                guard let primaryRoute = response.routes.first else {return}
                self.route = primaryRoute
                let distance = primaryRoute.distance
                //print("Main Route Polyline : \(String(describing: primaryRoute.polyline.coordinate))")
                //Add each MKRoute.step to array of MKRouteSteps.
                for step in primaryRoute.steps {
                    self.steps.append(step)
                }
                //Draw each line on 2d map
                self.mapView.addOverlay(primaryRoute.polyline, level: .aboveRoads)
                self.polylines = [primaryRoute.polyline]
                //let rect = primaryRoute.polyline.boundingMapRect
                //self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
                self.centerMapOnLocation(location: self.currentCoordinate.coordinate, distance: (distance *  2))
                //self.steps = primaryRoute.steps
                self.getLocation()
            }
        }
    }
    
    func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
    }
}
