//
//  RouteHeader.swift
//  triviataxi
//
//  Created by Alex Joy Schenning on 2/12/26.
//

import SwiftUI
import MapboxMaps
internal import Combine

struct Header: View {
    let title : String
    let onHomeTapped: () -> Void

    var body: some View {
        ZStack {

            //TODO: Figure out why title is covered by camera
            Button(action: onHomeTapped) {
                Circle()
                    .fill(Color(red: 1, green: 0.84, blue: 0))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "house.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                    )
            }
            .offset(x: -150)

            Text(title)
                .font(.system(size: 32, weight: .semibold))
                .italic()
                .foregroundColor(.black)

            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.black)

                Text("1000")
                    .font(.system(size: 15, weight: .semibold))
            }
            .offset(x: 150)
        }
        .frame(height: 44)
        .padding(.top, 34)
        .padding(.bottom, 12)
    }
}
