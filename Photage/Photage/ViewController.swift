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
import FillableLoaders
import Zip
import AFNetworking

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, TOCropViewControllerDelegate {


    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var zipButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var welcomeLabel: UILabel!
    
    @IBOutlet weak var signButton: UIButton!
    
    private var imageArray:[AnyObject]!
    private var loader: FillableLoader = FillableLoader()
    private var isLoggedIn = false
    private var progress:Double! = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        imageArray = []
        zipButton.enabled = false
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateAuthStatus", name: "InstaAuthed", object: nil)
        updateUI()
    }
    
    override func viewDidAppear(animated: Bool) {

    }
    
    func updateAuthStatus() {
        isLoggedIn = User.instance.isLoggedIn()
        if isLoggedIn{
            fetchProfile()
            fetchImages()
            updateUI()
        }
    }
    
    func updateUI(){
        //Hide components if a user has not signed in yet.
        headerView.hidden = !isLoggedIn
        collectionView.hidden = !isLoggedIn
        zipButton.hidden = !isLoggedIn
        
        welcomeLabel.hidden = isLoggedIn
        signButton.hidden = isLoggedIn
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
                            self.imageArray.append(media.standardResolutionImageURL)   
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
        User.instance.images.append(image)
        let indexPath = NSIndexPath(forRow: imageArray.count-1, inSection: 0)
        collectionView.insertItemsAtIndexPaths([indexPath])
        zipButton.enabled = true
        cropViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //Save images, zip and upload
    @IBAction func didTapZip(sender: AnyObject) {
        loader = WavesLoader.showProgressBasedLoaderWithPath(githubPath())
        updateProgress(0.0)
        var paths:[NSURL] = []
        //Save images to a directory
        for(var i = 0; i<User.instance.images.count;i++){
            if let data = UIImageJPEGRepresentation(User.instance.images[i] , 0.95) {
                let filename = getDocumentsDirectory().stringByAppendingPathComponent("\(i).jpg")
                let url:NSURL = NSURL(fileURLWithPath: filename)
                data.writeToURL(url, atomically: true)
                paths.append(url)
                updateProgress(0.02)
            }
        }
        //Zip the directory
        do {
            let zipFilePath = try Zip.quickZipFiles(paths, fileName: "archive")
            updateProgress(0.2)
            //Upload
            let data:NSData = NSData(contentsOfURL:zipFilePath)!//UIImageJPEGRepresentation(User.instance.images[0] , 0.8)!
            let url = "http://www.linsapp.com/api/messages/zip"
            let request = AFHTTPRequestSerializer().multipartFormRequestWithMethod("POST", URLString: url, parameters: nil, constructingBodyWithBlock: { (formData) -> Void in
                //print(data)
                print(data.length)
                formData.appendPartWithFileData(data, name: "imageZip", fileName: "archive.zip", mimeType: "application/zip")
                }, error: nil)
            
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let manager = AFURLSessionManager.init(sessionConfiguration: configuration)
            let uploadTask:NSURLSessionUploadTask = manager.uploadTaskWithStreamedRequest(request, progress: {   uploadProgress -> Void in
                let progress:NSProgress = uploadProgress
                print(progress.fractionCompleted)
                self.updateProgress(progress.fractionCompleted/2.0)
                }, completionHandler: { (response, responseObject, error) -> Void in
                    let resp = response as! NSHTTPURLResponse
                    let code:NSInteger = resp.statusCode
                    self.loader.removeLoader()
                    if code != 201{
                        self.showAlert("Error",message: "\(code)")
                    }else{
                        self.showAlert("Success", message: "The zip file has been uploaded.")
                    }
                    print(resp.statusCode)
                    print(responseObject)
                    
            })
            uploadTask.resume()
        }
        catch let error as NSError{
            print("Error[didTapZip]: \(error.localizedDescription)")
        }
    }
    
    func updateProgress(delta:Double){
        progress = progress + delta
        loader.progress = CGFloat(progress)
    }
    
    func showAlert(title:String, message:String) {
        let alertController = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func githubPath() -> CGPath {
        //Created with PaintCode
        let bezierPath = UIBezierPath()
        bezierPath.moveToPoint(CGPointMake(114.86, 69.09))
        bezierPath.addCurveToPoint(CGPointMake(115.66, 59.2), controlPoint1: CGPointMake(115.31, 66.12), controlPoint2: CGPointMake(115.59, 62.86))
        bezierPath.addCurveToPoint(CGPointMake(107, 35.39), controlPoint1: CGPointMake(115.64, 43.53), controlPoint2: CGPointMake(108.4, 37.99))
        bezierPath.addCurveToPoint(CGPointMake(105.55, 16.26), controlPoint1: CGPointMake(109.05, 23.51), controlPoint2: CGPointMake(106.66, 18.11))
        bezierPath.addCurveToPoint(CGPointMake(85.72, 23.96), controlPoint1: CGPointMake(101.45, 14.75), controlPoint2: CGPointMake(91.27, 20.15))
        bezierPath.addCurveToPoint(CGPointMake(50.32, 24.67), controlPoint1: CGPointMake(76.66, 21.21), controlPoint2: CGPointMake(57.51, 21.48))
        bezierPath.addCurveToPoint(CGPointMake(30.07, 16.34), controlPoint1: CGPointMake(37.07, 14.84), controlPoint2: CGPointMake(30.07, 16.34))
        bezierPath.addCurveToPoint(CGPointMake(28.87, 37.07), controlPoint1: CGPointMake(30.07, 16.34), controlPoint2: CGPointMake(25.54, 24.76))
        bezierPath.addCurveToPoint(CGPointMake(21.26, 57.69), controlPoint1: CGPointMake(24.51, 42.83), controlPoint2: CGPointMake(21.26, 46.9))
        bezierPath.addCurveToPoint(CGPointMake(21.68, 65.07), controlPoint1: CGPointMake(21.26, 60.28), controlPoint2: CGPointMake(21.41, 62.72))
        bezierPath.addCurveToPoint(CGPointMake(56.44, 95.87), controlPoint1: CGPointMake(25.43, 85.52), controlPoint2: CGPointMake(41.07, 94.35))
        bezierPath.addCurveToPoint(CGPointMake(50.97, 105.13), controlPoint1: CGPointMake(54.13, 97.69), controlPoint2: CGPointMake(51.35, 101.13))
        bezierPath.addCurveToPoint(CGPointMake(37.67, 106.24), controlPoint1: CGPointMake(48.06, 107.07), controlPoint2: CGPointMake(42.22, 107.72))
        bezierPath.addCurveToPoint(CGPointMake(19.33, 92.95), controlPoint1: CGPointMake(31.31, 104.15), controlPoint2: CGPointMake(28.87, 91.09))
        bezierPath.addCurveToPoint(CGPointMake(19.47, 95.96), controlPoint1: CGPointMake(17.27, 93.35), controlPoint2: CGPointMake(17.68, 94.76))
        bezierPath.addCurveToPoint(CGPointMake(27.22, 105.53), controlPoint1: CGPointMake(22.37, 97.91), controlPoint2: CGPointMake(25.11, 100.34))
        bezierPath.addCurveToPoint(CGPointMake(43.01, 116.64), controlPoint1: CGPointMake(28.84, 109.52), controlPoint2: CGPointMake(32.24, 116.64))
        bezierPath.addCurveToPoint(CGPointMake(50.28, 116.12), controlPoint1: CGPointMake(47.29, 116.64), controlPoint2: CGPointMake(50.28, 116.12))
        bezierPath.addCurveToPoint(CGPointMake(50.37, 130.24), controlPoint1: CGPointMake(50.28, 116.12), controlPoint2: CGPointMake(50.37, 126.28))
        bezierPath.addCurveToPoint(CGPointMake(44.43, 138.27), controlPoint1: CGPointMake(50.37, 134.8), controlPoint2: CGPointMake(44.43, 136.08))
        bezierPath.addCurveToPoint(CGPointMake(47.97, 139.22), controlPoint1: CGPointMake(44.43, 139.14), controlPoint2: CGPointMake(46.39, 139.22))
        bezierPath.addCurveToPoint(CGPointMake(57.59, 131.79), controlPoint1: CGPointMake(51.09, 139.22), controlPoint2: CGPointMake(57.59, 136.53))
        bezierPath.addCurveToPoint(CGPointMake(57.65, 113.15), controlPoint1: CGPointMake(57.59, 128.02), controlPoint2: CGPointMake(57.65, 115.36))
        bezierPath.addCurveToPoint(CGPointMake(60.15, 106.76), controlPoint1: CGPointMake(57.65, 108.3), controlPoint2: CGPointMake(60.15, 106.76))
        bezierPath.addCurveToPoint(CGPointMake(59.55, 136.08), controlPoint1: CGPointMake(60.15, 106.76), controlPoint2: CGPointMake(60.46, 132.61))
        bezierPath.addCurveToPoint(CGPointMake(56.55, 141.39), controlPoint1: CGPointMake(58.48, 140.16), controlPoint2: CGPointMake(56.55, 139.58))
        bezierPath.addCurveToPoint(CGPointMake(66.95, 136.13), controlPoint1: CGPointMake(56.55, 144.1), controlPoint2: CGPointMake(64.36, 142.05))
        bezierPath.addCurveToPoint(CGPointMake(68.06, 106.15), controlPoint1: CGPointMake(68.96, 131.5), controlPoint2: CGPointMake(68.06, 106.15))
        bezierPath.addLineToPoint(CGPointMake(70.15, 106.1))
        bezierPath.addCurveToPoint(CGPointMake(70.1, 123.02), controlPoint1: CGPointMake(70.15, 106.1), controlPoint2: CGPointMake(70.17, 117.71))
        bezierPath.addCurveToPoint(CGPointMake(72.63, 138.73), controlPoint1: CGPointMake(70.03, 128.51), controlPoint2: CGPointMake(69.48, 135.46))
        bezierPath.addCurveToPoint(CGPointMake(81.03, 141.22), controlPoint1: CGPointMake(74.7, 140.89), controlPoint2: CGPointMake(81.03, 144.67))
        bezierPath.addCurveToPoint(CGPointMake(76.59, 132.13), controlPoint1: CGPointMake(81.03, 139.21), controlPoint2: CGPointMake(76.59, 137.56))
        bezierPath.addLineToPoint(CGPointMake(76.59, 107.12))
        bezierPath.addCurveToPoint(CGPointMake(79.85, 115.34), controlPoint1: CGPointMake(79.29, 107.12), controlPoint2: CGPointMake(79.85, 115.34))
        bezierPath.addLineToPoint(CGPointMake(80.82, 130.61))
        bezierPath.addCurveToPoint(CGPointMake(86.63, 138.51), controlPoint1: CGPointMake(80.82, 130.61), controlPoint2: CGPointMake(80.17, 136.19))
        bezierPath.addCurveToPoint(CGPointMake(94.01, 138.17), controlPoint1: CGPointMake(88.91, 139.34), controlPoint2: CGPointMake(93.78, 139.56))
        bezierPath.addCurveToPoint(CGPointMake(88.08, 130.41), controlPoint1: CGPointMake(94.24, 136.78), controlPoint2: CGPointMake(88.14, 134.73))
        bezierPath.addCurveToPoint(CGPointMake(88.19, 114.82), controlPoint1: CGPointMake(88.05, 127.79), controlPoint2: CGPointMake(88.19, 126.25))
        bezierPath.addCurveToPoint(CGPointMake(81.55, 95.81), controlPoint1: CGPointMake(88.19, 103.4), controlPoint2: CGPointMake(86.71, 99.18))
        bezierPath.addCurveToPoint(CGPointMake(114.86, 69.09), controlPoint1: CGPointMake(96.52, 94.22), controlPoint2: CGPointMake(112.06, 87.3))
        bezierPath.closePath()
        bezierPath.miterLimit = 4;
        return bezierPath.CGPath
    }

}

