//
//  Photo.swift
//  SleepingInTheLibrary
//
//  Created by Michael Harper on 11/25/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit
import CoreData

class SimplePhoto: NSManagedObject {
    
    @NSManaged var title: String
    @NSManaged var image: UIImage
    @NSManaged var place: Location?
    
    struct Keys {
        static let path = "path"
        static let title = "title"
        static let image = "image"
    }

    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        title = dictionary[Keys.title] as! String
        image = (dictionary[Keys.image] as? UIImage)!
    }
    
    init(withTitle: String, image: UIImage, location: Location, context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        self.title = withTitle
        self.image = image
        self.place = location


    }
   
    
}

