//
//  ViewController.swift
//  Photage
//
//  Created by Kelvin Lam on 4/29/16.
//  Copyright © 2016 Lins. All rights reserved.
//

import UIKit

class ViewController: UIViewController {


    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var zipButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var welcomeLabel: UILabel!
    
    @IBOutlet weak var signButton: UIButton!
    @IBOutlet weak var cropButton: UIButton!
    @IBOutlet weak var fetchButton: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let isLoggedIn = User.instance.isLoggedIn()
        
        //Hide components if a user has not signed in yet.
        headerView.hidden = !isLoggedIn
        collectionView.hidden = !isLoggedIn
        cropButton.hidden = !isLoggedIn
        fetchButton.hidden = !isLoggedIn
        
        welcomeLabel.hidden = isLoggedIn
        signButton.hidden = isLoggedIn
    }
    
    @IBAction func didTapFetch(sender: AnyObject) {
    }
    
    @IBAction func didTapCrop(sender: AnyObject) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

