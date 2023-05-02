//
//  CustomImageView.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 5/1/23.
//

import UIKit

class CustomImageView: UIImageView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.layer.cornerRadius = self.layer.bounds.height / 2
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor(red: 224/255, green: 210/255, blue: 104/255, alpha: 1).cgColor
    }

}
