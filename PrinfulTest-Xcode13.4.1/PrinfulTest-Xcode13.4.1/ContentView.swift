//
//  ContentView.swift
//  PrinfulTest-Xcode13.4.1
//
//  Created by Guna Ruģele on 01/02/2023.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject var request = Requests()
    @State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 56.946285, longitude: 24.105078), span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
    
    var body: some View {
        Map(coordinateRegion: $mapRegion, annotationItems: request.users){ user in
            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude)) {
                AnnotationView(requests: request, user: user)
                    .animation(.linear(duration: 1), value: user)
            }
        }
    }
    
    struct AnnotationView: View{
        @ObservedObject var requests: Requests
        @State private var showDetails = false
        let user: User
        
        var body: some View{
            ZStack{
                if showDetails{
                    withAnimation(.easeInOut) {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.white)
                            .frame(width: 180, height: 50)
                            .overlay{
                                VStack{
                                    Text(user.name)
                                        .foregroundColor(.black)
                                        .font(.title3)
                                    Text(user.address)
                                        .foregroundColor(.gray)
                                }
                            }
                            .offset(y: -50)
                    }
                }
                
                Circle()
                    .frame(width: 35, height: 35)
                    .foregroundColor(.white)
                
                AsyncImage(url: URL(string: user.image)) { image in
                    image
                        .resizable()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                        .scaledToFit()
                } placeholder: {
                    Image(systemName: "person.circle")
                }
                .onTapGesture {
                    self.showDetails.toggle()
                }
            }
        }
    }
}
