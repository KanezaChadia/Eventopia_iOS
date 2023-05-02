//
//  CustomActivityIndicatorView.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 4/30/23.
//

import UIKit

class CustomActivityIndicatorView: UIView {

   
        @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
        @IBOutlet weak var statusLbl: UILabel!
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder:aDecoder)
            
            // Create a blur effect to be applied to view when gameOverView is displayed.
            let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.systemUltraThinMaterial)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = self.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            self.insertSubview(blurEffectView, at: 0)
        }

}
