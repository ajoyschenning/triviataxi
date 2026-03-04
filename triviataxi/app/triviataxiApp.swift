//
//  triviataxiApp.swift
//  triviataxi
//
import FirebaseAuth
import FirebaseCore
import SwiftUI

@main
struct triviataxiApp: App {
    @StateObject private var userManager = UserManager()
    @State private var appUserIsLoggedIn = false
    
    init() {
        // A. Start the Engine
        FirebaseApp.configure()
        print("✅ Firebase Configured")
        
        // B. Check if the user is ALREADY logged in (Auto-Login)
        if Auth.auth().currentUser != nil {
            print("👋 User is already signed in")
            _appUserIsLoggedIn = State(initialValue: true)
        }
        
    }
    
    var body: some Scene {
        WindowGroup {
            if appUserIsLoggedIn {
                HomeView(userIsLoggedIn: $appUserIsLoggedIn)
                    .environmentObject(userManager)

            } else {
                LoginView(userIsLoggedIn: $appUserIsLoggedIn)
            }
        }
    }
}
