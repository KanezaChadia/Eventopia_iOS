//
//  User.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 4/25/23.
//


import Foundation
import UIKit

class User {
    // Stored properties.
    var firstName: String
    var lastName: String
    var email: String
    var userEvents: [Event]?
    var profilePic: UIImage?
    var recentSearches: [String]?
    var addDate: Date
    
    // Computed property.
    var fullName: String {
        get {
            return "\(firstName) \(lastName)"
        }
    }
    
    // Initializer.
    init(profilePic: UIImage? = nil, firstName: String, lastName: String, email: String, addDate: Date, userEvents: [Event]? = nil, recentSearches: [String]? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.userEvents = userEvents
        self.profilePic = profilePic
        self.recentSearches = recentSearches
        self.addDate = addDate
        
    }
}
