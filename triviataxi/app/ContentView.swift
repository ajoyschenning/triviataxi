//
//  ContentView.swift
//  triviataxi
//
//  Created by Alex Joy Schenning on 1/23/26.
//
import SwiftUI
import MapboxMaps
import FirebaseAuth
internal import Combine

// MARK: HomeView
// TESTING
struct HomeView: View {
    @Binding var userIsLoggedIn: Bool
    
    @State private var showMap = false
    @State private var showShop = false
    @State private var showLeaderboard = false
    @State private var loggedIn = false

    var body: some View {
        ZStack {
            if !(userIsLoggedIn) {
                LoginView(userIsLoggedIn: .constant(false))
            }
            else if showMap {
                NashvilleMapView(showMap: $showMap)
//                NavigationViewControllerRepresentable()
//                            .edgesIgnoringSafeArea(.all)
            } else if showShop {
                ShopView(showShop: $showShop)
            } else if showLeaderboard {
                LeaderboardView(showLeaderboard: $showLeaderboard)
            } else {
                ZStack {
                    DollarRainBackground()
                    GoldFadeOverlay()
                    
                    VStack(spacing: 36) {
                        Spacer()
                        
                        Image("taxi")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300)
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 6)
                        
                        VStack(spacing: 20) {
                            FancyButton(title: "START RIDE") {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        showMap = true
                                    }
                            }
                            FancyButton(title: "SHOP") {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    showShop = true
                                }
                            }
                            FancyButton(title: "LEADERBOARD") {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    showLeaderboard = true
                                }
                            }
                            FancyButton(title: "LOG OUT") {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        logout()
                                }
                            }
                        }
                        // TODO: update font on buttons
                        
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                }}
        }
    }
    func logout() {
        try? Auth.auth().signOut()
        userIsLoggedIn = false
    }
}




#Preview {
    HomeView(userIsLoggedIn: .constant(true))
}
