//
//  UICommon.swift
//  Project 4 Virtual tourist
//
//  Created by Michael Harper on 10/7/15.
//  Copyright © 2015 hxx. All rights reserved.
//

import UIKit


// Display alert
func displayError(_ view: UIViewController, errorString: String?) {
    DispatchQueue.main.async(execute: {
        //present view controller
        var alert: UIAlertController!
        
        alert = UIAlertController(title: errorString, message: errorString, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        view.present(alert, animated: true, completion: nil)
        
    })
}

//shake a view
func shakeViewController(_ view: UIViewController) {
    
    let animation = CABasicAnimation(keyPath: "position")
    animation.duration = 0.07
    animation.repeatCount = 4
    animation.autoreverses = true
    animation.fromValue =
        NSValue(cgPoint: CGPoint(x: view.view.center.x - 10, y: view.view.center.y))
    animation.toValue = NSValue(cgPoint: CGPoint(x: view.view.center.x + 10, y: view.view.center.y))
    view.view.layer.add(animation, forKey: "position")
    
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


