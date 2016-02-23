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

class TravelLocationsMapVC: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinView: UIView!
    
    var editButton: UIBarButtonItem! = nil
    var longPressGesture: UILongPressGestureRecognizer! = nil
    
    var lastSelectedCoordinate: CLLocationCoordinate2D?
    var selectedLocation: Location! = nil
    
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    
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
        editButton = UIBarButtonItem(title: const.edit, style: .Plain, target: self, action: "editButtonPressed:")
        
        let rightButtons = [editButton!]
        self.navigationItem.rightBarButtonItems = rightButtons
        
        mapView.delegate = self
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.numberOfTapsRequired = 0
        longPressGesture.numberOfTouchesRequired = 1
        //longPressGesture
        
        mapView.addGestureRecognizer(longPressGesture)
        mapView.addAnnotations( fetchLocations() )
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == const.segueToPhoto) {
            
            // TODO: Do we still need this?
            // set locations here
            //let navigationController = segue.destinationViewController as! PhotoAlbumsVC
            //navigationController.selectedLocation = lastSeletedLocation
        }
    }
    
    func editButtonPressed(sender: UIButton) {
        dispatch_async(dispatch_get_main_queue(), {
            //Toogle view
            self.deletePinMode = !(self.deletePinMode)
        })
    }
    
    // MARK: Map Functions
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        guard let coordinate = view.annotation?.coordinate else {
            print("location not converted to annotation")
            return
        }
        
        let pin = Location(coordiante: coordinate, context: sharedContext)
        //view.annotation as! Location
        
        // Check for if pin is to be deleted
        if self.editButton.title == const.done {
            
            print("Deleting location \(coordinate)")
            //self.sharedContext.deleteObject(pin)
            if let elementsDeleted = self.removeDuplicateLocations(pin) {
                print("removed \(elementsDeleted)")
            }
            CoreDataStackManager.sharedInstance().saveContext()
            mapView.removeAnnotation(pin)
            let allAnnotations = mapView.annotations
            mapView.removeAnnotations(allAnnotations)
            mapView.addAnnotations(self.fetchLocations())
            
        } else {
            
            print ("going to photo albums")
            // get last selected location
            self.selectedLocation = pin
            
            // get PhotoAlbumsView controller
            let photoAlbumsVC = self.storyboard?.instantiateViewControllerWithIdentifier("photoAlbums") as! PhotoAlbumsVC
            
            // load selected location into photoVC
            photoAlbumsVC.selectedLocation = pin
            self.navigationController?.pushViewController(photoAlbumsVC, animated: true)
        }
    }
    
    
    
    //create a view with a "right callout accessory view".
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            
            if self.editButton.title == const.done {
                pinView!.animatesDrop = false
            } else {
                pinView!.animatesDrop = true
            }
            pinView!.draggable = false
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    //MARK: addAnnotation - Create map annaotation & get photos
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        
        // Do not add pins when in delete mode
        if self.editButton.title == const.edit {
            
            if gestureRecognizer.state == UIGestureRecognizerState.Ended {
                
                // get referance to long press coords
                let touchPoint = gestureRecognizer.locationInView(mapView)
                let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
                let annotation = MKPointAnnotation()
                
                // add the annotation to map
                annotation.coordinate = newCoordinates
                mapView.addAnnotation(annotation)
                
                // If the location is not stored in core data then store it
                // else don't do anything with it
                if isDuplicateLocation(newCoordinates ) == false {
                    print("added location \(newCoordinates)")
                    selectedLocation = Location(coordiante: newCoordinates, context: sharedContext)
                    fetchPhotosForLocation( selectedLocation )
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        }
    }
    
    //MARK: Helper Funcs
    func fetchLocations() -> [Location] {
        
        var error: NSError!
        
        let results: [AnyObject]?
        let fetchRequest = NSFetchRequest(entityName: Location.Keys.location)
        
        do {
            results = try sharedContext.executeFetchRequest(fetchRequest)
        } catch error as NSError {
            
            results = nil
        } catch _ {
            results = nil
        }
        
        if error != nil {
            displayError(self, errorString: "Can not access previous locations")
        }
        return results as! [Location]
    }
    
    func isDuplicateLocation(coordinate: CLLocationCoordinate2D) -> Bool {
        
        var error: NSError!
        
        let results: [AnyObject]?
        let fetchRequest = NSFetchRequest(entityName: Location.Keys.location)
        
        do {
            results = try sharedContext.executeFetchRequest(fetchRequest)
        } catch error as NSError {
            
            results = nil
        } catch _ {
            results = nil
        }
        
        if error != nil {
            displayError(self, errorString: "Duplicate check failed")
        }
        
        guard let locationResults = results as? [Location] else {
            return false
        }
        
        var locationCounted = 0
        if !results!.isEmpty {
            for x in locationResults {
                if x.latitude == coordinate.latitude && x.longitude == coordinate.longitude {
                    locationCounted = locationCounted + 1
                    return true
                }
            }
        }
        print("Location is new")
        return false
    }
    
    func removeDuplicateLocations(location: Location) -> Int? {
        
        var error: NSError!
        
        let results: [AnyObject]?
        let fetchRequest = NSFetchRequest(entityName: Location.Keys.location)
        
        do {
            results = try sharedContext.executeFetchRequest(fetchRequest)
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
                if x.latitude == location.latitude && x.longitude == x.longitude {
                    locationCounted = locationCounted + 1
                    sharedContext.deleteObject(x)
                }
            }
        }
        return locationCounted
    }
    
    
    func fetchPhotosForLocation(location: Location) {
        FlickrClient.sharedInstance().getImageUrlsByLocation(location.latitude, long: location.longitude) {
            result, error in
            if result == nil {
                print("fetchPhotosForLocations returned nil")
                return
            }
            
            //Parse the array of movies dictionaries
            
            let _ = result.map() { (var dictionary: [String : AnyObject]) -> Photo in
                // 1 - dictionary[Photo.Keys.location] = location // add location data to dict
                let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                
                photo.location = location // use coredata relationship instead of // 1
                //location.photos.addObject(photo)
                //photo.image =
                FlickrClient.sharedInstance().taskForGETImage(photo.url!, completionHandler: {
                    success, imageData, error in
                    if success != true {
                        print("error extracting " + photo.url!)
                    } else {
                        photo.saveImage(UIImage(data: imageData!))
                    }
                })
            
                return photo
            }
        }
    }
}



