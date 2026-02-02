//
//  PlayView.swift
//  triviataxi
//
//  Created by Alex Joy Schenning on 2/2/26.
//

import SwiftUI
import MapboxMaps
internal import Combine

// MARK: - Map (Start Ride)
struct NashvilleMapView: View {
    @Binding var showMap: Bool
    private let nashville = CLLocationCoordinate2D(latitude: 36.1447, longitude: -86.8027)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(initialViewport: .camera(
                center: nashville,
                zoom: 16,
                bearing: 0,
                pitch: 70
            )).mapStyle(MapStyle(uri: StyleURI(rawValue: "mapbox://styles/ajoyschenning/cmkvltd86003u01s0ccingat8")!))
            .ignoresSafeArea()

            Button(action: {
                showMap = false
            }) {
                Image(systemName: "house.fill")
                    .font(.title)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color(hex: "#FFECA1"))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 3)
                    )
            }
            .padding()

        }
    }
}
