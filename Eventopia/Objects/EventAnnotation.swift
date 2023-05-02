//
//  EventAnnotation.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 4/30/23.
//

import Foundation
import MapKit

class EventAnnotation: NSObject, MKAnnotation {
    let title: String?
    let coordinate: CLLocationCoordinate2D
    
    init(title: String?, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
        
        super.init()
    }
}
