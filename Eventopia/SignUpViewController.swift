//
//  SignUpViewController.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 4/26/23.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class SignUpViewController: UIViewController {

    @IBOutlet weak var firstNameTF: UITextField!
    @IBOutlet weak var lastNameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var password2TF: UITextField!
    @IBOutlet weak var errorLbl: UILabel!
    
    @IBOutlet weak var signUpBtn: UIButton!
    
    @IBOutlet weak var picIV: UIImageView!
    var imagePresent: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUpElements()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        picIV.addGestureRecognizer(gesture)
    }
    
    
    
    // MARK: Function
    
    @objc private func didTapChangeProfilePic(){
        
        presentPhotoActionSheet()
    }
    
    func setUpElements(){
        
        // Hide the error label
        
        errorLbl.alpha = 0
        
        //style the elements
       
        Utilities.styleFilledButton(signUpBtn)
        
    
    }
    
    
    
    func validateFields() -> String? {
        
        // check that all fields are filled in
        if firstNameTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            lastNameTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            emailTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            passwordTF.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            password2TF.text?.trimmingCharacters(in: .whitespacesAndNewlines) == ""{
            
            return "Please fill in all fields."
        }
        
        // Check if the password is secure
        let cleanedPassword = passwordTF.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if  Utilities.isPasswordValid(cleanedPassword) == false {
            // Password isn't secure enough
            
            return "Please make sure your password is at least 8 characters, contains a special character and a number."
        }
       
        return nil
    }
    
    func showError(_ message:String){
        
        errorLbl.text = message
        errorLbl.alpha = 1
    }
    
    @IBAction func signUpTapped(_ sender: Any) {
        
        
        // Ensure required fields are not empty.
        guard let fName = firstNameTF.text, !fName.isEmpty,
              let lName = lastNameTF.text, !lName.isEmpty,
              let email = emailTF.text,!email.isEmpty,
              let password = passwordTF.text, !password.isEmpty,
              let password2 = password2TF.text, !password2.isEmpty
        else {
            // Set show error.
            
            showError("All fields must be completed to continue.")
    
            
            return
        }
        
        // Validate email.
        if !Utilities.isValidEmail(email: email) {
            // Show error.
            showError("The email that you have entered is invalid. Please enter a valid email address and try again.")
   
        }
        
        // Validate passwords.
        if password.count < 6 || password.count > 10 || password != password2 {
            // Show error.
            showError("Password must be between 6 and 1 characters and passwords must match. Please enter a valid password and try again.")
          
         
            return
        }
        
        // Ensure profile picture is selected.
        if self.imagePresent == nil {
            // Show error.
            showError("Select a profile picture to continue. Please try again.")

            return
        }
        let addDate = Date()
        
        // Create new user account in Firebase.
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            // Ensure there are no errors during account creation.
            guard error == nil
            // Action if error occurs.
            else {
                // Show error.
                self.showError("Account creation failed. Please try again.")
                
                self.navigationItem.setHidesBackButton(false, animated: true)
                return
            }
            
            // Add user to user collection in Firebase.
            let db = Firestore.firestore()
            let documentId = Auth.auth().currentUser?.uid
            let data: [String: Any] = ["firstName": fName, "lastName": lName, "email": email, "addDate": addDate, "isInvited": false, "recentSearches": [String]()]
            
            db.collection("users").document(documentId!).setData(data) {(error) in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }else{
                    // Save user profile picture.
                    let storageRef = Storage.storage().reference().child("users").child(documentId!).child("profile.png")
                    let metaData = StorageMetadata()
                    
                    metaData.contentType = "image/png"
                    storageRef.putData(self.imagePresent!, metadata: metaData) { (metaData, error) in
                        if error == nil, metaData != nil {
                            storageRef.downloadURL { url, error in
                                if let url = url {
                                    // Update Firebase authentication profile picture.
                                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                                    
                                    changeRequest?.photoURL = url
                                    changeRequest?.commitChanges(completion: { error in
                                        if error == nil {
                                            // Set current user.
                                            let user = User(profilePic: self.picIV.image, firstName: fName, lastName: lName, email: email, addDate: addDate)
                                            
                                            CurrentUser.currentUser = user
                                            
                                            print("Your account has been created.")
                                            
                                            
                                            //Transition to the home screen
                                            self.transitionToHome()
                                            
                                        } else {
                                            // Print error if update fails.
                                            print(error!.localizedDescription)
                                        }
                                    })
                                }
                            }
                        } else {
                            // Print error if upload fails.
                            print(error?.localizedDescription ?? "There was an issue uploading photo.")
                        }
                    }
                }
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


extension SignUpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func presentPhotoActionSheet(){
        
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] _ in self?.presentCamera()}))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: {[weak self] _ in self?.presentPhotoPicker()}))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        
        imagePresent = selectedImage.pngData()

        self.picIV.image = selectedImage
        
    }
}

