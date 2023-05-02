//
//  LogInViewController.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 4/27/23.
//

import UIKit
import Firebase
import FirebaseAuth

class LogInViewController: UIViewController {

    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var passwordRecoveryBtn: UIButton!
    @IBOutlet weak var errorTF: UILabel!
    
    
    var userDataDelegate: UserDataDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setUpElements()
    }
    
    func setUpElements(){
        
        // Hide the error label
        
        errorTF.alpha = 0
        
        //style the elements
       
        Utilities.styleFilledButton(loginBtn)
        
    
    }
    
    func showError(_ message:String){
        
        errorTF.text = message
        errorTF.alpha = 1
    }

    
    
    @IBAction func logginTapped(_ sender: Any) {
        
        // Ensure required fields are not empty.
        guard let email = emailTF.text, !email.isEmpty, Utilities.isValidEmail(email: email),
              let password = passwordTF.text, !password.isEmpty
        else {
            // Set error message.
            
            showError("All fields must be completed to continue.")
            return
        }
        
        // Use Firebase to authenticate user
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {result, error in
            // Ensure there are no errors while signing in.
            guard error == nil
            // Action if error occurs.
            else {
                // Set error message.
                self.showError("The email or password that you entered is incorrect. Please enter the correct email and password and try again.")
                return
            }
            
            print("You have been signed in.")
            self.getUserData()
            
            UserDefaults.standard.set(true, forKey: "usersignedin")
            UserDefaults.standard.set(email, forKey: "email")
            
            self.transitionToHome()

            
        })
        
        
    }
    
    @IBAction func forgotPasswordTapped(_ sender: Any) {
        
        let alert = UIAlertController(title: "Reset Password", message: "Enter the email address associated with your account. Iffound, an email will be sent with instructions on how to reset your password.", preferredStyle: .alert)
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
    
    func getUserData() {
        userDataDelegate = FirebaseHelper()
        
        Task.init {
            do {
                try await userDataDelegate.getCriticalData()
            } catch {
                // .. handle error
                print("There was an error getting critical user data.")
            }
            

            // Show HomeViewController.
            self.transitionToHome()
            
            do {
                try await userDataDelegate.getBackgroundData()
            } catch {
                // .. handle error
                print("There was an error getting background user data.")
            }
        }
    }
    
    
    
    //MARK: Navigation
    
    func transitionToHome() {
        
        let homeTabBarController = storyboard?.instantiateViewController(identifier: Constants.Storyboard.homeTabBarController) as? HomeTabBarController
        
        view.window?.rootViewController = homeTabBarController
        view.window?.makeKeyAndVisible()
        
    }

}
