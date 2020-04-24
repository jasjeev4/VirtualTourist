//
//  ViewController.swift
//  VirutalTourist
//
//  Created by JASJEEV on 4/17/20.
//  Copyright © 2020 Lorgarithmic Science. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class HomeViewController: UIViewController, MKMapViewDelegate {
    var coordinates: CLLocationCoordinate2D!
    @IBOutlet weak var mapView: MKMapView!
    var chosenPin: Pin!
    var pinTitle: String!
    var pins: [NSManagedObject]!
    // MARK: - MKMapViewDelegate

//    private func setupFetchedResultsController() {
//        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
//
//        if let pins = try? dataController.viewContext.fetch(fetchRequest) {
//            pins.forEach { (pin) in
//                let lat = pin.latitude
//                let long = pin.longitude
//                let title = pin.title
//                //Convert to coordinates
//                let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: long)
//
//                // Generate pin
//                let myPin: MKPointAnnotation = MKPointAnnotation()
//                myPin.title = title
//                myPin.coordinate = coordinates
//
//
//                // Add to map
//                mapView.addAnnotation(myPin)
//            }
//        }
//    }
    
    private func setupFetchedResultsController() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
          return
        }

        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Pin")
        
        do {
            self.pins = try managedContext.fetch(fetchRequest)
           // Add pins to map
            pins.forEach { (pin) in
            // Generate pins.
            let myPin: MKPointAnnotation = MKPointAnnotation()

            // Set the coordinates.
            let lat = pin.value(forKey: "latitude")  as! Double
            let long = pin.value(forKey: "longitude")  as! Double
                                
            myPin.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)


            // Set the title.
            myPin.title = "\(lat), \(long)"

            // Added pins to MapView.
            mapView.addAnnotation(myPin)
        }
            
        } catch let error as NSError {
          print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        //olse
        
//        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
//
//        if let pins = try? dataController.viewContext.fetch(fetchRequest) {
//            pins.forEach { (pin) in
//                // Generate pins.
//                let myPin: MKPointAnnotation = MKPointAnnotation()
//
//                // Set the coordinates.
//                myPin.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
//
//
//                // Set the title.
//                myPin.title = "\(pin.latitude), \(pin.longitude)"
//
//                // Added pins to MapView.
//                mapView.addAnnotation(myPin)
//            }
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)

           // Center map to saved coordinates
            
           // Load user pins
       
           // delegate
           mapView.delegate = self
        
           // Generate long-press UIGestureRecognizer.
            let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
            longPress.addTarget(self, action: #selector(onLongPress(_:)))
        
            // Added UIGestureRecognizer to MapView.
            mapView.addGestureRecognizer(longPress)
    }
    
    func centerMap() {
        // Load from memory
        
        let latitude = UserDefaults.standard.double(forKey: "latitude")
        let longitude = UserDefaults.standard.double(forKey: "longitude")
        //let region =  UserDefaults.standard.data(forKey: "region")
        
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        mapView.setCenter(coordinates, animated: true)
        //mapView.setRegion(region, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Load pins
        setupFetchedResultsController()
        // center map
        centerMap()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        saveCoordinates()
    }
    
    func saveCoordinates() {
        // Save coordinates and zoom to preferences
        let printed = mapView.centerCoordinate
        print("Coordinates: \(printed) ")
        let latitude = printed.latitude
        let logitude = printed.longitude
        //var region = mapView.region
        //UserDefaults.standard.set(region, forKey: "region")
        UserDefaults.standard.set(latitude, forKey: "latitude")
        UserDefaults.standard.set(logitude, forKey: "longitude")
    }
    
    @objc private func onLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state != UIGestureRecognizer.State.began {
            return
        }
        
        // Get the coordinates of the point you pressed long.
        let location = sender.location(in: mapView)
        
        // Convert location to CLLocationCoordinate2D.
        let myCoordinate: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
        
        // Generate pins.
        let myPin: MKPointAnnotation = MKPointAnnotation()
        
        // Set the coordinates.
        myPin.coordinate = myCoordinate
        
        
        // Set the title.
        
        myPin.title = "\(myCoordinate.latitude), \(myCoordinate.longitude)"
        // print(myPin.title!)
        
        // Set subtitle.
        // myPin.subtitle = "subtitle"
        
        // Added pins to MapView.
        mapView.addAnnotation(myPin)
        
        
        savePin(title: myPin.title!, coordinates: myPin.coordinate)
    }
    
    func savePin(title: String, coordinates: CLLocationCoordinate2D) {
        guard let appDelegate =
          UIApplication.shared.delegate as? AppDelegate else {
          return
        }
        
        // 1
        let managedContext =
          appDelegate.persistentContainer.viewContext
        
        // 2
        let entity =
          NSEntityDescription.entity(forEntityName: "Pin",
                                     in: managedContext)!
        
        let pin = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
        
        // 3
        pin.setValue(title, forKeyPath: "title")
        pin.setValue(coordinates.latitude, forKeyPath: "latitude")
        pin.setValue(coordinates.longitude, forKeyPath: "longitude")
        
        // 4
        do {
          try managedContext.save()
           pins.append(pin)
        } catch let error as NSError {
          print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func showAlert(title: String, message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        show(alertVC, sender: nil)
    }

    
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives. Notice the similarity between this method and the cellForRowAtIndexPath
    // method in TableViewDataSource.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        let reuseId = "pine"

        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            // Add animation.
            pinView!.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }

        return pinView
    }
    
    // This delegate method is implemented to respond to taps. It performs a segue.
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            // Save coordinates
            saveCoordinates()
            
            coordinates = view.annotation?.coordinate
            chosenPin = Pin()
            let title = view.annotation?.title
            if let title = title {
                if let title = title {
                    print("Title: \(title) ")
                    self.pinTitle = title
                    chosenPin.title = title
                }
            }
            chosenPin.longitude = view.annotation?.coordinate.latitude as! Double
            chosenPin.latitude = view.annotation?.coordinate.latitude as! Double
            performSegue(withIdentifier: "showPin", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! PointViewController
        if let coordinates =  coordinates {
            vc.self.coordinates = coordinates
            vc.self.pin = chosenPin
            vc.self.pinTitle = pinTitle
        }
        else {
            print("Location not set")
        }
    }
}
