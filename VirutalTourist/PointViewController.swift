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

class PointViewController: UIViewController, NSFetchedResultsControllerDelegate
{
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    var coordinates: CLLocationCoordinate2D!
    var photos: [NSManagedObject] = []
    //var photoAlbum[PhotoAlbum] = []
    var pin: Pin!
    var pinTitle: String!
    @IBOutlet weak var collectionButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBAction func refreshClick(_ sender: Any) {
        handleReload()
        setupFetchedResultsController()
        fetchPhotosFromApi()
        self.collectionView?.reloadData()
    }
    
    
    @IBAction func onBackClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func setupFetchedResultsController() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
          return
        }
        
      let managedContext = appDelegate.persistentContainer.viewContext
      let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Photo")
      fetchRequest.predicate = NSPredicate(format: "pin.title = %@", pinTitle)
      let sortDescriptor = NSSortDescriptor(key: "photoID", ascending: true)
      fetchRequest.sortDescriptors = [sortDescriptor]
      do {
        self.photos = try managedContext.fetch(fetchRequest)
          
          self.collectionView?.reloadData()
          // self.tableView.reloadData()
      } catch let error as NSError {
        print("Could not fetch. \(error), \(error.userInfo)")
      }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        
        // print(coordinates)

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Generate pins.
        let myPin: MKPointAnnotation = MKPointAnnotation()
        
        // Set the coordinates.
        myPin.coordinate = coordinates
        // Set the title.
        myPin.title = "\(coordinates.latitude), \(coordinates.longitude)"
        
        // Added pins to MapView.
        mapView.addAnnotation(myPin)
        
        //center map coordinates
        centerMap()
        
        setupFetchedResultsController()

        // If no photos, fetch from the API

        if (photos.count == 0) {
            fetchPhotosFromApi()
        } else {
            collectionButton.isEnabled = true
            self.collectionView?.reloadData()
        }
    }
 
    func fetchPhotosFromApi() {
        collectionButton?.isEnabled = false
        
        FlickrClient.searchPhotos(lat: "\(coordinates.latitude ?? 0.0)", long: "\(coordinates.longitude ?? 0.0)", completion: handleSearchApiResponse(photos:error:))
    }
    
    func savePhotos(photos: [Photos]) {
      //
            
//            let newPhoto = Photo(context: dataController.viewContext)
//            newPhoto.pin = pin
//            newPhoto.photoID = photoResponse.id
//            newPhoto.title = photoResponse.title
//            newPhoto.url = FlickrClient.Endpoints.getPhoto(farmId: photoResponse.farm, serverId: photoResponse.server, photoId: photoResponse.id, photoSecret: photoResponse.secret).stringValue
//
//            do {
//                try dataController.viewContext.save()
//            } catch {
//                print("ERROR: Failed to write photo")
//                // showAlert(title: "Error", message: error.localizedDescription)
//            }
        
        
        photos.forEach { (photoResponse) in
             // Save to store
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
              return
            }
            let managedContext = appDelegate.persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "Photo", in: managedContext)!
            let photo = NSManagedObject(entity: entity, insertInto: managedContext)
            photo.setValue(pin, forKeyPath: "pin")
            photo.setValue(photoResponse.id, forKeyPath: "photoID")
            photo.setValue(photoResponse.title, forKeyPath: "title")
            photo.setValue(FlickrClient.Endpoints.getPhoto(farmId: photoResponse.farm, serverId: photoResponse.server, photoId: photoResponse.id, photoSecret: photoResponse.secret).stringValue, forKeyPath: "url")
            print(photoResponse.id)
            do {
              try managedContext.save()
            } catch let error as NSError {
              print("Could not save. \(error), \(error.userInfo)")
            }
         }
        
        setupFetchedResultsController()
        self.collectionView?.reloadData()
            
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
            //self.photos = photos
            savePhotos(photos: photos)
        }
    }
}

// MARK: Extension to handle Collection View
extension PointViewController: UICollectionViewDataSource, UICollectionViewDelegate {
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return photos.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cellPhoto = self.photos[indexPath.item]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionCell", for: indexPath) as! AlbumCell
            let imageName = "Placeholder.png"
            let placeholder = UIImage(named: imageName)
            cell.image?.image = placeholder
            if let url = cellPhoto.value(forKeyPath: "url") as? String {
                if let downloadedData = cellPhoto.value(forKeyPath: "pic") {
                    if let downloadedImage = UIImage(data: downloadedData as! Data) {
                        cell.image?.image = downloadedImage
                    }
                } else {
                    FlickrClient.downloadPhoto(urlString: url) { (image, error) in
                        guard let image = image else {
                            return
                        }
                        cell.image?.image = UIImage(data: image)
                        cellPhoto.setValue(image, forKeyPath: "pic")
                       // save to store
                    }
                }
            }
            return cell
        }
    
    func collectionView(_ collectionView: UICollectionView,  didSelectItemAt indexPath: IndexPath) {
        let cellPhoto = self.photos[indexPath.item]
        let url = cellPhoto.value(forKeyPath: "url") as! String
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                 return
               }
               
             let managedContext = appDelegate.persistentContainer.viewContext
             let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Photo")
             fetchRequest.predicate = NSPredicate(format: "url = %@", url)
             do {
                 let test = try managedContext.fetch(fetchRequest)
                 let photo = test[0]
                 managedContext.delete(photo)
                 
                 setupFetchedResultsController()
                 try managedContext.save()
                 //self.collectionView?.reloadData()
             } catch let error as NSError {
               print("Could not fetch. \(error), \(error.userInfo)")
             }
    }
    
    func handleReload() {
        //pinTitle
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                 return
               }
               
             let managedContext = appDelegate.persistentContainer.viewContext
             let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Photo")
            fetchRequest.predicate = NSPredicate(format: "pin.title = %@", pinTitle)
             do {
                 let objs = try managedContext.fetch(fetchRequest)
                 for picture in objs {
                    managedContext.delete(picture)
                 }
                 setupFetchedResultsController()
                
                 //self.collectionView?.reloadData()
             } catch let error as NSError {
               print("Could not fetch. \(error), \(error.userInfo)")
             }
    }
    
    
}
