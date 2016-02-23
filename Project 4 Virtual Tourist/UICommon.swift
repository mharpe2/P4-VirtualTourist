//
//  UICommon.swift
//  P3_onTheMap
//
//  Created by Michael Harper on 10/7/15.
//  Copyright © 2015 hxx. All rights reserved.
//

import UIKit


// Display alert
func displayError(view: UIViewController, errorString: String?) {
    dispatch_async(dispatch_get_main_queue(), {
        //present view controller
        var alert: UIAlertController!
        
        alert = UIAlertController(title: errorString, message: errorString, preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
        view.presentViewController(alert, animated: true, completion: nil)
        
    })
}

//shake a view
func shakeViewController(view: UIViewController) {
    
    let animation = CABasicAnimation(keyPath: "position")
    animation.duration = 0.07
    animation.repeatCount = 4
    animation.autoreverses = true
    animation.fromValue =
        NSValue(CGPoint: CGPointMake(view.view.center.x - 10, view.view.center.y))
    animation.toValue = NSValue(CGPoint: CGPointMake(view.view.center.x + 10, view.view.center.y))
    view.view.layer.addAnimation(animation, forKey: "position")
    
}

//// Notify Success
//func displaySuccessTextAndFadeView( view: UIViewController, displayText: String, durration: Double) {
//    
//    let textAttributes = [
//        NSStrokeColorAttributeName : UIColor.blackColor(), //Fill in appropriate UIColor,
//        NSForegroundColorAttributeName : UIColor.whiteColor(), //Fill in UIColor,
//        NSFontAttributeName : UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
//        NSStrokeWidthAttributeName : -1
//        
//    ]
//    
//    var text = UILabel()
//    text.text = displayText
//    text.at
//    text.defaultTextAttributes = textAttributes
//    


