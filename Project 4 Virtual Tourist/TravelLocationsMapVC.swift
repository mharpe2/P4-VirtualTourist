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
    
    var sharedContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    
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
            return (self.deletePinView.hidden)
        }
        set  {
            self.deletePinView.hidden = newValue
            if self.deletePinView.hidden == true {
                editButton.title = const.edit
            } else {
                editButton.title = const.done
            }
        }
    }
    
    // MARK: Lifecycle & UI Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Mark: UI - Custom Navigation buttons
        editButton = UIBarButtonItem(title: const.edit, style: .Plain, target: self, action: #selector(TravelLocationsMapVC.editButtonPressed(_:)))
        
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
        
        print("fetchedLocations = \(self.fetchLocations())")
        print("count = \(self.fetchLocations().count)")
        self.mapView.addAnnotations( self.fetchLocations() )
        
    }

    func editButtonPressed(sender: UIButton) {
        dispatch_async(dispatch_get_main_queue()) {
            //Toogle view
            self.deletePinMode = !(self.deletePinMode)
        }
    }
    
    // MARK: Map Functions
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        guard let coordinate = view.annotation?.coordinate else {
            print("location not converted to annotation")
            return
        }
        
        // Delete Location
        if self.editButton.title == const.done {
            
            print("Deleting location \(coordinate)")
            //self.sharedContext.deleteObject(pin)
            let pin = view.annotation as! Location
            sharedContext().deleteObject(pin)
            removeDuplicateLocations(pin)
            mapView.removeAnnotation(pin)
            CoreDataStackManager.sharedInstance().saveContext()
           }
        
            // else view photoalbums
        else {
            
            // get last selected location
            let thisLocation = view.annotation as! Location
            //let photoSet = fetchPhotosForLocation(self.selectedLocation)
            
            // get PhotoAlbumsView controller
            let photoAlbumsVC = self.storyboard?.instantiateViewControllerWithIdentifier("photoAlbums") as! PhotoAlbumsVC
            
            // load selected location into photoVC
            photoAlbumsVC.selectedLocation = thisLocation
            self.navigationController?.pushViewController(photoAlbumsVC, animated: true)
        }
        
    }
    
    
    //create a view with a "right callout accessory view".
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotation = annotation as? Location {
            let identifier = "pin"
            var view: MKPinAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            }
            else{
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = false
                view.animatesDrop = true
                view.draggable = false
                
            }
            return view
        }
        return nil
        
    }
    
    // addAnnotation - Create map annaotation & get photosRK:
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        
        // Do not add pins when in delete mode
        if self.editButton.title == const.edit {
            
            // get referance to long press coords
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates: CLLocationCoordinate2D  = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            switch gestureRecognizer.state {
                
            case .Began:
                // create the location
                locationToBeAdded = Location(coordiante: newCoordinates, context: self.sharedContext())
                mapView.addAnnotation(locationToBeAdded!)
                
            case .Changed:
                // update coordinate on drag
                //https://discussions.udacity.com/t/how-can-i-make-a-new-pin-draggable-right-after-adding-it/26653
                locationToBeAdded!.willChangeValueForKey("coordinate")
                locationToBeAdded!.coordinate = newCoordinates
                locationToBeAdded!.didChangeValueForKey("coordinate")
                
            case .Ended:
                
                // save in completion handler??????
                FlickrClient.sharedInstance().fetchPhotosForLocation(locationToBeAdded!) { }
                CoreDataStackManager.sharedInstance().saveContext()
                print("count = \(self.fetchLocations().count)")
                
            default:
                return
            }
        }
    }
    
    //MARK: Helper Funcs
    
    func fetchLocations() -> [Location] {
        
        let error: NSError? = nil
        
        var results: [AnyObject]?
        let fetchRequest = NSFetchRequest(entityName: "Location")
        do {
            results = try sharedContext().executeFetchRequest(fetchRequest)
        
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
    
    
    func removeDuplicateLocations(location: Location) -> Int? {
        
       
        var error: NSError!
        
        let results: [AnyObject]?
        let fetchRequest = NSFetchRequest(entityName: Location.Keys.location)
        let predicate = NSPredicate(format: "geohash == %@" , location.geohash)
        fetchRequest.predicate = predicate
        
        do {
            results = try sharedContext().executeFetchRequest(fetchRequest)
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
                    self.sharedContext().deleteObject(x)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        return locationCounted
        }
    
    
    
    
    func doesLocationExist(latitiude: Double, longitude: Double) -> Bool {
        
        let geohash = Geohash.encode(latitude: latitiude, longitude: longitude)
        let fetchRequest = NSFetchRequest(entityName: Location.Keys.location)
        fetchRequest.predicate = NSPredicate(format: "geohash == %@" , geohash)
        
        let results: [AnyObject]?
        var error: NSError!
        do {
            results = try sharedContext().executeFetchRequest(fetchRequest)
            
        } catch error as NSError {
            
            results = nil
            return false
        } catch _ {
            results = nil
            return false
        }
        
        if error != nil {
            displayError(self, errorString: "Duplicate check failed")
        }
        
        if results!.isEmpty {
            return false
        }
        
        return true
    }
}