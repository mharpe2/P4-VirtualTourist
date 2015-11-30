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
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
//        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("colCell", forIndexPath: indexPath) as! MemeCollectionCell
//        let meme = memes[indexPath.row]
//        
//        // Setup cell
//        cell.memedImage.contentMode = .ScaleAspectFit
//        cell.memedImage.image = meme.memeImage
        
        
        return UICollectionViewCell()
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath)
    {
        
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
    


    
}