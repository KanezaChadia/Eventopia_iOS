//
//  AppDelegate.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 4/25/23.
//

import UIKit
import CoreData
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FirebaseApp.configure()
        
        let userDefaults = UserDefaults.standard
        
        if !userDefaults.bool(forKey: "hasBeenLaunched") {
            print("Launching app for the first time.")
            
            // Update user defaults.
            userDefaults.set(true, forKey: "hasBeenLaunched")
            
            // Attempt to sign the previously signed in user out of Firebase.
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
            }
        } else {
            print("Launching app again.")
        }
        
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

