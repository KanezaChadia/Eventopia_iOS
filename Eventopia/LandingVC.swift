//
//  ViewController.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 4/25/23.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUoButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let isLoggedIn = UserDefaults.standard.bool(forKey: "usersignedin")
        
        if isLoggedIn {
            
            let homeTabBarController = self.storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeTabBarController) as? HomeTabBarController
      
            
            self.view.window?.rootViewController = homeTabBarController
            self.view.window?.makeKeyAndVisible()
        }
    
    }


}

