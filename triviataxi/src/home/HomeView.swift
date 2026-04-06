//
//  HomeView.swift
//  triviataxi
//

internal import Combine
import FirebaseAuth
import MapboxMaps
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userManager: UserManager
    @Binding var userIsLoggedIn: Bool
    
    @State private var showRoutes = false
    @State private var showShop = false
    @State private var showLeaderboard = false
    @State private var showProfile = false
    
    var body: some View {
        NavigationStack {
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
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.4
                            ) { showRoutes = true }
                        }
                        
                        FancyButton(title: "PROFILE") {
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                        showProfile = true
                                                    }
                                                }
                        
                        FancyButton(title: "SHOP") {
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.4
                            ) {
                                showShop = true
                            }
                        }
                        
                        FancyButton(title: "LEADERBOARD") {
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.4
                            ) {
                                showLeaderboard = true
                            }
                        }
                        
                        FancyButton(title: "LOG OUT") {
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.4
                            ) {
                                logout()
                            }
                        }
                    }.task {
                        // This function already has a safety check built in (guard !isProfileLoaded)
                        // so it will only ever hit your Firebase database ONCE per session.
                        await userManager.loadUserProfile()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .navigationDestination(isPresented: $showRoutes) {
                RouteSelectionView(showRoutes: $showRoutes)
            }
            .navigationDestination(isPresented: $showShop) {
                ShopView(showShop: $showShop)
            }
            .navigationDestination(isPresented: $showLeaderboard) {
                LeaderboardView(showLeaderboard: $showLeaderboard)
            }
            .navigationDestination(isPresented: $showProfile) {
                if let profile = userManager.userProfile {
                    ProfileView(userManager: userManager)
                } else {
                    VStack(spacing: 20) {
                        ProgressView("Hailing your data...")
                            .tint(.black)
                        
                        Button("Retry Connection") {
                            Task {
                                await userManager.loadUserProfile()
                            }
                        }
                        .font(.caption)
                    }
                    .task {
                        // 🚀 If we arrive here and it's nil, try loading one more time
                        if userManager.userProfile == nil {
                            await userManager.loadUserProfile()
                        }
                    }
                }
            }
        }
    }
    
    func logout() {
        // Reset any presented destinations
        showRoutes = false
        showShop = false
        showLeaderboard = false
        showProfile = false
        
        try? Auth.auth().signOut()
        userIsLoggedIn = false
    }
}

#Preview {
    HomeView(userIsLoggedIn: .constant(true))
}
