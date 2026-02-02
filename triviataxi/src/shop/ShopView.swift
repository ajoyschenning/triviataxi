//
//  ShopView.swift
//  triviataxi
//
//  Created by Alex Joy Schenning on 2/2/26.
//

import SwiftUI
import MapboxMaps
internal import Combine

// MARK: Shop View

struct ShopView: View {
    @Binding var showShop: Bool   // control navigation

    var body: some View {
        VStack(spacing: 0) {

            // 🔒 Static Header
            ShopHeader {
                showShop = false
            }

            // 📜 Scrollable Destinations
            ScrollView {
                VStack(spacing: 28) {
                    Text("DESTINATIONS")
                        .font(.system(size: 32, weight: .semibold))
                        .italic()
                        .foregroundColor(.black)
                        .padding(.top, 24)

                    DestinationCard(city: "New York", miles: "25 Miles", price: 100)
                    DestinationCard(city: "Washington DC", miles: "20 Miles", price: 100)
                    DestinationCard(city: "Miami", miles: "22 Miles", price: 150)
                    DestinationCard(city: "Boston", miles: "42 Miles", price: 250)
                    DestinationCard(city: "Paris", miles: "40 Miles", price: 200)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 21)
            }
        }
        .background(Color(red: 1, green: 0.98, blue: 0.80))
        .ignoresSafeArea(edges: .top)
    }
}

struct ShopHeader: View {
    let onHomeTapped: () -> Void

    var body: some View {
        ZStack {
            // Home Button
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

            // Title
            Text("Shop")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.11, green: 0.12, blue: 0.16))

            // Coin Balance
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
        .background(Color(red: 1, green: 0.98, blue: 0.80))
    }
}

struct DestinationCard: View {
    let city: String
    let miles: String
    let price: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(
                    color: Color(red: 0.71, green: 0.74, blue: 0.79, opacity: 0.14),
                    radius: 20,
                    y: 6
                )

            HStack(spacing: 16) {

                // Placeholder image
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.5))
                    .frame(width: 95, height: 116)

                VStack(alignment: .leading, spacing: 8) {
                    Text(miles)
                        .font(.system(size: 16))
                        .foregroundColor(.black)

                    Text(city)
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundColor(.black)

                    Spacer()

                    HStack(spacing: 10) {

                        HStack(spacing: 6) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.black)

                            Text("\(price)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 1, green: 0.84, blue: 0))
                        .cornerRadius(8)

                        Button(action: {
                            // TODO: purchase action
                        }) {
                            Text("BUY NOW")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.black)
                                .cornerRadius(8)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .frame(height: 140)
    }
}
