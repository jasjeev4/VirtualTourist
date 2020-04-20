//
//  PointViewController.swift
//  VirutalTourist
//
//  Created by JASJEEV on 4/18/20.
//  Copyright © 2020 Lorgarithmic Science. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PointViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    var coordinates: CLLocationCoordinate2D!
    var dataController: DataController!
    var pin: Pin!
    @IBOutlet weak var collectionButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    
    private var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    
    @IBAction func onBackClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "photoID", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        
        // print(coordinates)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Generate pins.
        let myPin: MKPointAnnotation = MKPointAnnotation()
        
        // Set the coordinates.
        myPin.coordinate = coordinates
        
        
        
        
        // Set the title.
        myPin.title = "\(coordinates.latitude), \(coordinates.longitude)"
        
        // Set subtitle.
        // myPin.subtitle = "subtitle"
        
        // Added pins to MapView.
        mapView.addAnnotation(myPin)
        
        //center map coordinates
        centerMap()
        
        setupFetchedResultsController()

        // If we don't have any photos, fetch from the API
        if (pin.photos?.count ?? 0 == 0) {
            fetchPhotosFromApi()
        } else {
            collectionButton.isEnabled = true
        }
    }
 
    func fetchPhotosFromApi() {
        // ctivityIndicator?.startAnimating()
        collectionButton?.isEnabled = false
        
        FlickrClient.searchPhotos(lat: "\(coordinates.latitude ?? 0.0)", long: "\(coordinates.longitude ?? 0.0)", completion: handleSearchApiResponse(photos:error:))
    }
    
    func savePhotos(photos: [Photos]) {
        photos.forEach { (photoResponse) in
            let newPhoto = Photo(context: dataController.viewContext)
            newPhoto.pin = pin
            newPhoto.photoID = photoResponse.id
            newPhoto.title = photoResponse.title
            newPhoto.url = FlickrClient.Endpoints.getPhoto(farmId: photoResponse.farm, serverId: photoResponse.server, photoId: photoResponse.id, photoSecret: photoResponse.secret).stringValue
            
            do {
                try dataController.viewContext.save()
            } catch {
                print("ERROR: Failed to write photo")
                // showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    func centerMap() {
        // Load from memory
        
        let latitude = coordinates.latitude
        let longitude = coordinates.longitude        //let region =  UserDefaults.standard.data(forKey: "region")
        
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        mapView.setCenter(coordinates, animated: true)
        //mapView.setRegion(region, animated: true)
    }
    
    private func downloadPhotos() {
        
        collectionButton.isEnabled = false
        
        FlickrClient.searchPhotos(lat: "\(coordinates.latitude )", long: "\(coordinates.longitude)", completion: handleSearchApiResponse(photos:error:))
    }
    
    private func handleSearchApiResponse(photos: [Photos]?, error: Error?) {
        collectionButton?.isEnabled = true
        
        guard let photos = photos else {
            print("No images found")
            //errorLabel?.text = "No images found"
            return
        }
        if photos.count == 0 {
            print("No images found")
            //errorLabel?.text = "No images found"
        } else {
            print(photos)
            //savePhotos(photos: photos)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellPhoto = fetchedResultsController.object(at: indexPath)

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionCell", for: indexPath) as! AlbumCell
        if let url = cellPhoto.url {
            if let downloadedData = cellPhoto.pic {
                if let downloadedImage = UIImage(data: downloadedData) {
                    cell.image?.image = downloadedImage
                }
            } else {
                FlickrClient.downloadPhoto(urlString: url) { (image, error) in
                    guard let image = image else {
                        return
                    }
                    cellPhoto.pic = image
                    try? self.dataController.viewContext.save()
                }
            }
        }
        return cell
    }
}

