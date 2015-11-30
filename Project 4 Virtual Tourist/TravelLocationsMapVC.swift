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

    var editButton: UIBarButtonItem! = nil
    var longPressGesture: UILongPressGestureRecognizer! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Mark: UI - Custom Navigation buttons
        editButton = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: "editButtonPressed:")
        
        let rightButtons = [editButton!]
        self.navigationItem.rightBarButtonItems = rightButtons
        mapView.delegate = self
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longPressGesture.minimumPressDuration = 1.0
        
        mapView.addGestureRecognizer(longPressGesture)
        
        //pinButton = UIBarButtonItem(image: pinImage, style: UIBarButtonItemStyle.Plain, target: self, action: "pinButtonPressed:")

        
    }
    
    //MARK: MapView Delegates and such
    
    // create a view with a "right callout accessory view".
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            pinView?.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if control == annotationView.rightCalloutAccessoryView {
            let app = UIApplication.sharedApplication()
            app.openURL(NSURL(string: annotationView.annotation!.subtitle!!)!)
        }
    }
    
    
    
    
    func editButtonPressed(sender: UIButton) {
        print("edit Button pressed")
        dispatch_async(dispatch_get_main_queue(), {
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("photoAlbumsVC")
            self.presentViewController(controller, animated: true, completion: nil)
        })

    }
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            mapView.addAnnotation(annotation)
        }
        
    }


}

