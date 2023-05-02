//
//  ProfileViewController.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 5/1/23.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {

    @IBOutlet weak var userPictureView: CustomImageView!
    @IBOutlet weak var fullNameLbl: UILabel!
    @IBOutlet weak var emailLbl: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if CurrentUser.currentUser != nil {
            displayUserData()
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        // Update data to display if it has been changed.
        if let currentUser = CurrentUser.currentUser {
            if currentUser.profilePic != userPictureView.image || currentUser.fullName != fullNameLbl.text || currentUser.email != emailLbl.text {
                displayUserData()
            }
        }
    }
    
    @IBAction func signOutBtnTapped(_ sender: UIButton) {
        // Create alert.
        let alert = UIAlertController(title: "Sign Out?", message: "Are you sure you want to sign out?", preferredStyle: .alert)
        
        // Add actions to alert controller.
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive, handler: { action in
            // Sign user out of Firebase.
            do {
              try Auth.auth().signOut()
            } catch let signOutError as NSError {
              print("Error signing out: %@", signOutError)
            }

            // Ensure user is signed out.
            if FirebaseAuth.Auth.auth().currentUser == nil {
                CurrentUser.currentUser = nil
                CurrentLocation.location = nil
                CurrentLocation.preferredLocation = nil
                // Dismiss entire tabController and return to SignInViewController.
                self.dismiss(animated: true, completion: nil)
                self.transitionToLanding()
            }
        }))
        
        // Show alert.
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func displayUserData() {
        userPictureView.image = CurrentUser.currentUser?.profilePic
        fullNameLbl.text = CurrentUser.currentUser?.fullName
        emailLbl.text = CurrentUser.currentUser?.email
    }
    
    
     //MARK: Navigation
     
     func transitionToLanding() {
         
         let landingViewController = storyboard?.instantiateViewController(identifier: Constants.Storyboard.landingViewController) as? ViewController
         
         view.window?.rootViewController = landingViewController
         view.window?.makeKeyAndVisible()
         
     }

}
