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
        longPressGesture.minimumPressDuration = 1.0
        
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
        
        guard let pin = view.annotation as? Location else {
            print("location not converted to annotation")
            return
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            
            if self.editButton.title == const.done {
                
                print("Deleting location")
                //dispatch_async(dispatch_get_main_queue(), {
                // delete location if it exists
                self.sharedContext.deleteObject(pin)
                
                CoreDataStackManager.sharedInstance().saveContext()
                
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.addAnnotations( self.fetchLocations() )
                return
                //})
            }
            
            //dispatch_async(dispatch_get_main_queue(), {
            
            print ("going to photo albums")
            // get last selected location
            //let location = view.annotation as! Location
            self.selectedLocation = pin
            // get PhotoAlbumsView controller
            let photoAlbumsVC = self.storyboard?.instantiateViewControllerWithIdentifier("photoAlbums") as! PhotoAlbumsVC
            
            // load selected location into photoVC
            photoAlbumsVC.selectedLocation = pin
            self.navigationController?.pushViewController(photoAlbumsVC, animated: true)
            
        })
    }
    
    
    // create a view with a "right callout accessory view".
    //    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
    //
    //        let reuseId = "pin"
    //        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
    //
    //        if pinView == nil {
    //            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
    //            pinView!.canShowCallout = false
    //            pinView!.animatesDrop = true
    //            pinView!.draggable = false
    //            //pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
    //        }
    //        else {
    //            pinView!.annotation = annotation
    //        }
    //
    //        return pinView
    //    }
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            
            // get referance to long press coords
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            
            // add the annotation to map
            annotation.coordinate = newCoordinates
            mapView.addAnnotation(annotation)
            
            // get images for location
            selectedLocation = Location(coordiante: annotation.coordinate, context: sharedContext)
            
            if !isDuplicateLocation(selectedLocation, toBeDeleted: true) {
                fetchPhotosForLocation( selectedLocation )
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
    
    func isDuplicateLocation(location: Location, toBeDeleted: Bool = false ) -> Bool {
        
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
                if x.latitude == location.latitude && x.longitude == x.longitude {
                    locationCounted = locationCounted + 1
                                    }
            }
            if locationCounted > 1 {
//                if toBeDeleted == true {
//                    print("Deleted \(x)")
//                    sharedContext.deleteObject(x)
//                }

                return true
            }
        }
        print("Location is new")
        return false
    }
    
    func fetchPhotosForLocation(location: Location) {
        FlickrClient.sharedInstance().getImagesByLocation(location.latitude, long: location.longitude)
            {
                success, error in
                if success {
                    
                    // update last location for seque
                    dispatch_async(dispatch_get_main_queue(), {
                        //CoreDataStackManager.sharedInstance().saveContext()
                    })
                    
                } else {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        print( error?.localizedDescription )
                        displayError(self, errorString: error?.localizedDescription)
                    })
                }
        }
    }
}

