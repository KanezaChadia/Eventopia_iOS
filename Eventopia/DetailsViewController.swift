//
//  DetailsViewController.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 4/30/23.
//

import UIKit
import MapKit
import Firebase
import LinkPresentation
import Kingfisher

class DetailsViewController: UIViewController, UILabelClickableLinksDelegate {
    
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventEditBtn: UIButton!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var eventDateLbl: UILabel!
    
    @IBOutlet weak var eventTicketsLbl: UILblClickableLinks!
    
    @IBOutlet weak var eventAddressLbl: UILabel!
    
    @IBOutlet weak var eventmapView: MKMapView!
    @IBOutlet weak var eventDescriptionLbl: UILabel!
    @IBOutlet weak var addEventBtn: UIButton!
    @IBOutlet weak var removeEventBtn: UIButton!
    
    @IBOutlet var buttonsView: UIView!
    @IBOutlet weak var favoriteBtn: UIButton!
 
    @IBOutlet weak var doneBtn: UIButton!
    
    
    let db = Firestore.firestore()
    let userId = Auth.auth().currentUser?.uid
    var docRef: DocumentReference?
    
    var event: Event?
    var eventId = ""
    var eventImgURL = ""
    var eventTitle = ""
    var eventDate = ""
    var eventAddress = ""
    var eventLink = ""
    var eventTickets = [[String: Any]]()
    var eventDescription = ""
    
    var eventOrganizerId = ""
    var eventStatus = ""
    
    
    var isFav = Bool()
    var isCreated = Bool()
    var metadata: LPLinkMetadata?
    
    var shouldEdit = false
    var editEvent: (() -> Void)?

    var eventDataDelegate: EventDataDelegate!
    override func viewDidLoad() {
        super.viewDidLoad()

        docRef = db.collection("users").document(userId!)
        eventDataDelegate = FirebaseHelper()
        
        populateFields()
        configureMapView()
        
        doneBtn.layer.cornerRadius = 10
        doneBtn.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        
        
        let buttonView = buttonsView
        
        view.addSubview(buttonView!)
        
        NSLayoutConstraint.activate([
            buttonView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonView!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonView!.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        if event?.status == "attending" {
            // Update visible buttons.
            eventEditBtn.isHidden = !isCreated
            addEventBtn.isHidden = true
            removeEventBtn.isHidden = false
        }
        
        favoriteBtn.isSelected = isFav
        favoriteBtn.tintColor = favoriteBtn.isSelected ? UIColor(red: 224/255, green: 210/255, blue: 104/255, alpha: 1) : .systemGray
        
        
    }
    @IBAction func doneButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        
        if event != nil && docRef != nil {
            
            if self.isFav {
                // If an event has just been added as a favorite, it will not have an id.
                // Check if the event's id property is empty and attempt to get it if it exists in user's userEvents array.
                if self.eventId.isEmpty {
                    if let eId = CurrentUser.currentUser?.userEvents?.first(where: { $0.title == self.eventTitle && $0.link == self.eventLink})?.id {
                        self.eventId = eId
                    } else {
                        print("Event cannot be added at this time")
                        buttonsView.isHidden = true
                        return
                    }
                }
                
       
            } else{
                // Check if event already exists in Firebase "events" collection.
                let collRef = db.collection("events")
                
                collRef.whereField("title", isEqualTo: eventTitle).whereField("link", isEqualTo: eventLink).getDocuments { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                        self.buttonsView.isHidden = true
                    } else {
                        // If event already exists, just add a reference to it to the user's "events" collection.
                        if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                            let docId = querySnapshot.documents[0].documentID
                            
                            self.saveEventToFirebase(eventId: docId)
                        } else {
                            // Add event to Firebase "events" collection.
                            let data: [String: Any] = ["thumbnail": self.eventImgURL, "title": self.eventTitle, "date": self.eventDate, "tickets": self.eventTickets, "address": self.eventAddress, "link": self.eventLink, "description": self.eventDescription]
                            
                            var ref: DocumentReference?
                            
                            ref = collRef.addDocument(data: data) { (error) in
                                if let error = error {
                                    print("Error: \(error.localizedDescription)")
                                    self.buttonsView.isHidden = true
                                } else {
                                    if let docId = ref?.documentID {
                                        self.saveEventToFirebase(eventId: docId)
                                    }
                                    self.addEventBtn.isHidden = true
                                    self.removeEventBtn.isHidden = false
                                }
                            }
                        }
                    }
                }
            }
            
        }
        
    }
    
    
    @IBAction func removeEventTapped(_ sender: Any) {
        
        // Create alert.
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        
        if isCreated {
            alert.title = "Delete Event"
            alert.message = "Are you sure that you want to change your plans? Since you created this event, doing so will delete this event along with all associated media and this action cannot be undone."
        } else {
            alert.title = "Change plans?"
            alert.message = "Are you sure that you want to change your plans? Any saved memories will be deleted and this cannot be undone."
        }
        
        // Add actions to alert controller.
        alert.addAction(UIAlertAction(title: "Keep", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { action in
            self.buttonsView.isHidden = false
                        
            if self.isCreated || !self.isFav {
                self.deleteFirebaseEvent()
            } else if self.isFav {
                self.notGoingToFavoritedEvent(disableButtonView: self.removeEventBtn)
            }
        }))
        
        // Show alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    
    private func saveEventToFirebase(eventId: String) {
        self.eventDataDelegate.addUserEvent(uId: self.userId!, eventId: eventId, isCreated: false) { result in
            if result == true {
                print("Event Was saved!")
            }
        }
    }
    
    private func deleteFirebaseEvent() {
        self.eventDataDelegate.deleteFirebaseEvent(event: self.event!) { result in
            if result == false {
                print("There was an issue deleting this event.")
            } else {
                if self.isCreated {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    // Update displayed event.
                    self.event?.id = ""
                    self.event?.status = ""
                    
                    self.updateVisibleButtons(going: false)
                }
            }
        }
    }
    
    
    private func updateVisibleButtons(going: Bool) {
        if going {
            // Update visible buttons.
            addEventBtn.isHidden = true
            removeEventBtn.isHidden = false
            
          
        } else {
            // Update visible buttons.
            addEventBtn.isHidden = false
          
        }
        
    }
    
    
    private func notGoingToFavoritedEvent(disableButtonView: UIView) {
        // Find document in Firebase and update status field.
        self.docRef!.collection("events").document(self.eventId).updateData(["status": ""]) { err in
            if let err = err {
                print("Error updating document: \(err)")
                disableButtonView.isHidden = true
                return
            } else {
                // Update event properties and update current user's events to match.
                if let index = CurrentUser.currentUser?.userEvents?.firstIndex(where: { $0.id == self.eventId }) {
                    // Update displayed event.
                    self.event?.status = ""
                    
                    CurrentUser.currentUser?.userEvents?[index] = self.event!
            
                    
                    self.updateVisibleButtons(going: false)

                    
                    print("Document successfully updated")
                }
            }
        }
    }
    
    private func populateFields() {
        if event != nil {
            eventId = event!.id
            eventImgURL = event!.imageUrl
            eventTitle = event!.title
            eventDate = event!.date
            eventAddress = event!.address
            eventLink = event!.link
            eventTickets = event!.tickets
            eventDescription = event!.description
            eventStatus = event!.status
            isFav = event!.isFavorite
            isCreated = event!.isCreated
            
            // Populate fields.
            eventImageView.image = event?.image
            eventTitleLbl.text = eventTitle
            eventDateLbl.text = eventDate
            eventTicketsLbl.text = "No ticket info provided"
            eventAddressLbl.text = eventAddress
            eventDescriptionLbl.text = eventDescription

            // Create links to tickets.
            let attStr = NSMutableAttributedString(string: "")
            
            if !isCreated && !eventTickets.isEmpty {
                for i in 0...eventTickets.count - 1 {
                    if let source = eventTickets[i]["source"] as? String, let link = eventTickets[i]["link"] as? String {
                        let attLink = NSMutableAttributedString(string: i < eventTickets.count - 1 ? "\(source)\n" : source)
                        let range = NSMakeRange(attStr.length, source.count)
                        
                        attStr.append(attLink)
                        
                        let linkCustomAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1),
                                                    NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
                                                    NSAttributedString.Key.attachment: URL(string: link)!] as [NSAttributedString.Key : Any]
                        
                        attStr.addAttributes(linkCustomAttributes, range: range)
                    }
                }
                
                eventTicketsLbl.attributedText = attStr
                eventTicketsLbl.delegate = self
            } else {
                if let price = eventTickets[0]["source"] as? String {
                    eventTicketsLbl.text = price
                }
            }
            
        }
    }
    
    private func configureMapView() {
        // Set up map.
        eventmapView.layer.cornerRadius = 10
        
        // Get coordinates from event address
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(eventAddress) { (placemarks, error) in
            if (error != nil) {
                print("error in geocodeAddressString")
            }
            
            if let placemarks = placemarks, !placemarks.isEmpty {
                let placemark = placemarks.first
                let lat = placemark?.location!.coordinate.latitude
                let lon = placemark?.location!.coordinate.longitude
                let location = CLLocation(latitude: lat!, longitude: lon!)
                
                // Create map annotation for current location.
                let locAnnotation = EventAnnotation(title: self.eventAddress, coordinate: (placemark?.location!.coordinate)!)
                
                // Update mapView with coordinates.
                self.eventmapView.centerToLocation(location)
                self.eventmapView.addAnnotation(locAnnotation)
            }
        }
    }
    
    func clickableLabel(_ label: UILblClickableLinks, didTapUrl urlStr: String, atRange range: NSRange) {
        guard let url = URL(string: urlStr) else { return }
        UIApplication.shared.open(url)
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
//extension DetailsViewController: UILabelClickableLinksDelegate {
//    func clickableLabel(_ label: UILblClickableLinks, didTapUrl urlStr: String, atRange range: NSRange) {
//        guard let url = URL(string: urlStr) else { return }
//        UIApplication.shared.open(url)
//    }
//}

private extension MKMapView {
    func centerToLocation(_ location: CLLocation, regionRadius: CLLocationDistance = 200) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        setRegion(coordinateRegion, animated: true)
    }
}
