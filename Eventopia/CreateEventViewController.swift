//
//  CreateEventViewController.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 4/30/23.
//

import UIKit
import MapKit
import Firebase
import FirebaseStorage

class CreateEventViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
   
    
    

    @IBOutlet weak var eventTitleField: UITextField!
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventDateField: UITextField!
    
    @IBOutlet weak var eventPriceField: UITextField!
    @IBOutlet weak var eventDescriptionTV: UITextView!
    
    @IBOutlet weak var eventLocationTV: UITextField!
    
    @IBOutlet weak var eventDatePicker: UIDatePicker!
    
    @IBOutlet weak var dateDoneButton: UIButton!
    
    @IBOutlet weak var createButton: UIButton!
    
   
    @IBOutlet weak var datePickerBackView: UIView!
    @IBOutlet weak var dateAreaTap: UIView!
    
    @IBOutlet weak var datePickerView: CustomActivityIndicatorView!
    
    let db = Firestore.firestore()
    let userId = Auth.auth().currentUser?.uid
    var docRef: DocumentReference?
    
    var eventDataDelegate: EventDataDelegate!
    
   
    private var searchCompleter: MKLocalSearchCompleter?
    private var searchRegion: MKCoordinateRegion = MKCoordinateRegion(MKMapRect.world)
    private var currentPlacemark: CLPlacemark?
    
    var completerResults: [MKLocalSearchCompletion]?
    var imagePicker = UIImagePickerController()
    var imageData: Data?
    var image = UIImage()
    var imgTapRecognizer: UITapGestureRecognizer!
    var dateTapRecognizer: UITapGestureRecognizer!
    
    
    var allUserEvents = [Event]()
    var event: Event?
    var eventId = ""
    var editEvent = false
    var imageChanged = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        docRef = db.collection("users").document(userId!)
        allUserEvents = CurrentUser.currentUser?.userEvents ?? [Event]()
        eventDataDelegate = FirebaseHelper()
        
        // Set default image.
        image = UIImage(named: "logo_placeholder")!
        
        // Set up gesture recognizers.
        imgTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(setPicture(_:)))
        eventImageView.addGestureRecognizer(imgTapRecognizer)
        
        dateTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(pickDate(_:)))
        dateAreaTap.addGestureRecognizer(dateTapRecognizer)
        



        // Style views.
        eventImageView.layer.cornerRadius = 10
        datePickerBackView.layer.cornerRadius = 10
       
        eventDescriptionTV.layer.cornerRadius = 6
        eventDescriptionTV.layer.borderWidth = 2
        eventDescriptionTV.layer.borderColor = UIColor(red: 194/255, green: 231/255, blue: 250/255, alpha: 1).cgColor
                
        // Populate fields if an event is being edited.
        if event != nil {
            editEvent = true
            eventId = event!.id
            populateFields()
        }
    }
    
    
    @objc func pickDate(_ sender: UIView) {
        datePickerView.activityIndicator.isHidden = true
        datePickerView.statusLbl.isHidden = true
        datePickerView.isHidden = false
    }
    
    @objc func setPicture(_ sender: UIImageView) {
        let getPermissionsDelegate: GetPhotoCameraPermissionsDelegate! = GetImageHelper()
        let actionSheet = UIAlertController(title: "Photo Source", message: "Choose a Source", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action:UIAlertAction) in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                Task.init {
                    if await getPermissionsDelegate.getPhotosPermissions() {
                        let imagePicker = UIImagePickerController()
                        
                        imagePicker.delegate = self
                        imagePicker.sourceType = .photoLibrary
                        imagePicker.allowsEditing = false
                        
                        self.present(imagePicker, animated: true, completion: nil)
                    }
                }
            } else {
                // Create alert.
                let alert = UIAlertController(title: "No Library", message: "Photo library is not available on this device.", preferredStyle: .alert)
                // Add action to alert controller.
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // Show alert.
                self.present(alert, animated: true, completion: nil)
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action:UIAlertAction) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Task.init {
                    if await getPermissionsDelegate.getCameraPermissions() {
                        let imagePicker = UIImagePickerController()
                        
                        imagePicker.delegate = self
                        imagePicker.sourceType = .camera
                        
                        self.present(imagePicker, animated: true)
                    }
                }
            } else {
                // Create alert.
                let alert = UIAlertController(title: "No Camera", message: "Camera is not available on this device.", preferredStyle: .alert)
                // Add action to alert controller.
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // Show alert.
                self.present(alert, animated: true, completion: nil)
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    @IBAction func datePickingDone(_ sender: Any) {
        let formatter = DateFormatter()
        
        formatter.calendar = eventDatePicker.calendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        var dateString = formatter.string(from: eventDatePicker.date)
        dateString = dateString.replacingOccurrences(of: ",", with: "")
        dateString = dateString.replacingOccurrences(of: "at", with: "|")
        
        eventDateField.text = dateString
        datePickerView.isHidden = true
    }
    

    
    
    @IBAction func createEventTapped(_ sender: Any) {
        
        // Create alert to be displayed if proper conditions are not met.
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        // Add action to alert controller.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Ensure required fields are not empty.
        guard let eventTitle = eventTitleField.text, !eventTitle.isEmpty,
              let eventDate = eventDateField.text, !eventDate.isEmpty,
              let eventPrice = eventPriceField.text, !eventPrice.isEmpty,
              let eventLocation = eventLocationTV.text, !eventLocation.isEmpty,
              let eventDescription = eventDescriptionTV.text, !eventDescription.isEmpty
        else {
            alert.title = "Missing Info"
            alert.message = "All fields must be completed to continue."
            
            // Show alert.
            self.present(alert, animated: true, completion: nil)
            
            return
        }
                
        if editEvent {
            // Ensure data has been changed.
            let price = event?.tickets[0]["source"] as? String
            
            if eventImageView.image == event?.image && eventTitle == event?.title && eventDate == event?.date && eventPrice == price && eventLocation == event?.address && eventDescription == event?.description {
                // Set alert title and message.
                alert.title = "Unchanged Data"
                alert.message = "The information that you are trying to submit is unchanged and cannot be updated. Please verify that you have entered new information and try again."
                
                // Show alert.
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            
            datePickerView.statusLbl.text = "Updating your event..."
        }
        
        datePickerView.activityIndicator.isHidden = false
        datePickerView.statusLbl.isHidden = false
        datePickerView.isHidden = true
        datePickerBackView.isHidden = true
        dateDoneButton.isHidden = true
        datePickerView.activityIndicator.startAnimating()
        datePickerView.isHidden = false
        
        var eventTickets = [[String: Any]]()
        eventTickets.append(["source" : eventPrice])
                
        let data: [String: Any] = ["thumbnail": event?.imageUrl ?? "", "title": eventTitle, "date": eventDate, "tickets": eventTickets, "address": eventLocation, "link": "", "description": eventDescription]
        
        // Create new event and make it the current event.
        self.event = Event(id: self.event?.id ?? "", title: eventTitle, date: eventDate, address: eventLocation, link: "", description: eventDescription, tickets: eventTickets, imageUrl: self.event?.imageUrl ?? "", image: self.image, status: "attending", isFavorite: self.event?.isFavorite ?? false, isCreated: self.event?.isCreated ?? true)
        
        if !self.editEvent {
            // Add event to Firebase "events" collection.
            var ref: DocumentReference?
            
            ref = db.collection("events").addDocument(data: data) { (error) in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                } else {
                    if let docId = ref?.documentID {
                        self.saveEventToFirebase(eventId: docId)
                    }
                }
            }
        } else {
            self.updateFirebaseEvent(data: data)
        }
        
        
    }
    private func populateFields() {
        eventImageView.image = event?.image
        eventTitleField.text = event?.title
        eventDateField.text = event?.date
        
        if let price = event?.tickets[0]["source"] as? String {
            eventPriceField.text = price
        }

        eventLocationTV.text = event?.address
        eventDescriptionTV.text = event?.description
        eventDescriptionTV.textColor = .label
        
        // Change createButton text.
        createButton.setTitle("Save Changes", for: .normal)
    }
    
    
    private func saveImageToFirebase() {
        // Save event image to Firebase Storage.
        let storageRef = Storage.storage().reference().child("events").child(eventId).child("thumbnail.png")
        let metaData = StorageMetadata()
        
        metaData.contentType = "image/png"
        
        if self.imageData == nil {
            self.imageData = self.image.pngData()
        }
        
        storageRef.putData(self.imageData!, metadata: metaData) { (metaData, error) in
            if error == nil, metaData != nil {
                storageRef.downloadURL { url, error in
                    if let url = url {
                        // Update created event in Firebase with url string.
                        self.db.collection("events").document(self.eventId).updateData(["thumbnail": url.absoluteString]) { err in
                            if let err = err {
                                print("Error adding image: \(err)")
                            } else {
                                // Update event in user's current events.
                                CurrentUser.currentUser?.userEvents?.first(where: { $0.id == self.eventId })?.image = self.image
                                CurrentUser.currentUser?.userEvents?.first(where: { $0.id == self.eventId })?.imageUrl = url.absoluteString
                                
                                print("Image successfully added")
                            }
                        }
                    }
                }
            } else {
                // Print error if upload fails.
                print(error?.localizedDescription ?? "There was an issue uploading photo.")
            }
        }
    }
    
    private func updateFirebaseEvent(data: [String: Any]) {
        // Find document in Firebase and update favorite field.
        db.collection("events").document(eventId).updateData(data) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                // Update current user's events.
                if let index = self.allUserEvents.firstIndex(where: { $0.id == self.eventId }) {
                    if self.imageChanged {
                        self.event?.image = self.eventImageView.image!
                        self.event?.imageUrl = ""
                        self.saveImageToFirebase()
                    }
                    
                    self.allUserEvents[index] = self.event!
                    
                    CurrentUser.currentUser?.userEvents = self.allUserEvents
                    
                    print("Document successfully updated")
                    
                    self.showSuccessAlert()
                }
            }
        }
    }
    
    private func saveEventToFirebase(eventId: String) {
        self.eventDataDelegate.addUserEvent(uId: self.userId!, eventId: eventId, isCreated: true) { result in
            if result == true {
                // Create new group in Firebase and update user's event.
                self.event?.id = eventId
                
                self.eventId = eventId
                
                self.allUserEvents.append(self.event!)
                CurrentUser.currentUser?.userEvents = self.allUserEvents
                
                self.showSuccessAlert()
                self.saveImageToFirebase()
                
                
            }
        }
    }
    
    private func createHighlightedString(text: String, rangeValues: [NSValue]) -> NSAttributedString {
        let attributes = [NSAttributedString.Key.backgroundColor: UIColor.white.cgColor ]
        let highlightedString = NSMutableAttributedString(string: text)
        
        // Each `NSValue` wraps an `NSRange` that can be used as a style attribute's range with `NSAttributedString`.
        let ranges = rangeValues.map { $0.rangeValue }
        
        ranges.forEach { (range) in
            highlightedString.addAttributes(attributes, range: range)
        }
        
        return highlightedString
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let img = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // Resize image
            let targetSize = CGSize(width: 100, height: 100)
            let scaledImg = img.scalePreservingAspectRatio(targetSize: targetSize)
            
            imageData = scaledImg.pngData()
            eventImageView.image = img
            imageChanged = true
            self.image = img
        }
    }
    
    private func showSuccessAlert() {
        let action = editEvent ? "updated" : "created"
        
        // Create alert to notify user of successful update.
        let successAlert = UIAlertController(title: "Success", message: "Your event has been successfully \(action).", preferredStyle: .alert)
        
        // Add action to successAlert controller.
        successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.datePickerView.isHidden = true
            self.datePickerView.activityIndicator.stopAnimating()
            self.datePickerView.activityIndicator.isHidden = true
            self.datePickerView.statusLbl.isHidden = true
            self.eventDatePicker.isHidden = false
            self.eventDatePicker.isHidden = false
            self.dateDoneButton.isHidden = false
            self.dismiss(animated: true, completion: nil)
        }))
        
        // Show alert.
        self.present(successAlert, animated: true, completion: nil)
    }
    
    
    
    // MARK: - Table View
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return completerResults?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "table_cell_3", for: indexPath)
        
        if let suggestion = completerResults?[indexPath.row] {
            // Each suggestion is a MKLocalSearchCompletion with a title, subtitle, and ranges describing what part of the title
            // and subtitle matched the current query string. The ranges can be used to apply helpful highlighting of the text in
            // the completion suggestion that matches the current query fragment.
            cell.textLabel?.attributedText = createHighlightedString(text: suggestion.title, rangeValues: suggestion.titleHighlightRanges)
            cell.detailTextLabel?.attributedText = createHighlightedString(text: suggestion.subtitle, rangeValues: suggestion.subtitleHighlightRanges)
        }
        
        return cell
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
