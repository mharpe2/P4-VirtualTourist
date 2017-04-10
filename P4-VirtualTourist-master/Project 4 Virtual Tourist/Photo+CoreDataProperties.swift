//
//  Photo+CoreDataProperties.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 3/28/17.
//  Copyright © 2017 hxx. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var fileName: String?
    @NSManaged public var title: String?
    @NSManaged public var url: String?
    @NSManaged public var location: Location?

}
