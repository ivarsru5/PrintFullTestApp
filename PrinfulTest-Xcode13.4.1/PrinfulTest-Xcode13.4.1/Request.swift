//
//  Request.swift
//  PrinfulTest-Xcode13.4.1
//
//  Created by Guna Ruģele on 01/02/2023.
//

import Foundation
import Network
import CoreLocation


class Requests: ObservableObject{
    @Published var users = [User]()
    
    //Defining connection to server
    private var connection: NWConnection?
    
    init(){
        self.connect(email: "rugelis.ivars@gmail.com")
    }
    
    
    //Defining host/port of connection, and .stateUpdateHandler listens for changes in connection.
    //In case connection to server .failed should handel error, but in this case instead of alert presenting, just print to console error.
    
    //If connection is successful send AUTHORIZE comand <email> to server to recive users in background thread.
    func connect(email: String){
        let host = NWEndpoint.Host("ios-test.printful.lv")
        let port = NWEndpoint.Port(integerLiteral: 6111)
        
        connection = NWConnection(host: host, port: port, using: .tcp)
        connection?.stateUpdateHandler = { state in
            switch state{
            case .ready:
                print("Connected to server")
                let authorize = "AUTHORIZE \(email)\n".data(using: .utf8)
                self.connection?.send(content: authorize, completion: .contentProcessed{ error in
                    if error == nil{
                        print("authorize command sent")
                        self.receiveData()
                    }else{
                        print("Error sending comand: \(String(describing: error))")
                    }
                })
            case .failed(let error):
                print("Error connecting to server: \(error)")
            default:
                break
            }
        }
        connection?.start(queue: DispatchQueue.global())
    }
    
    //Receiving data from server, with min/max set length of data in trailing closure.
    //Until isComplete state changes to 'true' function executes in recursive maner to keep receiving data from server until connection is closed.
    func receiveData(){
        self.connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536, completion: { data, context, isComplete, error in
            if let data = data, let response = String(data: data, encoding: .utf8){
                print("Response \(response)")
                self.collectUsers(response)
            } else if let error = error{
                print("Error geting data: \(error)")
            }
            if !isComplete{
                self.receiveData()
            }
        })
    }
    
    //This function call is invoked the given moment 'response' is received form server.
    //As the first time response provides with name and image function create new struct of 'User' for it to store the data.
    
    //If users already exists function invokes processData(response:) to get updated information.
    //After receiving update data group enters for loop to call geocodeAddress() and not proceed util completion block executes leaves the grop to notify changes.
    func collectUsers(_ response: String){
        let group = DispatchGroup()
        
        if users.count != 0{
            let updates = processData(response: response)
            
            for user in updates{
                group.enter()
                
                geocodeAddress(latitude: user.latitude, longitude: user.longitude) { address in
                    if let index = self.users.firstIndex(where: { $0.id == user.id }){
                        self.users[index].latitude = user.latitude
                        self.users[index].longitude = user.longitude
                        self.users[index].address = address
                        group.leave()
                    }
                }
            }
            group.notify(queue: .main){
                print("Users updated")
            }
        }else{
            var userData = response.components(separatedBy: ";")
            userData.removeLast()
            
            let users = userData.compactMap { userString -> User? in
                
                let userProperties = userString.components(separatedBy: ",")
                
                var idPart = userProperties[0].components(separatedBy: " ")
                if idPart.count == 2{
                    idPart.removeFirst()
                }
                
                guard userProperties.count == 5 else { return nil }
                guard let id = Int(idPart[0]),
                      let latitude = Double(userProperties[3]),
                      let longitude = Double(userProperties[4]) else { return nil }
                
                var collectedUser = User(id: id, name: userProperties[1], image: userProperties[2], latitude: latitude, longitude: longitude, address: "")
                group.enter()
                geocodeAddress(latitude: latitude, longitude: longitude) { address in
                    collectedUser.address = address
                    group.leave()
                }
                return collectedUser
            }
            group.notify(queue: .main){
                self.users = users
            }
        }
    }
    
    //Given the response from server function processes it and returns array with updated user information.
    func processData(response: String) -> [User.UserUpdate] {
        var updates = [User.UserUpdate]()
        
        var data = response.components(separatedBy: "\n")
        data.removeLast()

        data.forEach { part in
            let components = part.components(separatedBy: ",")
            let userID = components[0].components(separatedBy: " ")

            let id = Int(userID[1])
            let latitude = Double(components[1])!
            let longitude = Double(components[2])!
            
            updates.append(User.UserUpdate(id: id!, latitude: latitude, longitude: longitude))
        }
        return updates
    }
    
    //Function call with parameter latitude/longitude calls reversGeacode trailing completion. As the call is asyncrounous it send data to completion in the same manner.
    //As user information, and UI updates is on main queue.
    func geocodeAddress(latitude: Double, longitude: Double, completion: @escaping (String) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if error == nil {
                let placemark = placemarks?[0]
                if let thoroughfare = placemark?.thoroughfare, let subThoroughfare = placemark?.subThoroughfare {
                    let collectedAddress = thoroughfare + " " + subThoroughfare
                    completion(collectedAddress)
                }
            } else {
                print("Could not get address \(error!.localizedDescription)")
            }
        }
    }

}
