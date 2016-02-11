//
//  PhotoAlbumsVC.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 11/11/15.
//  Copyright © 2015 hxx. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumsVC: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var colletionView: UICollectionView!
    @IBOutlet weak var layout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    var oKButton: UIBarButtonItem!
    var selectedLocation: Location!
    
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()

            
    
    // fetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        //Create fetch request for photos which match the sent Location.
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        // handle duplicates
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.selectedLocation)
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
        fetchRequest.sortDescriptors = []

        
        //Create fetched results controller with the new fetch request.
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Mark: UI - Custom Navigation buttons
        oKButton = UIBarButtonItem(title: "Ok", style: .Plain, target: self, action: "oKButtonPressed:")
        
        let leftButtons = [oKButton!]
        self.navigationItem.leftBarButtonItems = leftButtons
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        // center map around selectedLocation
        if selectedLocation != nil {
            
            // add the annotation to map
            mapView.addAnnotation(selectedLocation)
        }
        
        // Core Data 
        
        // Step 2: invoke fetchedResultsController.performFetch(nil) here
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        // Step 9: set the fetchedResultsController.delegate = self
        
        //Delegates
        fetchedResultsController.delegate = self
        mapView.delegate = self
        colletionView.delegate = self
        colletionView.dataSource = self


    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    //MARK: CollectionView
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        //Disallow selection if the cell is waiting for its image to appear.
        //if cell.activityIndicatorView.isAnimating() {
            
        //    return false
        //}
        
        return true
    }

    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        guard let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo? else {
            return 1
            }
        
        return sectionInfo.numberOfObjects
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // dequeued cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotoCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        if photo.image != nil {
            cell.imageView.image = photo.image
        }
        
        // confiure cell
        configureCell(cell, photo: photo)
    
        return cell
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath)
    {
        //
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        //
        if photo.image == nil {
            
            //UI changes to indicate activity.
            //cell.activityIndicatorView.startAnimating()
            cell.imageView.alpha = 0.0
            cell.imageView.image = nil
            
            //retryImageDownloadForPhoto(photo)
            return
        }

       
    }
    
    //MARK: MapView
    
    // create a view with a "right callout accessory view".
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "Location"
        var LocationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if LocationView == nil {
            LocationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            LocationView!.canShowCallout = false
            LocationView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            LocationView?.animatesDrop = true
        }
        else {
            LocationView!.annotation = annotation
        }
        
        return LocationView
    }
    
    // delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
    }
    
    @IBAction func oKButtonPressed(sender: AnyObject) {
        
        navigationController?.popViewControllerAnimated(true)
    }


   //MARK: Collection View Helpers
    
    func configureCell(cell: PhotoCell, photo: Photo) {
        var posterImage = UIImage(named: "posterPlaceHoldr")
        
        //cell.textLabel!.text = photo.title
        cell.imageView!.image = nil
        
        // Set the photo Poster Image
        
        if photo.imagePath == nil || photo.imagePath == "" {
            posterImage = UIImage(named: "noImage")
        } else if photo.imagePath != nil {
            posterImage = photo.image
        }
            
        else { // This is the interesting case. The photo has an image name, but it is not downloaded yet.
            
            // This first line returns a string representing the second to the smallest size that ThephotoDB serves up
            //let size = ThephotoDB.sharedInstance().config.posterSizes[1]
            
            // Start the task that will eventually download the image
//            let task = ThephotoDB.sharedInstance().taskForImageWithSize(size, filePath: photo.posterPath!) { data, error in
//                
//                if let error = error {
//                    print("Poster download error: \(error.localizedDescription)")
//                }
//                
//                if let data = data {
//                    // Craete the image
//                    let image = UIImage(data: data)
//                    
//                    // update the model, so that the infrmation gets cashed
//                    photo.posterImage = image
//                    
//                    // update the cell later, on the main thread
//                    
//                    dispatch_async(dispatch_get_main_queue()) {
//                        cell.imageView!.image = image
//                    }
//                }
//            }
            
            // This is the custom property on this cell. See TaskCancelingTableViewCell.swift for details.
            //cell.taskToCancelifCellIsReused = task
            
            //TODO: ????
        }
        
        cell.imageView!.image = posterImage
    }

}


