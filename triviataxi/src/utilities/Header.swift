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
