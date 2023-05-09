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
    
    @IBOutlet weak var changePassword: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if CurrentUser.currentUser != nil {
            displayUserData()
        }
        
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.clickAction(sender:)))
        self.changePassword.addGestureRecognizer(gesture)
    }
    
    @objc func clickAction(sender : UITapGestureRecognizer) {
        
        let alert = UIAlertController(title: "Change Password", message: "Enter the email address associated with your account. If found, an email will be sent with instructions on how to reset your password.", preferredStyle: .alert)
        // Add text field to alert controller.
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
        })
        
        // Add actions to alert controller.
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        let submitAction = UIAlertAction(title: "Submit", style: .default, handler: { action in
            guard let email = alert.textFields?.first?.text else { return }
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if error != nil {
                    print("There was an error")
                } else {
                    print("Reset instructions sent")
                }
            }
        })
        
        submitAction.isEnabled = false
        
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: alert.textFields?.first, queue: .main) { (notification) -> Void in
            guard let inputStr = alert.textFields?.first?.text else { return }
            submitAction.isEnabled =
            Utilities.isValidEmail(email: inputStr) && !inputStr.isEmpty
        }
        
        alert.addAction(submitAction)
        
        // Show alert.
        self.present(alert, animated: true, completion: nil)
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
