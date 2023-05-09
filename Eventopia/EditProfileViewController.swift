//
//  EditProfileViewController.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 5/7/23.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage

class EditProfileViewController: UIViewController {

    @IBOutlet weak var profilePicView: UIImageView!
    @IBOutlet weak var firstNameTF: UITextField!
    @IBOutlet weak var lastNameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIBarButtonItem!
    
    @IBOutlet weak var activityIndView: UIActivityIndicatorView!
    
    
   
    var imagePresent: Data?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if CurrentUser.currentUser != nil {
            profilePicView.image = CurrentUser.currentUser?.profilePic
            firstNameTF.text = CurrentUser.currentUser?.firstName
            lastNameTF.text = CurrentUser.currentUser?.lastName
            emailTF.text = CurrentUser.currentUser?.email
        }
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        profilePicView.addGestureRecognizer(gesture)
    }
    
    @objc private func didTapChangeProfilePic(){
        
        presentPhotoActionSheet()
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func passwordEntered(_ sender: UITextField) {
        saveBtn.isEnabled = passwordTF.hasText
    }
    
    @IBAction func saveBtnTapped(_ sender: UIButton) {
        // Create alert to be displayed if proper conditions are not met.
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        // Add action to alert controller.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Ensure required fields are not empty.
        guard let firstName = firstNameTF.text, !firstName.isEmpty,
              let lastName = lastNameTF.text, !lastName.isEmpty,
              let email = emailTF.text, !email.isEmpty
        else {
            // Set alert title and message.
            alert.title = "Missing Info"
            alert.message = "All fields must be filled to continue."
            
            // Show alert.
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        // Validate email.
        if !email.contains("@") {
            // Set alert title and message.
            alert.title = "Invalid Email"
            alert.message = "Please enter a valid email address and try again."
            
            // Show alert.
            self.present(alert, animated: true, completion: nil)
        }
        
        
        // Ensure data has been changed.
        if  firstName == CurrentUser.currentUser?.firstName && lastName == CurrentUser.currentUser?.lastName && email == CurrentUser.currentUser?.email {
            // Set alert title and message.
            alert.title = "Unchanged Data"
            alert.message = "The information that you are trying to submit is unchanged and cannot be updated. Please verify that you have entered new information and try again."
            
            // Show alert.
            self.present(alert, animated: true, completion: nil)
            
            self.activityIndView.isHidden = true
            self.activityIndView.stopAnimating()
            
            return
        }
        
        self.activityIndView.startAnimating()
        self.activityIndView.isHidden = false
        
        // Reauthenticate user.
        let credential = EmailAuthProvider.credential(withEmail: CurrentUser.currentUser!.email, password: passwordTF.text!)
        
        Auth.auth().currentUser?.reauthenticate(with: credential, completion: { (result, error) in
            // Ensure there are no errors while reauthenticating.
            guard error == nil
            // Action if error occurs.
            else {
                // Set alert title and message.
                alert.title = "Verification Failed"
                alert.message = "There was an issue verifying your credentials. Please re-enter your password and try again."
                
                // Show alert.
                self.present(alert, animated: true, completion: nil)
                
                self.activityIndView.isHidden = true
                self.activityIndView.stopAnimating()
                
                return
            }
            
            Auth.auth().currentUser?.updateEmail(to: email) { error in
                // Ensure there are no errors while updating user email.
                guard error == nil
                // Action if error occurs.
                else {
                    // Set alert title and message.
                    alert.title = "Email Update Failed"
                    alert.message = "There was an issue updating your email address. Please try again."
                    
                    // Show alert.
                    self.present(alert, animated: true, completion: nil)
                    
                    self.activityIndView.isHidden = true
                    self.activityIndView.stopAnimating()
                    
                    return
                }
                
                // Update user document in Firebase.
                let db = Firestore.firestore()
                let docId = Auth.auth().currentUser?.uid
                
                db.collection("users").document(docId!).updateData(["firstName": firstName, "lastName": lastName, "email": email]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("Document successfully updated")
                        
                        // Create alert to notify user of successful update.
                        let successAlert = UIAlertController(title: "Success", message: "Account information successfully updated.", preferredStyle: .alert)
                        
                        // Add action to successAlert controller.
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                            self.activityIndView.isHidden = true
                            self.activityIndView.stopAnimating()
                            self.dismiss(animated: true, completion: nil)
                        }))
                        
                        // Save user profile picture.
                        if self.imagePresent != nil {
                            let storageRef = Storage.storage().reference().child("users").child(docId!).child("profile.png")
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
                                                    // Update current user photo.
                                                    CurrentUser.currentUser?.profilePic = self.profilePicView.image
                                                    
                                                    // Show successAlert.
                                                    self.present(successAlert, animated: true, completion: nil)
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
                        } else {
                            // Show successAlert if photo has not been changed.
                            self.present(successAlert, animated: true, completion: nil)
                        }
                        
                        // Update current user information.
                        CurrentUser.currentUser?.firstName = firstName
                        CurrentUser.currentUser?.lastName = lastName
                        CurrentUser.currentUser?.email = email
                    }
                }
            }
        })
        
    }
    
    


}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func presentPhotoActionSheet(){
        
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] _ in self?.presentCamera()}))
        
        actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: {[weak self] _ in self?.presentPhotoPicker()}))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera(){
        let vc = UIImagePickerController()
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            let alertController = UIAlertController(title: nil, message: "Device has no camera.", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Alright", style: .default, handler: { (alert: UIAlertAction!) in
            })
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        } else {
            // Other action
            
            vc.sourceType = .camera
            vc.delegate = self
            vc.allowsEditing = true
            present(vc, animated: true)
        }
        
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

        self.profilePicView.image = selectedImage
        
    }
}
