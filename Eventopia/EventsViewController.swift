//
//  EventsViewController.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 4/30/23.
//

import UIKit
import Kingfisher

class EventsViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var noEventMsgLbl: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    var userUpcomingEvents = [Event]()
    var userPastEvents = [Event]()
    var userFavoriteEvents = [Event]()
    var eventTypeArray = [[Event]]()
    var selectedEvent: Event?
    
    var editEvent = false
    var updateLV = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
       
        
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(red: 224/255, green: 210/255, blue: 104/255, alpha: 1)], for: .selected)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let allUserEvents = CurrentUser.currentUser?.userEvents ?? [Event]()
        
        userUpcomingEvents = allUserEvents.filter({ $0.status == "attending" && $0.isPast == false })
        userPastEvents = allUserEvents.filter({ $0.isPast == true && $0.status == "attending" }).reversed()
        userFavoriteEvents = allUserEvents.filter({ $0.isFavorite == true })
        
        
        eventTypeArray = [userUpcomingEvents, userPastEvents, userFavoriteEvents]
        
        noEventMsgLbl.isHidden = !eventTypeArray[segmentedControl.selectedSegmentIndex].isEmpty
        
        tableView.reloadData()
        
        if editEvent {
            editEvent = false
            
            // Show CreateEventViewController.
            self.performSegue(withIdentifier: "goToEdit", sender: self)
        }
    }
    
    @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
        
        self.tableView.reloadSections(IndexSet([0]), with: .fade)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventTypeArray[segmentedControl.selectedSegmentIndex].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "table_cell_2", for: indexPath) as! CustomTableViewCell
        let dataToShow = eventTypeArray[segmentedControl.selectedSegmentIndex]
        let event = dataToShow[indexPath.row]
        
        cell.eventImageView.layer.cornerRadius = 10
        
        if segmentedControl.selectedSegmentIndex != 0 {
            cell.eventImageView.kf.indicatorType = .activity
            cell.eventImageView.kf.setImage(with: URL(string: event.imageUrl), placeholder: event.image, options: [.transition(.fade(1))], completionHandler: { result in
                switch result {
                case .success(let value):
                    dataToShow[indexPath.row].image = value.image
                    event.image = value.image
                    
                    switch self.segmentedControl.selectedSegmentIndex {
                    case 1:
                        if !self.userPastEvents.isEmpty {
                            self.userPastEvents[indexPath.row].image = value.image
                        }
                        break
                    case 2:
                        if !self.userFavoriteEvents.isEmpty {
                            self.userFavoriteEvents[indexPath.row].image = value.image
                        }
                        break
                    
                    default:
                        break
                    }
                    
                    CurrentUser.currentUser?.userEvents?.first(where: { $0.id == event.id})?.image = value.image
                    break
                    
                case .failure(let error):
                    if !error.isTaskCancelled && !error.isNotCurrentTask {
                        print("Error getting image: \(error)")
                    }
                    break
                }
            })
        } else {
            cell.eventImageView.image = event.image
        }

        cell.eventDateLbl.text = event.date
        
        if event.isCreated {
            let title = NSMutableAttributedString(string: "\(event.title) ")
            let imageAttachment = NSTextAttachment()
            
            // Resize image
            let targetSize = CGSize(width: 14, height: 14)
            imageAttachment.image = UIImage(named: "logo_placeholder")?.scalePreservingAspectRatio(targetSize: targetSize).withTintColor(UIColor(red: 224/255, green: 210/255, blue: 104/255, alpha: 1))
            
            let imageStr = NSAttributedString(attachment: imageAttachment)
            
            title.append(imageStr)
            
            cell.eventTitleLbl.attributedText = title
        } else {
            cell.eventTitleLbl.text = event.title
        }
        
        cell.eventAddressLbl.text = event.address
        cell.favoriteBtn.isHidden = true

        return cell
    }
    
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect row for animation purposes.
        tableView.deselectRow(at: indexPath, animated: true)
        
        let dataToShow = eventTypeArray[segmentedControl.selectedSegmentIndex]
        
        // Set selected event to be passed to DetailsViewController
        selectedEvent = dataToShow[indexPath.row]
        
        // Show DetailsViewController.
        self.performSegue(withIdentifier: "goToDetails", sender: self)
    }
    


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Action if navigating to DetailsViewController.
        if  segue.identifier == "goToDetails",
                   let destination = segue.destination as? DetailsViewController
               {
            destination.event = self.selectedEvent
            destination.editEvent = {
                self.editEvent = true
            }
        }
        
//        if let destination = segue.destination as? CreateEventViewController {
//            destination.event = self.selectedEvent
//            destination.updateCV = {
//                self.updateLV = true
//            }
//        }
    }

}
