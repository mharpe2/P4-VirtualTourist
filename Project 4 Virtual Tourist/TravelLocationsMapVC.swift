//
//  TravelLocationsMapVC.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 11/4/15.
//  Copyright © 2015 hxx. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsMapVC: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var deletePinView: UIView!
    var editButton: UIBarButtonItem! = nil
    var longPressGesture: UILongPressGestureRecognizer! = nil
    var lastSeletedLocation: Location!
    
    // Manage pin delete modes
    // toggle deletePinView / edit button 
    // with single variable
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
    
    struct const {
        static let done = "Done"
        static let edit = "Edit"
        static let segueToPhoto = "toPhotoAlbum"
    }

    
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
        
    }
    
       override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == const.segueToPhoto) {
            
            // set locations here
            let navigationController = segue.destinationViewController as! PhotoAlbumsVC
        }
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        if editButton.title == const.done {
            let pin = view.annotation
            //sharedContext.deleteObject(pin)
            mapView.removeAnnotation(pin!)
            //CoreDataStackManager.sharedInstance.saveContext()
            return
        }
        
        lastSeletedLocation = Location(Latitude: view.annotation!.coordinate.latitude, Longitude: view.annotation!.coordinate.longitude)
        
        dispatch_async(dispatch_get_main_queue(), {
            //let controller = self.storyboard!.instantiateViewControllerWithIdentifier("photoAlbums")
            //self.presentViewController(controller, animated: true, completion: nil)
            self.performSegueWithIdentifier(const.segueToPhoto, sender: nil)
        })
    }
  
    
    func editButtonPressed(sender: UIButton) {
        dispatch_async(dispatch_get_main_queue(), {
            //Toogle view
            self.deletePinMode = !(self.deletePinMode)
        })
    }
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            mapView.addAnnotation(annotation)
            
            let pinLoc = Location(Latitude: annotation.coordinate.latitude, Longitude: annotation.coordinate.longitude )
            
            FlickrClient.sharedInstance().getImagesByLocation(pinLoc.latitude, long: pinLoc.longitude)
                {
                    success, error in
                    if success {
                        
                    } else {
                        print( error?.localizedDescription )
                    }
            }
        }
    }
}


