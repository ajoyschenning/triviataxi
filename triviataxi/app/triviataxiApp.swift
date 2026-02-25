//
//  triviataxiApp.swift
//  triviataxi
//
import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct triviataxiApp: App {
    
    // 1. Define the State
    @State private var appUserIsLoggedIn = false
    
    // 2. The "Bulletproof" Start-Up
    init() {
        // A. Start the Engine
        FirebaseApp.configure()
        print("✅ Firebase Configured")
        
        // B. Check if the user is ALREADY logged in (Auto-Login)
        // We do this check manually here to set the initial state correctly
        if Auth.auth().currentUser != nil {
            print("👋 User is already signed in")
            _appUserIsLoggedIn = State(initialValue: true)
        }
    }

    var body: some Scene {
        WindowGroup {
            if appUserIsLoggedIn {
                // Pass the binding so the HomeView can log out if needed
                HomeView(userIsLoggedIn: $appUserIsLoggedIn)
            } else {
                LoginView(userIsLoggedIn: $appUserIsLoggedIn)
            }
        }
    }
}
