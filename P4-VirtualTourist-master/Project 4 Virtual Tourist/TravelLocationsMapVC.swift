//
//  TravelLocationsMapVC.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 11/4/15.
//  Copyright © 2015 hxx. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapVC: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinView: UIView!
    
    var editButton: UIBarButtonItem! = nil
    var longPressGesture: UILongPressGestureRecognizer! = nil
    
    var lastSelectedCoordinate: CLLocationCoordinate2D?
    var selectedLocation: Location! = nil
    var locationToBeAdded: Location? = nil
    
    let ad = UIApplication.shared.delegate as! AppDelegate
    var sharedContext: NSManagedObjectContext!
    
//        return ad.coreData.persistentContainer.viewContext
//
//        //persistentContainer.viewContext
//    }
    
    
    // Const strings
    struct const {
        static let done = "Done"
        static let edit = "Edit"
        static let segueToPhoto = "toPhotoAlbum"
    }
    
    // Manage pin delete modes
    // toggle deletePinView/edit butto with single variable
    var deletePinMode: Bool {
        get {
            // if delete pin view is not visible, then
            // not in delete mode
            return (self.deletePinView.isHidden)
        }
        set  {
            self.deletePinView.isHidden = newValue
            if self.deletePinView.isHidden == true {
                editButton.title = const.edit
            } else {
                editButton.title = const.done
            }
        }
    }
    
    // MARK: Lifecycle & UI Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sharedContext = ad.coreData.persistentContainer.viewContext
        
        //Mark: UI - Custom Navigation buttons
        editButton = UIBarButtonItem(title: const.edit, style: .plain, target: self, action: #selector(TravelLocationsMapVC.editButtonPressed(_:)))
        
        let rightButtons = [editButton!]
        self.navigationItem.rightBarButtonItems = rightButtons
        
        mapView.delegate = self
        
        longPressGesture =
            UILongPressGestureRecognizer(target: self,
                                         action: #selector(TravelLocationsMapVC.addAnnotation(_:) ))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.numberOfTapsRequired = 0
        longPressGesture.numberOfTouchesRequired = 1
        mapView.addGestureRecognizer(longPressGesture)
        
        let locations = fetchLocations()
        print("fetchedLocations = \(locations)")
        print("count = \(locations.count)")
        self.mapView.addAnnotations( locations )
        
    }

    func editButtonPressed(_ sender: UIButton) {
        DispatchQueue.main.async {
            //Toogle view
            self.deletePinMode = !(self.deletePinMode)
        }
    }
    
    // MARK: Map Functions
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let coordinate = view.annotation?.coordinate else {
            print("location not converted to annotation")
            return
        }
        
        // Delete Location
        if self.editButton.title == const.done {
            
            print("Deleting location \(coordinate)")
            //self.sharedContext.deleteObject(pin)
            let pin = view.annotation as! Location
            
//            //remove stored photos
//            for photo in pin.photos {
//                let image = photo as? Photo
//                image?.deleteImage()
//            }
            sharedContext.delete(pin)
            //removeDuplicateLocations(pin)
            mapView.removeAnnotation(pin)
            
            do {
                try sharedContext.save()
            } catch _ {
                fatalError()
            }
            
        }
        
            // else view photoalbums
        else {
            
            // get last selected location
            let thisLocation = view.annotation as! Location
            //let photoSet = fetchPhotosForLocation(self.selectedLocation)
            
            // get PhotoAlbumsView controller
            let photoAlbumsVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAlbums") as! PhotoAlbumsVC
            
            // load selected location into photoVC
            photoAlbumsVC.selectedLocation = thisLocation
            self.navigationController?.pushViewController(photoAlbumsVC, animated: true)
            mapView.deselectAnnotation(view.annotation, animated: true)
        }
        
    }
    
    
    //create a view with a "right callout accessory view".
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotation = annotation as? Location {
            let identifier = "pin"
            var view: MKPinAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            }
            else{
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = false
                view.animatesDrop = true
                view.isDraggable = false
                
            }
            return view
        }
        return nil
        
    }
    
    // addAnnotation - Create map annaotation & get photosRK:
    func addAnnotation(_ gestureRecognizer:UIGestureRecognizer){
        
        // Do not add pins when in delete mode
        if self.editButton.title == const.edit {
            
            // get referance to long press coords
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoordinates: CLLocationCoordinate2D  = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            switch gestureRecognizer.state {
                
            case .began:
                // create the location
                locationToBeAdded = Location(coordiante: newCoordinates, context: self.sharedContext)
                mapView.addAnnotation(locationToBeAdded!)
                
            case .changed:
                // update coordinate on drag
                //https://discussions.udacity.com/t/how-can-i-make-a-new-pin-draggable-right-after-adding-it/26653
                locationToBeAdded!.willChangeValue(forKey: "coordinate")
                locationToBeAdded!.coordinate = newCoordinates
                locationToBeAdded!.didChangeValue(forKey: "coordinate")
                
            case .ended:
                
                // save in completion handler??????
                FlickrClient.sharedInstance().fetchPhotosForLocation(locationToBeAdded!)
                
            default: break
            }
        }
    }
    
    //MARK: Helper Funcs
    
    func fetchLocations() -> [Location] {
        
        let error: NSError? = nil
        
        var results: [AnyObject]?
        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest() //as! NSFetchRequest<Location>
        //let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        do {
            results = try sharedContext.fetch(fetchRequest)
        
        } catch error! as NSError {
            
            results = nil
        } catch _ {
            results = nil
        }
        
        if error != nil {
            displayError(self, errorString: "Can not access previous locations")
        }
        return results as! [Location]
    }
    
    
    func removeDuplicateLocations(_ location: Location) -> Int? {
        
       
        var error: NSError!
        
        let results: [AnyObject]?
        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
        //let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Location.Keys.location)
        let predicate = NSPredicate(format: "longitude == %@",  location.longitude! )
        fetchRequest.predicate = predicate
        
        do {
            results = try sharedContext.fetch(fetchRequest)
        } catch error as NSError {
            
            results = nil
        } catch _ {
            results = nil
        }
        
        if error != nil {
            displayError(self, errorString: "fetch failed")
        }
        
        guard let locationResults = results as? [Location] else {
            return nil
        }
        
        var locationCounted = 0
        if !results!.isEmpty {
            for x in locationResults {
                    locationCounted = locationCounted + 1
                    self.sharedContext.delete(x)
                do {
                    try sharedContext.save()
                } catch _ {
                    print("can not save")
                    fatalError()
                }
                }
        return locationCounted
        }
        return locationCounted
    }
    
    
    
    
    
//    func doesLocationExist(_ latitiude: Double, longitude: Double) -> Bool {
//        
//        //let geohash = Geohash.encode(latitude: latitiude, longitude: longitude)
//        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest() as! NSFetchRequest<Location>
//        
//       // let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Location.Keys.location)
//        fetchRequest.predicate = NSPredicate(format: " == %@" , geohash)
//        
//        let results: [AnyObject]?
//        var error: NSError!
//        do {
//            results = try sharedContext().fetch(fetchRequest)
//            
//        } catch error as NSError {
//            
//            results = nil
//            return false
//        } catch _ {
//            results = nil
//            return false
//        }
//        
//        if error != nil {
//            displayError(self, errorString: "Duplicate check failed")
//        }
//        
//        if results!.isEmpty {
//            return false
//        }
//        
//        return true
//    }
}
