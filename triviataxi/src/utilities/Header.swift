//
//  RouteHeader.swift
//  triviataxi
//

internal import Combine
import MapboxMaps
import SwiftUI



struct Header: View {
    @EnvironmentObject var userManager: UserManager
    let title: String
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

                Text("\(userManager.coins)")
                    .font(.system(size: 15, weight: .semibold))
            }
            .offset(x: 150)
        }
        .frame(height: 44)
        .padding(.top, 34)
        .padding(.bottom, 12)
    }
}
