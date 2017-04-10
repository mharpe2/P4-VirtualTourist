//
//  FlickrClient.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 11/5/15.
//  Copyright © 2015 hxx. All rights reserved.
//

import UIKit
import MapKit
import Foundation
import CoreData

class FlickrClient: NSObject {
    
    //typealias CompletionHander = (_ result: Any?, _ error: NSError?) -> Void
    
    let ad = UIApplication.shared.delegate as! AppDelegate
    var sharedContext: NSManagedObjectContext!
    
    
    
    //    var sharedContext = {
    //        return CoreDataStackManager.sharedInstance().persistentContainer.viewContext
    //    }
    
    // Session
    var session: URLSession!
    var lastLocation: Location!
    var lastPage = 0
    
    override init() {
        session = URLSession.shared
        sharedContext = ad.coreData.persistentContainer.viewContext
        super.init()
    }
    
    // download a list of image urls assocatiated with a location
    func getImageUrlsByLocation(_ location: Location,
                                completionHandler: @escaping (_ result: [[String: AnyObject]]?, _ error: NSError?, _ numPages: Int?) -> Void ) {
        let sharedContext = ad.coreData.persistentContainer.viewContext
        // visit pages incrementally
        var page = 0
        
        // if browsing a new location reset page counter
        if lastLocation != location {
            lastLocation = location
            lastPage = 0
        } else  {
            //if let numPages = location.numberOfPages //{
            if Int(location.numberOfPages!) > 0 {
                // loop around pages
                let page = (lastPage + 1) % Int(location.numberOfPages!)
                lastPage = Int(page)
                //}
            }
        }
        if page == 0 {
            page = 1
        }
        
        print(" selected page: \(page) of \(location.numberOfPages)")
        
        
        let methodArguments: [String: Any] = [
            methodParameters.method: const.PHOTO_SEARCH,
            methodParameters.api_key: const.API_KEY,
            methodParameters.extras: const.EXTRAS,
            methodParameters.format: const.DATA_FORMAT,
            methodParameters.noJsonCallback: const.NO_JSON_CALLBACK,
            "lat" : location.latitude ?? 0,
            "lon" : location.longitude ?? 0,
            methodParameters.page: page,
            methodParameters.perPage: 21
        ]
        
        _ = self.taskForGETMethod(methodArguments){ JSONResult, error in
            
            guard error == nil else {
                print(error! as NSError)
                completionHandler(nil, error, nil)
                return
            }
            
            // as? [String: Any] [jsonResponse.photos]
            let domainText = "getImagesByLocation"
            guard let photosDictionary = (JSONResult as AnyObject)[jsonResponse.photos]  else {
                let errorText = "Cant find key 'photo' in photosDictionary"
                print("\(errorText)")
                
                let dataError = NSError(domain: domainText, code: 0, userInfo: [NSLocalizedDescriptionKey : errorText])
                completionHandler(nil, dataError, nil)
                return
            }
            
            guard let numPages = (photosDictionary as AnyObject)[jsonResponse.pages] as? NSNumber else {
                let errorText = "Cant find key number of pages"
                print("\(errorText)")
                let dataError = NSError(domain: domainText, code: 0, userInfo: [NSLocalizedDescriptionKey : errorText])
                print(JSONResult)
                completionHandler(nil, dataError, nil)
                return
            }
            
            guard let photoArray = (photosDictionary as AnyObject)[jsonResponse.photo] as? [[String: AnyObject]] else {
                let errorText = "Cant find key 'photo' in photosDictionary"
                print("\(errorText)")
                let dataError = NSError(domain: domainText, code: 0, userInfo: [NSLocalizedDescriptionKey : errorText])
                completionHandler(nil, dataError, nil)
                return
            }
            
            print( "NumberOfPages \(numPages)")
            if (numPages.intValue != location.numberOfPages?.intValue ){
                location.numberOfPages = numPages
                
                do {
                    try sharedContext.save()
                }
                catch {
                    fatalError("Error in fetching records")
                }
                
                
            }
            completionHandler(photoArray, nil, numPages.intValue)
        }
        
    }
    
    //MARK: General networking funcs
    
    func taskForGETMethod(_ parameters: [String : Any], completionHandler: @escaping ((_ result: Any?, _ error: NSError?) -> Void)) -> URLSessionDataTask {
        
        
        /* 2/3. Build the URL and configure the request */
        let urlString = const.BASE_URL + escapedParameters(parameters)
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)
        
        /* 4. Make the request */
        let task = session.dataTask(with: request, completionHandler: {data, response, downloadError in
            
            guard let _ = data else {
                print("Error: did not recieve data")
                let dataError =  NSError(domain: "taskForGetMethod", code: 0, userInfo: [NSLocalizedDescriptionKey : "no data recieved"])
                completionHandler(nil, dataError)
                return
            }
            
            guard downloadError == nil else {
                print("Error: \(downloadError?.localizedDescription)")
                completionHandler(nil, downloadError as NSError?)
                return
            }
            
            // Success!
            FlickrClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
        })
        
        /* 7. Start the request */
        task.resume()
        return task
    }
    
    
    func taskForGETImage(_ filePath: String , completionHandler: @escaping (_ success: Bool, _ image: UIImage?, _ error: NSError?) ->  Void)  {
        
        
        // Set the parameters
        // 2/3. Build the URL and configure the request */
        let imageURL = URL(string: filePath)
        let task = URLSession.shared.dataTask(with: imageURL!) { (data, response, error) in
            
            if error == nil {
                
                // create image
                let downloadedImage = UIImage(data: data!)
                
                // update UI on a main thread
                performUIUpdatesOnMain {
                    //self.imageView.image = downloadedImage
                    completionHandler(true, downloadedImage, nil)
                }
                
            } else {
                let error = error as? NSError
                print(error?.localizedDescription ?? "Unknown Error")
                completionHandler(false, nil, error)
            }
        } // end of task
        
        // start network request
        task.resume()
    }
    
    // MARK: - Helpers
    
    class func errorForData(_ data: Data?, response: URLResponse?, error: NSError) -> NSError {
        
        if data == nil {
            return error
        }
        
        let  parsedResult: NSDictionary
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
            
            if let status = parsedResult[jsonResponse.status] as? String {
                let msg = parsedResult[jsonResponse.msg] as? String
                if status == jsonRepsonseVals.failure {
                    let reasonForFailure: [AnyHashable: Any] = [NSLocalizedDescriptionKey: msg!]
                    print("Error converting to json")
                    return NSError(domain: "errorForData", code: 0, userInfo: reasonForFailure  )
                    
                }
            }
        }catch error as NSError {
            print("Error converting to json")
            return error
            
        } catch _ {
            print("Error converting to json")
            return NSError(domain: "errorForData", code: 0, userInfo: [NSLocalizedDescriptionKey : "Error converting to json"])
        }
        
        guard let _ = parsedResult["msg"] as? String else {
            return NSError(domain: "errorForData", code: 0, userInfo: [NSLocalizedDescriptionKey : "Error: msg not found in parsed resut"])
        }
        return error
    }
    
    // Helper: Given raw JSON, return a usable Foundation object
    
    class func parseJSONWithCompletionHandler(_ data: Data, completionHandler: (_ result: Any?, _ error: NSError?) -> Void) {
        
        var parsedResult: Any? = nil
        
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
            
        } catch let error as NSError {
            completionHandler(nil, error)
            return
            
        } catch {
            completionHandler( nil, NSError(domain: "parseJSONWithCompletionHandler", code: 0,
                                            userInfo: [NSLocalizedDescriptionKey : "Error: msg not found in parsed resut"])
            )
            return
        }
        
        completionHandler(parsedResult, nil)
        
    }
    
    /* Helper: Substitute the key for the value that is contained within the method name */
    class func subtituteKeyInMethod(_ method: String, key: String, value: String) -> String? {
        if method.range(of: "{\(key)}") != nil {
            return method.replacingOccurrences(of: "{\(key)}", with: value)
        } else {
            return nil
        }
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(_ parameters: [String : Any]) -> String {
        
        var urlVars = [String]()
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joined(separator: "&")
    }
    
    /* helper function: get last path component of URL */
    //
    func getLastPathComponent(_ fullPath: String) -> String {
        return ( fullPath as NSString).lastPathComponent
    }
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    func fetchPhotosForLocation(_ location: Location) { //completionHandler: ((Void) -> (Void)) ) {
        
        FlickrClient.sharedInstance().getImageUrlsByLocation(location) {
            result, error, numPages in
            if result == nil {
                print("fetchPhotosForLocations returned nil")
                return
            }
            
            //_ = result.map() { ( dictionary: [[String : AnyObject]] ) -> Photo in
            for x in result! {
                
                let photo = Photo(dictionary: x , context: self.sharedContext)
                photo.location = location
                FlickrClient.sharedInstance().taskForGETImage(photo.url!, completionHandler: {
                    success, imageData, error in
                    
                    if success != true {
                        print("error extracting " + photo.url!)
                        return
                    }
                    
                    performUIUpdatesOnMain {
                        
                        
                        //if let url = URL(string:photo.url!) {
                        
                        // let data = try Data(contentsOf: url)
                        if let imageData = imageData {
                            photo.saveImage(imageData)
                        }
                        
                        do {
                            try self.sharedContext.save()
                        }catch _ {
                            print("Error Occuree")
                        }
                    } //end dispatch
                    
                })
            }
        }
    }
    
    
    
    //func downloadImage(_ photo: Photo) {
    //  _ = FlickrClient.sharedInstance().taskForGETImage(photo.url!, completionHandler: {
    //    success, imageData, error in
    //  if success != true {
    //    print("error extracting " + photo.url!)
    //} else {
    //   photo.saveImage(UIImage(data: imageData!))
    //print("saved \(photo.location)" )
    //  do {
    //     try self.sharedContext.save()
    // }
    //catch error as NSError? {
    //   print("Error Occuree")
    //   fatalError()
    // }
    //}
    //}) // end taskForGetImage
    //}
}


