//
//  LargeImageViewController.swift
//  GithubUsers
//
//  Created by Alex on 27.09.16.
//  Copyright © 2016 Alex. All rights reserved.
//

import UIKit

class LargeImageViewController: UIViewController {

    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    var image: UIImage?
    var name: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logoImage.image = image
        nameLabel.text = name
    }

}
