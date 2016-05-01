//
//  User.swift
//  Photage
//
//  Created by Kelvin Lam on 4/30/16.
//  Copyright © 2016 Lins. All rights reserved.
//

import UIKit

class User: NSObject{
    
    var token: String = ""
    var profileURL: String = ""
    var name: String = ""
    var images:[UIImage] = []
    
    func isLoggedIn() -> Bool {
        return !token.isEmpty
    }
    
    class var instance: User {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: User? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = User()
        }
        return Static.instance!
    }
    
}