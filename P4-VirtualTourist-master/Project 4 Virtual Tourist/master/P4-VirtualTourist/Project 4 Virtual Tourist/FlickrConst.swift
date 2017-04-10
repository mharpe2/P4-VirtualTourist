//
//  FlikrConst.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 11/5/15.
//  Copyright © 2015 hxx. All rights reserved.
//

import Foundation


// MARK: - Files Support
private let _documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
private let _fileURL: NSURL = _documentsDirectoryURL.URLByAppendingPathComponent("Flickr-Context")

extension FlickrClient {

    
    // Right Side values
    struct const {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let PHOTO_SEARCH = "flickr.photos.search"
        static let GETPHOTOS = "flickr.galleries.getPhotos"
        static let API_KEY = "c8902f02cddab705350a2d3c1e13a49c"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
    }
    
    // Left Side values
    struct methodParameters {
        static let api_key = "api_key"
        static let method = "method"
        static let bbox = "bbox"
        static let extras = "extras"
        static let dataFormat = "json"
        static let format = "format"
        static let noJsonCallback = "nojsoncallback"
        static let safeSearch = "safe_search"
        static let galleryId = "gallery_id"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let page = "page"
        static let perPage = "per_page"
    }
    
    struct jsonResponse{
        static let photo = "photo"
        static let photos = "photos"
        static let pages = "pages"
        static let title = "title"
        static let imageType = "url_m"
        static let status = "stat"
        static let msg = "message"
        static let code = "code"
    }
    
    struct jsonRepsonseVals {
        static let success = "ok"
        static let failure = "fail"
    }
    
    class func getPhotoByLocationParameters() -> [String:String] {
    return
        [
        methodParameters.method: const.PHOTO_SEARCH,
        methodParameters.api_key: const.API_KEY,
        methodParameters.bbox: "38.9047, 77.0164", // Washington D.C.
        methodParameters.extras: const.EXTRAS,
        methodParameters.dataFormat : const.DATA_FORMAT,
        methodParameters.noJsonCallback: const.NO_JSON_CALLBACK
        ]
    }
    
    
}
