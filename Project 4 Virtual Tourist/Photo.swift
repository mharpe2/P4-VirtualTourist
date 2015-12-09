//
//  Photo.swift
//  SleepingInTheLibrary
//
//  Created by Michael Harper on 11/25/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation
import UIKit

class Photo {
    
    struct Keys {
        static let path = "path"
        static let title = "title"
        static let imageURL = "imageURL"
    }
    
    struct Error {
        static let noPath = "Path not found in init"
        static let noTitle = "Title not found in init"
    }
    
    var path: String? = nil
    var title: String = ""
    var imageData: NSData? = nil
    var imageURL: String = ""
    var image: UIImage? = nil
    
    init(dictionary: [String : AnyObject] ) {
        
        title = (dictionary[Keys.title] as? String)!
        path = (dictionary[Keys.path] as? String)!
        imageURL = (dictionary[Keys.imageURL] as? String)!
        
        /* 8 - If an image exists at the url, set the image and title */
        if let imageData = NSData(contentsOfURL: NSURL(fileURLWithPath: self.imageURL)) {
            self.image = UIImage(data: imageData)
            
        }
    } // end init
}

class SimplePhoto {
    
    var title: String = ""
    var image: UIImage? = nil
    var location: Location
    
    init(titleOfPhoto: String, image: UIImage, location: Location) {
        self.title = titleOfPhoto
        self.image = image
        self.location = location
    }
    
   
    
}