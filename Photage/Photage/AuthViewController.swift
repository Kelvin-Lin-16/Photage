//
//  AuthViewController.swift
//  Photage
//
//  Created by Kelvin Lam on 4/30/16.
//  Copyright © 2016 Lins. All rights reserved.
//

import UIKit
import InstagramKit

class AuthViewController: UIViewController, UIWebViewDelegate{

    
    @IBOutlet var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let authURL = InstagramEngine.sharedEngine().authorizationURL()
        self.webView.loadRequest(NSURLRequest(URL: authURL))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        do {
            try InstagramEngine.sharedEngine().receivedValidAccessTokenFromURL(request.URL!)
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
        return true
    }
    
    @IBAction func didTapClose(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}