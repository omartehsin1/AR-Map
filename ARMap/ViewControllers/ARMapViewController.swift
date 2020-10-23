//  ViewController.swift
//  ARMap
//
//  Created by David Gonzalez on 2019-03-05.
//  Copyright © 2019 David Gonzalez. All rights reserved.
//
import CoreLocation
import UIKit
import SceneKit
import ARKit
import MapKit
import SCNPath

class ARMapViewController: UIViewController, ARSCNViewDelegate, Mapable, ARCoachingOverlayViewDelegate {
    
    //MARK: - Properties
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet var arView: UIView!
    @IBOutlet weak var coachingOverlay: ARCoachingOverlayView!
    @IBOutlet weak var directionalView: UIView!
    
    var myRoute = MKRoute() //from previous VC
    var pathSteps = [[CLLocationCoordinate2D]]() //from previous VC
    private var mySteps = [CLLocationCoordinate2D]()
    private var anchors: [ARAnchor] = []
    private var locations = [CLLocation]()
    internal var myLocation: CLLocation!
    private var nodes = [Node]()
    private var updateNodes = false
    private var updateLocations = [CLLocation]()
    private var done = false
    private var mapAnnotations = [MapAnnotation]()
    private var annotationColor = UIColor.blue
    private let locationManager = CLLocationManager()
    private let regionRadius: CLLocationDistance = 500
    private var hasDetectedPlane: Bool = false
    private var pathPoints = [SCNVector3]()
    private var pathNode = SCNPathNode(path: [])
    private var pathNodes: [Node] = []
    private var mainPointLocations = [CLLocation]()
    private var heading = CLHeading()
    private var nextPointLocation: Float = 0.0 {
        didSet{
            animateIndicator(at: nextPointLocation)
        }
    }
    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpScene()
        setUpNavigation()
        getCoordinates()
        centerMapInInitialCoordinates()
        addCompassToMiniMap()
        setUpViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mapView.alpha = 0.8
        runSession()
        //presentCoachingOverlay()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if locationManager.heading != nil {
            //issue: might need to update when user moves.
            heading = locationManager.heading!
        }
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()// Pause the view's session
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
       
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft{
            locationManager.headingOrientation = .landscapeLeft
            print("Landscape Left")
        }
        else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight{
            locationManager.headingOrientation = .landscapeRight
            print("Landscape Right")
        }
        else if UIDevice.current.orientation == UIDeviceOrientation.portraitUpsideDown{
            locationManager.headingOrientation = .portraitUpsideDown
            print("Upside Down")
        }
        else if UIDevice.current.orientation == UIDeviceOrientation.portrait{
            locationManager.headingOrientation = .portrait
            print("Portrait")
        }
    }
    
    deinit {
        mapView.annotations.forEach{mapView.removeAnnotation($0)}
        mapView.delegate = nil
    }
    
    //MARK: - Actions
    @IBAction func backBtn(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goBtn(_ sender: UIButton) {
        start()
        placeDirectionalView(nodes: pathNodes)
    }
    
    private func start(){
        if !pathSteps.isEmpty{
            done = true
        }
        updateNodes = true
        if updateLocations.count > 0 {
            myLocation = CLLocation.bestLocationEstimate(locations: updateLocations)
            if (myLocation != nil && done == true){
                self.addAnchors(steps: self.myRoute.steps)
                trackingLocation(for: self.myLocation)
                addtextNode(color: UIColor.systemPurple, size: 0.5)
                DispatchQueue.main.async {
                    self.centerMapInInitialCoordinates()
                    self.addAnnotations()
                    self.showPointsOfInterestInMap(currentPath: self.mySteps)
                }
            }
        }
    }
    
    private func placeDirectionalView(nodes: [Node]){
        //passes the location to start monitoring path points.
        for pathPoint in nodes {
            startPathPointMonitoring(pathPoint: pathPoint.location)
        }
    }
    
    private func runSession(){
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical, .horizontal]
        configuration.environmentTexturing = .automatic
        configuration.worldAlignment = .gravityAndHeading
        sceneView.session.run(configuration, options: [.resetTracking])
    }
    
    private func setUpScene(){
        sceneView.delegate = self
        sceneView.debugOptions = .showFeaturePoints
        sceneView.automaticallyUpdatesLighting = true
        //sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight ]
    }
    
    //gets coordinates
    private func getCoordinates(){
        for pSteps in pathSteps {
            mySteps = mySteps + pSteps
        }
        for myStep in mySteps {
            locations.append(CLLocation(latitude: myStep.latitude, longitude: myStep.longitude))
        }
    }
    
    private func setUpViews(){
        directionalView.layer.cornerRadius = 30
    }
    
    /// Begins the coaching process that instructs the user's movement during
    /// ARKit's session initialization.
    private func presentCoachingOverlay() {
        coachingOverlay.session = sceneView.session
        coachingOverlay.delegate = self
        coachingOverlay.goal = .anyPlane
        coachingOverlay.activatesAutomatically = false
        coachingOverlay.setActive(true, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.coachingOverlay.delegate = nil
            self.coachingOverlay.setActive(false, animated: false)
            self.coachingOverlay.removeFromSuperview()
            self.start()
        }
    }
    
    private func trackingLocation(for currentLocation: CLLocation) {
        if currentLocation.horizontalAccuracy <= 100.0 && currentLocation.horizontalAccuracy >= 0 {
            updateLocations.append(currentLocation)
            updateNodePosition()
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    //MARK: - Begining Text
    
    private func addtextNode(color: UIColor, size: CGFloat){
        let text = SCNText(string: "Follow the\n Yellow\n Brick Path", extrusionDepth: 0.1)
        text.font = UIFont(name: "AvenirNext-Medium", size: size)
        text.firstMaterial?.diffuse.contents = color
        text.isWrapped = true
        let textNode = SCNNode(geometry: text)
        
        //flips the text so that is the right way
        textNode.eulerAngles = SCNVector3Make(0, .pi , 0)
        
        if let firstStepLocation = (myRoute.steps.first?.getLocation()){
            let translation = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: myLocation, location: firstStepLocation)
            let anchor = ARAnchor(transform: translation)
            sceneView.session.add(anchor: anchor)
            var distanceRateFromPointOfOrigin:Float = 1
            let x = anchor.transform.columns.3.x
            let z = anchor.transform.columns.3.z
            
            //issue: make separate method for this.
            let hypotenuse = (powf(x, 2) + powf(z, 2)).squareRoot()
            if hypotenuse >= 14 {
                distanceRateFromPointOfOrigin = 0.4
            } else if hypotenuse >= 10 {
                distanceRateFromPointOfOrigin = 0.5
            } else if hypotenuse >= 8 {
                distanceRateFromPointOfOrigin = 0.6
            } else if hypotenuse >= 6 {
                distanceRateFromPointOfOrigin = 0.7
            } else {
                distanceRateFromPointOfOrigin = 2.5
            }
            
            textNode.position = SCNVector3((x * distanceRateFromPointOfOrigin), anchor.transform.columns.3.y - 2, (z * distanceRateFromPointOfOrigin))
            
            //makes it so that the node is always facing the camera.
            let billboardConstraint = SCNBillboardConstraint()
            billboardConstraint.freeAxes = SCNBillboardAxis.Y
            textNode.constraints = [billboardConstraint]
            
            sceneView.scene.rootNode.addChildNode(textNode)
        }
    }
    
    //MARK: - Rotate Arrows
    private func rotateVectors(path: [SCNVector3]) -> [SCNVector3]{
        let maxIndex = path.count - 1
        var vectors: [SCNVector3] = []
        var bentBy: Float = 0
        var addVector: SCNVector3!
        var arrowVector = addVector
        for (index, vert) in path.enumerated() {
            
            if index == 0 { // first point
                addVector = SCNVector3(0, 0, 0)
                arrowVector = addVector
            } else if index < maxIndex {  // turn points
                let toThis = (vert - path[index - 1])
                let fromThis = (path[index + 1] - vert)
                bentBy = fromThis.angleChange(to: toThis)
                addVector = vert
                arrowVector = addVector.rotate(about: path[index + 1], by: bentBy)
                //print("Angle in radian is: \(bentBy) which in degress is \(bentBy * (180/Float.pi)), Difference from vector: \(fromThis), AddVector: \(String(describing: addVector)) at index: \(index) -> Vert: \(vert)")
            } else { // last point
                addVector = vert
                arrowVector = addVector
            }
            vectors.append(arrowVector!)
        }
        return vectors
    }
    
    //MARK: - Indicator methods
    private func directionalDot(nextPoint: CLLocation?)-> Float {
        if let nextPoint = nextPoint {
            let translation = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: myLocation, location: nextPoint)
            let nextPosition = SCNVector3.positionForNode(transform: translation)
            let myLocVec = SCNVector3(0,0,0)
            let directionalDot = myLocVec.rotate(about: nextPosition, by: 0)
            let direction = directionalDot.direction(vector: nextPosition)
            return direction
        } else {
            return 0.0
        }
    }
    
    // MARK: - Animation
    
    //animating the indicator to point toward the next point passed by the heading angle.
    private func animateIndicator(at angle: Float){
        let width = self.view.frame.width
        let height = self.view.frame.height
        let directionalViewSize = directionalView.frame
        if let cgPoint = angle.angleToCGPoint(width: width - directionalViewSize.width, height: height - directionalViewSize.height) {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                UIView.animate(withDuration: 0.3, animations: {
                    self.directionalView.frame.origin = cgPoint
                })
            }
        }
    }
    
    // add info to AR nodes
    private func addAnchors(steps: [MKRoute.Step]){
        guard myLocation != nil && steps.count > 0 else {return}
        for step in steps { //place nodes in main points
            placeNode(for: step)
        }
        for location in locations {  //place nodes in between main locations
            placeNode(for: location)
        }
    }
    //Change path properties like material
    private func path(){
        let pathMaterial = SCNMaterial()
        pathMaterial.diffuse.contents = UIColor.systemYellow.withAlphaComponent(0.6)
        pathNode.materials = [pathMaterial] //this is a path node from SCNPath
        pathNode.width = 1.2
        sceneView.scene.rootNode.addChildNode(pathNode) //adds actual path to the scene.
    }
    
    //MARK: - Create AR Nodes
    //issue: anchors were created and appedned twice, check if functionality suffers if removed.
    
    // placeNode for Main points
    func placeNode(for step: MKRoute.Step){
        let stepLocation = step.getLocation()
        //needed for the Hud feature.
        mainPointLocations.append(stepLocation)
        let locationTransform = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: myLocation, location: stepLocation)
        let stepAnchor = ARAnchor(transform: locationTransform)
        let displayNode = Node()
        displayNode.addTextNode(size: 0.6, color: .systemPurple, text: step.instructions) //Adds text to the node.
        displayNode.location = stepLocation //the location is added here so that it can be passes to the nodes array.
        displayNode.position.y = -1
        sceneView.session.add(anchor: stepAnchor) //?
        sceneView.scene.rootNode.addChildNode(displayNode)
        pathNodes.append(displayNode) //pathNodes are the nodes used to place the actual path
    }
    // placeNode in between main locations
    func placeNode(for location: CLLocation){
        let object = Node()
        object.addGlove(size: 0.05)
        object.location = location
        sceneView.scene.rootNode.addChildNode(object)
        nodes.append(object)
    }
    
    //issue: Try to split it into different methods.
    private func updateNodePosition(){
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.1
        if updateLocations.count > 0 && pathNodes.count > 0 {
            myLocation = CLLocation.bestLocationEstimate(locations: updateLocations)
            //gets user's location to be added to the array that creates the path so that the path starts from the user's location as opposed to the street location.
            let translationStartingPoint = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: myLocation, location: myLocation)
            var positionAtMyLocation = SCNVector3.positionForNode(transform: translationStartingPoint)
            //Lowers the path at the origin's location.
            positionAtMyLocation.y = -2
            pathPoints.append(positionAtMyLocation)
            
            //nodes in between main points
            //nodes.first?.removeFromParentNode() //removes first node so that the first glove is not added.
            for node in nodes {
                if node.location != nil && node != nodes[0] { //Places the nodes in their positions
                    
                    let translation = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: myLocation, location: node.location!)
                    let position = SCNVector3.positionForNode(transform: translation)
                    let distance = node.location!.distance(from: myLocation)
                    DispatchQueue.main.async {
                        let scale = 100 / Float(distance)
                        node.scale = SCNVector3(x: scale, y: scale, z: scale)
                        node.position = position
                        node.position.y = -1
                    }
                }
            }
            //nodes at main points
            for (index, pathN) in pathNodes.enumerated() {
                if pathN.location != nil {
                    let translation = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: myLocation, location: pathN.location!)
                    var position = SCNVector3.positionForNode(transform: translation)
                    
                    //issue: might make the path follow -- to follow up and test it.
                    position.y = -2
                    let distance = pathN.location!.distance(from: myLocation)
                    let scale = 100 / Float(distance)
                    DispatchQueue.main.async {
                        pathN.scale = SCNVector3(x: scale, y: scale, z: scale)
                        pathN.position = position
                        pathN.anchor = ARAnchor(transform: translation)
                    }
                    print("Position at \(index) at X \(position.x), Position at \(index) at Z \(position.z)")
                    pathPoints.append(position) //add vectors to path
                }
            }
            self.pathNode.path = pathPoints //Creates the actual path.
            let rotatedPathPoints = rotateVectors(path: pathPoints) //get the rotation for the arrows
            let maxIndex = pathPoints.count - 1
            for (index, pathPoint) in pathPoints.enumerated() { //places Arrows at pathPoints.
                if index > 0 && index < maxIndex { //no arrow for the first location.
                    let arrowNode = Node()
                    arrowNode.addArrow(pathPoint, rotatedPathPoints[index])
                    sceneView.scene.rootNode.addChildNode(arrowNode)
                } else if index >= maxIndex {
                    let arrowNode = Node()
                    arrowNode.addArrow(pathPoint, SCNVector3(0,90,0))
                    sceneView.scene.rootNode.addChildNode(arrowNode)
                }
            }
        }
        SCNTransaction.commit()
        path()
        mapView.addOverlay(myRoute.polyline)
    }
    
    // MARK: - ARSCNViewDelegate
    //issue: Make sure all that is needed from the below methods is used for better user experience and app performance, then delete the unused code.
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            if !hasDetectedPlane {
                let planeYPosition = SCNVector3.positionForNode(transform: planeAnchor.transform).y - 1
                pathNode.position.y = planeYPosition
                hasDetectedPlane = true
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    }
}

extension ARMapViewController: MKMapViewDelegate, CLLocationManagerDelegate {
    
    func setUpNavigation(){
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingHeading()
        
        //get current location
        guard let aLocation = locationManager.location else {return}
        myLocation = aLocation
        updateLocations.append(myLocation)
    }
    
    //MARK: - Minimap
    private func showPointsOfInterestInMap(currentPath: [CLLocationCoordinate2D]) {
        guard let myAnnotation = currentPath.first else {return}
        guard let destinationAnnotation = currentPath.last else {return}
        let annotation = MapAnnotation(coordinate: myAnnotation)
        let destiAnnotation = MapAnnotation(coordinate: destinationAnnotation)
        self.mapView.addAnnotation(annotation)
        self.mapView.addAnnotation(destiAnnotation)
    }
    
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
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
    }
    
    //adds anotations and overlay to minimap
    private func addAnnotations(){
        mapView.addOverlay(myRoute.polyline)
    }
    
    private func addCompassToMiniMap(){
        let compass = MKCompassButton(mapView: mapView)   // Creates a new compass
        compass.compassVisibility = .visible          // Makes it visible
        mapView.addSubview(compass) // Adds it to the view
        compass.translatesAutoresizingMaskIntoConstraints = false // Position it as required
        compass.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -12).isActive = true
        compass.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 12).isActive = true
    }
    
    // MARK: - CLLOcation
    
    private func startPathPointMonitoring(pathPoint: CLLocation?){
        if let center = pathPoint?.coordinate {
            monitoringRegionAtLocation(center: center, identifier: "pathPoint")
        }
    }
    
    //created the region and distance and starts monitoing them.
    private func monitoringRegionAtLocation(center: CLLocationCoordinate2D, identifier: String){
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self){
            let distanceFromPoint = 7.0
            let region = CLCircularRegion(center: center, radius: distanceFromPoint, identifier: identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = false
            locationManager.startMonitoring(for: region)
        }
    }
    
    //once someone enters the region monitored, this delegate method is triggered.
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            if mainPointLocations.count > 0 {
                directionalView.backgroundColor = UIColor.init(red: CGFloat.random(in: 0..<255), green: CGFloat.random(in: 0..<255), blue: CGFloat.random(in: 0..<255), alpha: 0.7)
                _ = mainPointLocations.remove(at: 0)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        tempLabel.text = String(format: "%.2f", newHeading.trueHeading)
        //issue: heading might need to be updated when user moves, might.
        
        if mainPointLocations.count > 0 {
            //use the result of this to animate the red dot.
            nextPointLocation = defaultHeading(orientation: newHeading.trueHeading, originalHeading: Float(heading.trueHeading), nextPoint: directionalDot(nextPoint: mainPointLocations[0]))
        } else {
            nextPointLocation = 0.0
        }
    }
    
    //gets the heading to the next point by passing the angle of it.
    private func defaultHeading(orientation: CLLocationDirection, originalHeading: Float, nextPoint: Float)->Float{
        let degreesFromHeading = Float(orientation) - originalHeading
        let angleHeading = (nextPoint - degreesFromHeading) - originalHeading
        //print("degrees from heading: \(degreesFromHeading), angleHeading: \(angleHeading)")
        return angleHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //issue: what is the distance for this to be called.
        print("is this even being called")
        guard let currentLocation = locations.first else {return}
        updateLocations.append(currentLocation)
        mapView.userTrackingMode = .followWithHeading 
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
}



