//
//  Photo.swift
//  SleepingInTheLibrary
//
//  Created by Michael Harper on 11/25/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit
import CoreData

class Photo: NSManagedObject {
    
    @NSManaged var location: Location?
    @NSManaged var url: String?
    @NSManaged var imagePath: String?
    
    struct Keys {
        static let url = "url"
        static let photo = "Photo"
        static let location = "Location"
        static let path = "pathToImage"
    }

    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        //Core Data
        let entity =  NSEntityDescription.entityForName(Keys.photo, inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        // Dictionary
        url = (dictionary[Keys.url] as? String)!
        location = (dictionary[Keys.location] as? Location)
        imagePath = (dictionary[Keys.path] as? String)
    }
    
    
    var image: UIImage? {
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(imagePath)
        }
        
        set {
            return FlickrClient.Caches.imageCache.storeImage(image, withIdentifier: imagePath!)
        }
    }
}

