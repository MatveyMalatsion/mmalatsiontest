//
//  MainMapMainMapViewController.swift
//  Tinkoff Test
//
//  Created by madway94@yandex.ru on 06/10/2018.
//  Copyright © 2018 MMalatsion. All rights reserved.
//

import MapKit
import UIKit

class MainMapViewController: UIViewController, MainMapViewInput {
    var locationManager: CLLocationManager?
    var output: MainMapViewOutput!

    var quadTree: CoordinateTreeNode!
    var treeRoot: QuadTreeNode<DepositionPointProtocol>!
    var cachedAnnotations: NSMutableSet?

    let imageViewTag = 156

    @IBOutlet var zoomInButton: UIButton!
    @IBOutlet var zoomOutButton: UIButton!
    @IBOutlet var locationButton: UIButton!
    @IBOutlet var mapView: MKMapView!

    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        treeRoot = tree(from: [])
        quadTree = CoordinateTreeNode(root: treeRoot)
        locationManager = CLLocationManager()
        locationManager!.delegate = self

        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager!.startUpdatingLocation()
        } else {
            locationManager!.requestWhenInUseAuthorization()
        }

        [zoomInButton, zoomOutButton, locationButton].forEach { button in
            button!.setTitleColor(UIColor.black, for: .normal)
        }

        mapView.setRegion(MKCoordinateRegion(center: mapView.userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)), animated: true)
        output.viewIsReady()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        [zoomInButton, zoomOutButton, locationButton].forEach { button in
            button!.layer.cornerRadius = button!.bounds.width / 2
            button!.layer.shadowRadius = 1
            button!.layer.shadowOffset = CGSize(width: 1, height: 1)
            button!.layer.shadowOpacity = 0.3
            button!.layer.shadowColor = UIColor.black.cgColor
        }
    }

    func reloadPins() {
        mapView.setRegion(mapView.region, animated: true)
    }

    func update(annotations: [MapPin]) {
        var before = NSMutableSet(array: mapView.annotations)
        before.remove(mapView.userLocation)
//
//        before = NSMutableSet(array: before.compactMap{$0 as? MapPin}.compactMap{ PointHashableWrapper(point: $0.depositionPoint, annotation: $0)} )
//        let after = NSSet(array: annotations.compactMap{ PointHashableWrapper(point: $0.depositionPoint, annotation: $0)} )
//
//        let toKeep = NSMutableSet(set: before)
//        toKeep.intersect(after as! Set)
//
//        let toAdd = NSMutableSet(set: after)
//        toAdd.minus(toKeep as! Set)
//
//        let toRemove = NSMutableSet(set : before)
//        toRemove.minus(after as! Set)
//
//        toAdd.forEach{ point in
//            (point as? MapPin)?.needToAnimateOnAppearance = true
//        }
//      Something strange sometimes happende here
        

//        let eps = 0.000001
//        before.compactMap{$0 as? MapPin}.filter{ pin1 in
//            if annotations.last(where: { pin2 in
//                CLLocation(latitude: pin1.coordinate.latitude, longitude: pin1.coordinate.longitude).distance(from: CLLocation(latitude: pin2.coordinate.longitude, longitude: pin2.coordinate.longitude)) < eps
//            }) != nil{
//                return true
//            }
//
//            return true
//            }.forEach{
//                $0.needToAnimateOnAppearance = true
//        }
//      Something strange sometimes happende here
//      So for now
//      TODO: make correct diffing and remove/add only needed points
        
        OperationQueue.main.addOperation {
            self.mapView.removeAnnotations(before.allObjects.compactMap { $0 as? MapPin })
            self.mapView.addAnnotations(annotations)
//            self.mapView.addAnnotations(toAdd.allObjects.compactMap{$0 as? PointHashableWrapper}.compactMap{ wrapper in
//                return wrapper.annotation ?? MapPin(depositionPoint: wrapper.point)
//            })
//            self.mapView.removeAnnotations(toRemove.allObjects.compactMap{($0 as? PointHashableWrapper)?.annotation})
        }
    }

    func showRegularAnnotations(for locations: [DepositionPointProtocol]) {
        let zoomScale = Double(mapView.bounds.width) / Double(mapView.visibleMapRect.width)
        let rect = mapView.visibleMapRect
        OperationQueue().addOperation {
            if self.cachedAnnotations == nil {
                self.cachedAnnotations = NSMutableSet(array: locations.compactMap { PointHashableWrapper(point: $0) })
                locations.forEach { location in
                    _ = self.treeRoot.insert(data: self.node(from: location))
                }
            } else {
//                let before = NSMutableSet(set: self.cachedAnnotations!)
                let after = NSMutableSet(array: locations.compactMap { PointHashableWrapper(point: $0) })
                let toKeep = NSMutableSet(set: self.cachedAnnotations!)
                if after.count > 0{
                    toKeep.intersect(after as! Set<PointHashableWrapper>)
                }

                let toAdd = NSMutableSet(set: after)
                if toKeep.count > 0{
                    toAdd.minus(toKeep as! Set<PointHashableWrapper>)
                }

                toAdd.allObjects.compactMap { $0 as? PointHashableWrapper }.forEach { wrapper in
                    _ = self.treeRoot.insert(data: self.node(from: wrapper.point))
                    // TODO: CRASHES SOMETIMES
                    self.cachedAnnotations?.add(wrapper)
                }
            }

            let annotations = self.quadTree.clusteredAnnotations(with: rect, zoomScale: MKZoomScale(zoomScale))
            OperationQueue().addOperation {
                self.update(annotations: annotations)
            }
        }
    }

    // MARK: MainMapViewInput

    func setupInitialState() {}
}

extension MainMapViewController {
    func node(from depositionPoint: DepositionPointProtocol) -> QuadTreeNodeData<DepositionPointProtocol> {
        return QuadTreeNodeData(x: Double(depositionPoint.location?.latitude ?? 0), y: Double(depositionPoint.location?.longitude ?? 0), data: depositionPoint)
    }

    func tree(from locations: [DepositionPointProtocol]) -> QuadTreeNode<DepositionPointProtocol> {
        let wordBox = BoundingBox(x0: 0, y0: -166, xf: 200, yf: 100)
        return QuadTreeNode(data: locations.compactMap { node(from: $0) }, box: wordBox, capacity: 4)
    }
}

extension MainMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated _: Bool) {
        let centerLat = mapView.centerCoordinate.latitude
        let centerLon = mapView.centerCoordinate.longitude
        let radius = mapView.currentRadius()

        output.userDidChangeMapConfiguration(lat: centerLat, lon: centerLon, radius: radius)
    }

    func mapView(_: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            if let pin = view.annotation as? MapPin {
//                if pin.needToAnimateOnAppearance{
                let animation = CAKeyframeAnimation(keyPath: "transform.scale")

                animation.values = [0.05, 1.1, 0.9, 1]
                animation.duration = 0.6
                animation.timingFunctions = Array(repeating: CAMediaTimingFunction(name: .easeInEaseOut), count: 4)
                animation.isRemovedOnCompletion = false
                view.layer.add(animation, forKey: "bounce")
                pin.needToAnimateOnAppearance = false
//                }
            }
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? MapPin else { return nil }

        let id = "annotations"
        var view: MKMarkerAnnotationView!

        if let newView = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView {
            view = newView
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
        }

        view.annotation = annotation
        view.displayPriority = .required
        view.layer.shadowRadius = 0
        view.glyphText = String(annotation.count)
        view.glyphTintColor = UIColor.black
        view.markerTintColor = UIColor.yellow
        view.canShowCallout = false
        view.isUserInteractionEnabled = false

        if let imageView = view.viewWithTag(imageViewTag) as? UIImageView {
            imageView.image = nil
        }
        if annotation.count == 1 {
            output.fetchPartner(for: annotation.depositionPoint, completion: { partner in
                if partner != nil && annotation.count == 1 {
                    view.glyphText = partner!.name

                    let setImage: (UIImage) -> Void = { image in
                        if annotation.count == 1 {
                            view.glyphText = nil
                            if let imageView = view.viewWithTag(self.imageViewTag) as? UIImageView {
                                imageView.image = image
                                view.bringSubviewToFront(imageView)
                            } else {
                                let imageView = UIImageView()
                                imageView.image = image
                                imageView.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
                                imageView.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2 - 5)
                                imageView.layer.cornerRadius = 12.5
                                imageView.layer.masksToBounds = true
                                imageView.tag = self.imageViewTag
                                view.addSubview(imageView)
                                view.bringSubviewToFront(imageView)
                            }
                        }
                    }

                    self.output.getImage(for: partner!, cached: setImage, completion: setImage)
                } else {
                    if let imageView = view.viewWithTag(self.imageViewTag) as? UIImageView {
                        imageView.image = nil
                    }
                }
            })
        } else {
            if let imageView = view.viewWithTag(imageViewTag) as? UIImageView {
                imageView.image = nil
            }
        }
        if let imageView = view.viewWithTag(imageViewTag) as? UIImageView {
            view.bringSubviewToFront(imageView)
        }
        return view
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let imageView = view.viewWithTag(imageViewTag) as? UIImageView {
            imageView.image = nil
        }

        if let mapPin = view.annotation as? MapPin {
            mapView.setRegion(MKCoordinateRegion(center: mapPin.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000), animated: true)
        }
    }
}

extension MainMapViewController: CLLocationManagerDelegate {
    func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        mapView.showsUserLocation = false
        locationButton.isEnabled = false
        switch status {
        case .notDetermined:
            print("NotDetermined")
        case .restricted:
            print("Restricted")
        case .denied:
            print("Denied")
        case .authorizedAlways:
            print("AuthorizedAlways")
            mapView.showsUserLocation = true
            locationButton.isEnabled = true
            locationManager!.startUpdatingLocation()
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            locationButton.isEnabled = true
            print("AuthorizedWhenInUse")
            locationManager!.startUpdatingLocation()
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first!
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(coordinateRegion, animated: false)
        locationManager?.stopUpdatingLocation()
        locationManager = nil
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        print("Failed to initialize GPS: ", error)
    }
}

extension MainMapViewController {
    @IBAction func zoomIn(_ sender: UIButton) {
        animatePressing(button: sender)

        zoomMap(byFactor: 0.5)
    }

    @IBAction func zoomOut(_ sender: UIButton) {
        animatePressing(button: sender)

        zoomMap(byFactor: 2)
    }

    @IBAction func centerUser(_ sender: UIButton) {
        animatePressing(button: sender)

        let coordinateRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(coordinateRegion, animated: false)
    }

    func zoomMap(byFactor delta: Double) {
        var region: MKCoordinateRegion = mapView.region
        var span: MKCoordinateSpan = mapView.region.span
        span.latitudeDelta *= delta
        span.longitudeDelta *= delta
        region.span = span
        mapView.setRegion(region, animated: true)
    }

    func animatePressing(button: UIButton) {
        UIView.animate(withDuration: 0.15, animations: {
            button.transform = CGAffineTransform(scaleX: 0.91, y: 0.91)
        }, completion: { _ in
            UIView.animate(withDuration: 0.15, animations: {
                button.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: nil)
        })
    }
}

extension MKMapView {
    func topCenterCoordinate() -> CLLocationCoordinate2D {
        return convert(CGPoint(x: frame.size.width / 2.0, y: 0), toCoordinateFrom: self)
    }

    func currentRadius() -> Double {
        let centerLocation = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
        let topCenterCoordinate = self.topCenterCoordinate()
        let topCenterLocation = CLLocation(latitude: topCenterCoordinate.latitude, longitude: topCenterCoordinate.longitude)
        return centerLocation.distance(from: topCenterLocation)
    }
}
