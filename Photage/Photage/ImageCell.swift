//
//  ImageCell.swift
//  Photage
//
//  Created by Kelvin Lin on 4/30/16.
//  Copyright © 2016 Lins. All rights reserved.
//

import UIKit
import SDWebImage

class ImageCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    
    func load(url:NSURL){
//        imageView.image = UIImage.init(named: "user-default")
        imageView.sd_setImageWithURL(url) { (image, error, type, url) in
            User.instance.images.append(image)
        }
    }
}
