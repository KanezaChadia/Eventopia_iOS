//
//  HomeViewController.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 4/27/23.
//

import UIKit
import CoreLocation
import Firebase
import Kingfisher

class HomeTableViewController: UITableViewController,CLLocationManagerDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    let db = Firestore.firestore()
    let userId = Auth.auth().currentUser?.uid
    var docRef: DocumentReference?
    
    let manager = CLLocationManager()
    
    var useCurrentLocation = true
    var locationStr = "Kigali,RW"
    var allUserEvents = [Event]()
    var userUpcomingEvents = [Event]()
    var localEvents = [Event]()
    var selectedEvent: Event?
    var editEvent = false
    var apiKey = "f5f6c4283773ca865ad9b308708d823a2f01101aa39aeabcba72bfde7014c9e8"
    
    var filteredEvents = [Event]()
    var recentSearches = [String]()
    var nonSearchBarInputStr = ""
    var searchResults = [Event]()
    var tempLocalEvents = [Event]()
    
    var favoritesDelegate: EventDataDelegate!
    var getImageDelegate: GetImageDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        docRef = db.collection("users").document(userId!)
        favoritesDelegate = FirebaseHelper()
        getImageDelegate = GetImageHelper()
        
        useCurrentLocation = UserDefaults.standard.object(forKey: "\(userId!)useCurrentLocation") as? Bool ?? true
        
        if !useCurrentLocation {
            if let preferredLocation = UserDefaults.standard.stringArray(forKey: "\(userId!)preferredLocation"),
               let lat = Double(preferredLocation[3]), let lon = Double(preferredLocation[4]) {
                let loc = Location(city: preferredLocation[0], coordinates: [lat, lon], state: preferredLocation[1], id: preferredLocation[2])
                
                CurrentLocation.preferredLocation = loc
                locationStr = loc.city
                getLocalEvents(loc: loc.searchStr)
            }
            
            searchBar.delegate = self
            searchBar.placeholder = "Find Events"
         
           
           
        }
        
        //getLocalEvents(loc: "Atlanta")
        
        //getUserLocation()
        
        
        // Register CustomTableViewHeader xib.
        let headerNib = UINib.init(nibName: "CustomTableViewHeader", bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "header_1")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let prefLoc = CurrentLocation.preferredLocation
        
        if prefLoc != nil && locationStr != prefLoc!.city {
            locationStr = prefLoc!.city
            //getLocalEvents(loc: prefLoc!.searchStr)
            
        }
        
        getLocalEvents(loc: "Kigali+Rwanda")
        
        if !editEvent {
            let currentEventCount = allUserEvents.count
            let actualEventCount = CurrentUser.currentUser?.userEvents?.count
            
            CurrentUser.currentUser?.userEvents = CurrentUser.currentUser?.userEvents?.sorted(by: { $0.dateStamp < $1.dateStamp })
            allUserEvents = CurrentUser.currentUser?.userEvents ?? [Event]()
            userUpcomingEvents = allUserEvents.filter({ $0.status == "attending" && $0.isPast == false })

            // Reload tableView collectionView if events have been added or removed.
            if currentEventCount != actualEventCount {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func getUserLocation() {
        manager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.startUpdatingLocation()
        } else {
            // Alert user that they need to enable location services.
            print("Services Disabled")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(locations[0]) { (placemarks, error) in
            if (error != nil) {
                return
            }
            
            let placemark = placemarks! as [CLPlacemark]
            
            if placemark.count > 0 {
                let placemark = placemarks![0]
                
                if self.locationStr != placemark.locality! {
                    let currentLocation = Location(city: placemark.locality!, coordinates: [placemark.location!.coordinate.latitude, placemark.location!.coordinate.longitude], state: placemark.administrativeArea!, id: placemark.postalCode!)
                    
                    CurrentLocation.location = currentLocation
                    
                    if self.useCurrentLocation {
                        self.locationStr = currentLocation.city
                        
                        CurrentLocation.preferredLocation = CurrentLocation.location
                        
                        self.getLocalEvents(loc: currentLocation.searchStr)
                    }
                }
            }
        }
    }
    
    
    private func getLocalEvents(loc: String) {
        self.localEvents.removeAll()
        
        // Create default configuration.
        let config = URLSessionConfiguration.default

        // Create session.
        let session = URLSession(configuration: config)
        
        // Validate URL.
        if let validURL = URL(string: "https://serpapi.com/search.json?engine=google_events&q=events+in+\(loc)&api_key=\(apiKey)") {
            // Create task to download data from validURL as Data object.
            let task = session.dataTask(with: validURL, completionHandler: { (data, response, error) in
                // Exit method if there is an error.
                if let error = error {
                    print("Task failed with error: \(error.localizedDescription)")
                    return
                }

                // If there are no errors, check response status code and validate data.
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200, // 200 = OK
                      let validData = data
                else {
                    DispatchQueue.main.async {
                        // Present alert on main thread if there is an error with the URL (subreddit does not exist).
//                        self.present(alert, animated: true, completion: nil)
                    }
                    
                    print("JSON object creation failed.")
                    return
                }
                
                // Create Event object.
                do {
                    // Create json Object from downloaded data above and cast as [String: Any].
                    if let jsonObj = try JSONSerialization.jsonObject(with: validData, options: .mutableContainers) as? [String: Any] {
                        guard let data = jsonObj["events_results"] as? [[String: Any]]
                        else {
                            print("The data cannot be found")
                            return
                        }
                        
                        for event in data {
                            // Step through outer level data to get to relevant event data.
                            guard let title = event["title"] as? String,
                                  let date = event["date"] as? [String: Any],
                                  let address = event["address"] as? [String],
                                  let link = event["link"] as? String,
                                  let description = event["description"] as? String,
                                  let tickets = event["ticket_info"] as? [[String: Any]],
                                  let imageUrl = event["thumbnail"] as? String
                            else {
                                print("There was an error with this local event's data")
                                continue
                            }
                            
                            guard let start = date["start_date"] as? String,
                                  let when = date["when"] as? String
                            else {
                                print("Date data cannot be found")
                                return
                            }
                            
                            let dateStr = "\(start) | \(when)"
                            let addressStr = "\(address[0]), \(address[1])"
                            let eventImage = UIImage(named: "logo_placeholder")!
       
                            self.localEvents.append(Event(id: "", title: title, date: dateStr, address: addressStr, link: link, description: description, tickets: tickets, imageUrl: imageUrl, image: eventImage))
                        }
                    }
                }
                catch{
                    print("Error: \(error.localizedDescription)")
                }
                
                self.localEvents = self.localEvents.sorted(by: { $0.dateStamp < $1.dateStamp })
                
                DispatchQueue.main.async {
                    self.tableView.reloadSections(IndexSet([0]), with: .fade)
                }
            })
            // Start task.
            task.resume()
        }
    }
    
    
    
    // MARK: - Table view data source
    

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return localEvents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:  "table_cell_1", for: indexPath)  as! CustomTableViewCell
        
        let event = localEvents[indexPath.row]
        
        cell.eventImageView.layer.cornerRadius = 10
        cell.eventImageView.kf.indicatorType = .activity
        cell.eventImageView.kf.setImage(with: URL(string: event.imageUrl), placeholder: UIImage(named: "logo_placeholder"), options: [.transition(.fade(1))], completionHandler: { result in
            switch result {
            case .success(let value):
                event.image = value.image
                self.localEvents[indexPath.row].image = value.image
                break
                
            case .failure(let error):
                if !error.isTaskCancelled && !error.isNotCurrentTask {
                    print("event: \(event.title)")
                    print("Error getting tv image: \(error)")
                }
                break
            }
        })
        
        cell.eventDateLbl.text = event.date
        cell.eventTitleLbl.text = event.title
        cell.eventAddressLbl.text = event.address
        cell.favoriteBtn.isSelected = allUserEvents.filter({$0.isFavorite == true}).contains(where: {$0.title == event.title})
        cell.favoriteBtn.tintColor = cell.favoriteBtn.isSelected ? UIColor(red: 224/255, green: 210/255, blue: 104/255, alpha: 1) : .systemGray
    
        cell.favBtnTapped = { (favoriteBtn) in
            var updateEvent: Event?
            // Set event to be updated.
            if let index = CurrentUser.currentUser?.userEvents?.firstIndex(where: { $0.title == event.title && $0.link == event.link }) {
                // If event is contained in user's events, pass that event instead.
                // This ensures correct information is shown on DetailsViewController.
                updateEvent = CurrentUser.currentUser?.userEvents?[index]
            } else {
                // Create a copy of the event to prevent modifying the underlying data.
                updateEvent = Event(id: event.id, title: event.title, date: event.date, address: event.address, link: event.link, description: event.description, tickets: event.tickets, imageUrl: event.imageUrl, image: event.image)
            }
            
            self.favoritesDelegate.setFavorite(event: updateEvent!, isFav: !favoriteBtn.isSelected)
            favoriteBtn.isSelected.toggle()
            favoriteBtn.tintColor = favoriteBtn.isSelected ? UIColor(red: 224/255, green: 210/255, blue: 104/255, alpha: 1) : .systemGray
        }
            
        
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header_1") as? CustomTableViewHeader
        header?.cellTitleLbl?.text = "Events Near \(locationStr)"

        return header
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.tableView.deselectRow(at: indexPath, animated: true)

        let localEvent = localEvents[indexPath.row]
        
        // Set selected event to be passed to DetailsViewController
        // If event is contained in user's events, pass that event instead.
        // This ensures correct information is shown on DetailsViewController.
        if let index = CurrentUser.currentUser?.userEvents?.firstIndex(where: { $0.title == localEvent.title && $0.link == localEvent.link }) {
            if localEvent.imageUrl != CurrentUser.currentUser?.userEvents?[index].imageUrl {
                CurrentUser.currentUser?.userEvents?[index].imageUrl = localEvent.imageUrl
                CurrentUser.currentUser?.userEvents?[index].image = localEvent.image
                
                // Update event thumbnail (imageUrl) in Firebase "events" collection.
                if let eId = CurrentUser.currentUser?.userEvents?[index].id {
                    db.collection("events").document(eId).updateData(["thumbnail": localEvent.imageUrl]) { err in
                        if let err = err {
                            print("Error updating thumbnail: \(err)")
                        } else {
                            print("Event thumbnail successfully updated in Firebase.")
                        }
                    }
                }
            }
            
            selectedEvent = CurrentUser.currentUser?.userEvents?[index]
        } else {
            selectedEvent = localEvent
        }

        //MARK: TO BE UPDATED Show DetailsViewController.
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
        
    }
    
    
}

extension HomeTableViewController: UISearchBarDelegate{
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        
        if(!tempLocalEvents.isEmpty){
            localEvents = tempLocalEvents
            //getLocalEvents(loc: locationStr)
        }
        
        tableView.reloadData()
    }

    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        var inputStr = searchBar.text ?? ""

        if inputStr.isEmpty {
            inputStr = nonSearchBarInputStr
        }

        if !inputStr.isEmpty {
            self.navigationItem.searchController?.searchBar.isHidden = true
            // Run query
            let formattedSearch = inputStr.replacingOccurrences(of: " ", with: "+")
            let searchStr = ("\(formattedSearch)+in+\(locationStr)")
            print(searchStr)

            findEvents(searchStr: searchStr)
            nonSearchBarInputStr = ""

            // Limit recent searches to 20 items.
            if recentSearches.count > 19 {
                recentSearches.removeLast()
            }

            recentSearches.insert(inputStr, at: 0)
        }
    }

       func updateSearchResults(for searchController: UISearchController) {
           // Filter the events based on the search text
           let searchText = searchController.searchBar.text ?? ""
           filteredEvents = localEvents.filter { $0.title.lowercased().contains(searchText.lowercased()) }

           // Reload the table view with the filtered events
           tableView.reloadData()
       }

    func findEvents(searchStr: String) {
        // Clear searchResults array.
        searchResults.removeAll()

        // Create default configuration.
        let config = URLSessionConfiguration.default

        // Create session.
        let session = URLSession(configuration: config)
        
        let stringURL = "https://serpapi.com/search.json?engine=google_events&q=\(searchStr)&api_key=\(apiKey)"

        // Validate URL.
        if let validURL = URL(string: stringURL) {
            // Create task to download data from validURL as Data object.
            let task = session.dataTask(with: validURL, completionHandler: { [self] (data, response, error) in
                // Exit method if there is an error.
                if let error = error {
                    print("Task failed with error: \(error.localizedDescription)")
                    return
                }

                // If there are no errors, check response status code and validate data.
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200, // 200 = OK
                      let validData = data
                else {
                    DispatchQueue.main.async {
                        // Present alert on main thread if there is an error with the URL (subreddit does not exist).
//                        self.present(alert, animated: true, completion: nil)
                    }

                    print("JSON object creation failed.")
                    return
                }

                // Create event object.
                do {
                    // Create json Object from downloaded data above and cast as [String: Any].
                    if let jsonObj = try JSONSerialization.jsonObject(with: validData, options: .mutableContainers) as? [String: Any] {
                        guard let data = jsonObj["events_results"] as? [[String: Any]]
                        else {
                            print("This isn't working")
                            return
                        }

                        for event in data {
                            // Step through outer level data to get to relevant post data.
                            guard let title = event["title"] as? String,
                                  let date = event["date"] as? [String: Any],
                                  let address = event["address"] as? [String],
                                  let link = event["link"] as? String,
                                  let description = event["description"] as? String,
                                  let tickets = event["ticket_info"] as? [[String: Any]],
                                  let imageUrl = event["thumbnail"] as? String
                            else {
                                print("There was an error with this event's data")

                                continue
                            }

                            guard let start = date["start_date"] as? String,
                                  let when = date["when"] as? String
                            else {
                                print("This isn't working")
                                return
                            }

                            let dateStr = "\(start) | \(when)"
                            let addressStr = "\(address[0]), \(address[1])"
                            let eventImage = UIImage(named: "logo_placeholder")!

                            self.searchResults.append(Event(id: "", title: title, date: dateStr, address: addressStr, link: link, description: description, tickets: tickets, imageUrl: imageUrl, image: eventImage))
                            self.tempLocalEvents = localEvents
                            self.localEvents = searchResults
                        }
                    }
                }
                catch{
                    print("Error: \(error.localizedDescription)")
                }

                self.searchResults = self.searchResults.sorted(by: { $0.dateStamp < $1.dateStamp })

                DispatchQueue.main.async {
                    self.tableView.reloadData()

                    self.navigationItem.searchController?.searchBar.isHidden = false
                }
            })
            // Start task.
            task.resume()
        }
    }
   }
