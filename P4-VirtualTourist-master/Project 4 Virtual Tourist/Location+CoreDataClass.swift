//
//  Location+CoreDataClass.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 3/28/17.
//  Copyright © 2017 hxx. All rights reserved.
//

import Foundation
import CoreData
import MapKit

public class Location: NSManagedObject, MKAnnotation {

    
    struct Keys {
        static let location = "Location"
        static let longitude = "longitude"
        static let latitude = "latitude"
        static let numPages = "numberOfPages"
    }
    
    // conform to MKAnnotation
    public var coordinate: CLLocationCoordinate2D {
        set {
            self.latitude = newValue.latitude as NSNumber?
            self.longitude = newValue.longitude as NSNumber?
        }
        
        get {
            return CLLocationCoordinate2DMake(latitude as! CLLocationDegrees, longitude as! CLLocationDegrees)
        }
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(coordiante: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        
        // Core Data
        let entity = NSEntityDescription.entity(forEntityName: Keys.location, in: context)!
        super.init(entity: entity, insertInto: context)
        
        longitude = coordiante.longitude as NSNumber?
        latitude = coordiante.latitude as NSNumber?
        //geohash = Geohash.encode(latitude: latitude, longitude: longitude)
        self.photos = NSMutableOrderedSet()
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entity(forEntityName: Keys.location, in: context)!
        super.init(entity: entity, insertInto: context)
        
        if let lat = dictionary[Keys.latitude] as! Double? {
            if let long = dictionary[Keys.longitude] as! Double? {
                latitude = lat as NSNumber?
                longitude = long as NSNumber?
                // geohash = Geohash.encode(latitude: latitude, longitude: longitude)
            }
        }
        numberOfPages = dictionary[Keys.numPages]  as? NSNumber
        self.photos = NSMutableOrderedSet()
    }
    
    //MARK: override DESCRIPTION
    override public var description: String {
        return String("Location: \(latitude), \(longitude), \(numberOfPages)")
    }
    
}

//MARK: == Operator
// isEqual
func ==(lhs: Location, rhs: Location) -> Bool {
    
    //return ( (lhs.longitude == rhs.longitude) && (lhs.latitude == rhs.latitude))
    return ( lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude)

}
