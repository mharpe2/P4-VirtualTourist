//
//  PhotoAlbumsVC.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 11/11/15.
//  Copyright © 2015 hxx. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumsVC: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    
    @IBOutlet weak var layout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    var oKButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Mark: UI - Custom Navigation buttons
        oKButton = UIBarButtonItem(title: "Ok", style: .Plain, target: self, action: "oKButtonPressed:")
        
        let leftButtons = [oKButton!]
        self.navigationItem.leftBarButtonItems = leftButtons
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0

    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return FlickrClient.sharedInstance().foundPhotos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotoCell    
        let photo  = FlickrClient.sharedInstance().foundPhotos[indexPath.row]
        
        // Setup cell
        //cell.imageView.contentMode = .ScaleAspectFit
        cell.imageView.image = photo.image
        
        
        return cell
        
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath)
    {
        
       
        var cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell!.layer.borderWidth = 3.0
        cell!.layer.borderColor = UIColor.grayColor().CGColor
        
        /*let detailController = storyboard!.instantiateViewControllerWithIdentifier("memeDetailView") as! MemeDetailViewController
        detailController.meme = memes[indexPath.row]
        detailController.memeIndex = indexPath.row
        
        navigationController!.pushViewController(detailController, animated: true)
        */
    }
    
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
        
    }
    
    @IBAction func oKButtonPressed(sender: AnyObject) {
        
        navigationController?.popViewControllerAnimated(true)
    }


    
}