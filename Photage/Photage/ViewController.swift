//
//  ViewController.swift
//  Photage
//
//  Created by Kelvin Lam on 4/29/16.
//  Copyright © 2016 Lins. All rights reserved.
//

import UIKit
import InstagramKit
import SDWebImage
import TOCropViewController

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, TOCropViewControllerDelegate {


    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var zipButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var welcomeLabel: UILabel!
    
    @IBOutlet weak var signButton: UIButton!
    
    private var imageArray:[AnyObject]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        imageArray = []
        zipButton.enabled = false
    }
    
    override func viewDidAppear(animated: Bool) {
        let isLoggedIn = User.instance.isLoggedIn()
        //Hide components if a user has not signed in yet.
        headerView.hidden = !isLoggedIn
        collectionView.hidden = !isLoggedIn
        zipButton.hidden = !isLoggedIn
        
        welcomeLabel.hidden = isLoggedIn
        signButton.hidden = isLoggedIn
        
        if isLoggedIn{
            fetchProfile()
            fetchImages()
        }
    }
    
    //Fetch current user's profile(name, profile photo url)
    func fetchProfile(){
        InstagramEngine.sharedEngine().getSelfUserDetailsWithSuccess(
            {(instagramUser) in
                if let u:InstagramUser = instagramUser {
                    self.nameLabel.text = u.username
                    self.profileImageView.sd_setImageWithURL(u.profilePictureURL)
                }
            }) {(err, serverStatusCode) in
                print("Error[getSelfUserDetailsWithSuccess]: \(err.localizedDescription)")
        }
    }
    
    //Fetch current user's recent feeds
    func fetchImages() {
        InstagramEngine.sharedEngine().getSelfRecentMediaWithSuccess(
            {(medias, pagination) in
                if let mediaArray:[InstagramMedia] = medias{
                    for media in mediaArray{
                        if self.imageArray.count<10{
                            self.imageArray.append(media.thumbnailURL)   
                        }
                    }
                    self.collectionView.reloadData()
                }
            
            }) { (err, statusCode) in
                print("Error[getSelfFeedWithSuccess]: \(err.localizedDescription)")
        }
    }
    
    //Count of images
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return imageArray.count
    }
    
    //Fill cells
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCell", forIndexPath: indexPath) as! ImageCell
        
        if let url = imageArray[indexPath.item] as? NSURL{
            cell.load(url)
        }else if let image = imageArray[indexPath.item] as? UIImage{
            cell.imageView.image = image
        }else{
            print("Wrong element type in image array")
        }
        return cell
    }
    
    //Tap a cell to present cropping view
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cropViewController = TOCropViewController.init(image: User.instance.images[indexPath.item])
        cropViewController.delegate = self
        self.presentViewController(cropViewController, animated: true, completion: nil)
    }
    
    //Process cropping
    func cropViewController(cropViewController: TOCropViewController!, didCropToImage image: UIImage!, withRect cropRect: CGRect, angle: Int) {
        imageArray.append(image)
        let indexPath = NSIndexPath(forRow: imageArray.count-1, inSection: 0)
        collectionView.insertItemsAtIndexPaths([indexPath])
        zipButton.enabled = true
        cropViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //Save images, zip and upload
    @IBAction func didTapZip(sender: AnyObject) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

