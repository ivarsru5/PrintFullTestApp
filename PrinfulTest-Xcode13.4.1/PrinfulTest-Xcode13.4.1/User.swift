//
//  User.swift
//  PrinfulTest-Xcode13.4.1
//
//  Created by Guna Ruģele on 01/02/2023.
//

import Foundation
import CoreLocation

struct User: Identifiable, Equatable {
    var id: Int
    let name: String
    let image: String
    var latitude: Double
    var longitude: Double
    var address: String
    
    struct UserUpdate: Identifiable{
        var id: Int
        var latitude: Double
        var longitude: Double
    }
}



