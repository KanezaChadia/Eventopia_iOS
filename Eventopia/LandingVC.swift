//
//  ViewController.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 4/25/23.
//

import UIKit
import Firebase
import FirebaseAuth

class ViewController: UIViewController {
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUoButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var userDataDelegate: UserDataDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        signInButton.isHidden = true
        signUoButton.isHidden = true
        
        if Auth.auth().currentUser != nil {
            activityIndicator.startAnimating()
            
            userDataDelegate = FirebaseHelper()
            
            Task.init {
                do {
                    try await userDataDelegate.getCriticalData()
                } catch {
                    // .. handle error
                    print("There was an error getting critical user data.")
                }
                
                do {
                    try await userDataDelegate.getBackgroundData()
                } catch {
                    // .. handle error
                    print("There was an error getting background user data.")
                }
                // Show HomeViewController.
                
                let homeTabBarController = self.storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeTabBarController) as? HomeTabBarController
          
                
                self.view.window?.rootViewController = homeTabBarController
                self.view.window?.makeKeyAndVisible()
               
        }
        
        } else {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            
            signInButton.isHidden = false
            signUoButton.isHidden = false
            
        }
        
}
    
    
    // MARK: - Navigation

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }


}

