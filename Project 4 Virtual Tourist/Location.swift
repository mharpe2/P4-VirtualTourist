//
//  Location.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 11/30/15.
//  Copyright © 2015 hxx. All rights reserved.
//

import CoreData
import MapKit

class Location: NSManagedObject, MKAnnotation {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [SimplePhoto]
    
    // conform to MKAnnotation
    var coordinate: CLLocationCoordinate2D {
        
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
        
        get {
            return CLLocationCoordinate2DMake(latitude, longitude)
        }
    }
    
    struct Keys {
        static let latitude = "latitude"
        static let longitude = "longitude"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    //
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        //CoreData
        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        //Dictionary
        latitude = dictionary[Keys.latitude] as! Double
        longitude = dictionary[Keys.longitude ] as! Double
    }
    
    init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        
        //CoreData
        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = latitude
        self.longitude = longitude

    }
    
    class func makeLocation(latitude: Double, longitude: Double, context: NSManagedObjectContext?) -> Location {
        
        let coordinates = [self.Keys.latitude: latitude, self.Keys.longitude: longitude]
        let location = Location(dictionary: coordinates, context: context!)
        return location
        
    }
    
        
   
}