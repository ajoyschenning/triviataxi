//
//  triviataxiApp.swift
//  triviataxi
//

import SwiftUI
import FirebaseCore

// 1. The "Switchboard" - This MUST be here to start Firebase
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // This is the specific line your error says is missing:
        FirebaseApp.configure()
        return true
    }
}

@main
struct triviataxiApp: App {
    // 2. Connect the Switchboard to SwiftUI
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // 3. The State to switch screens
    @State private var appUserIsLoggedIn = false

    var body: some Scene {
        WindowGroup {
            if appUserIsLoggedIn {
                // If logged in, go to the Game
                HomeView(userIsLoggedIn: $appUserIsLoggedIn)
            } else {
                // If not, go to the Login (and pass the switch so it can turn it on)
                LoginView(userIsLoggedIn: $appUserIsLoggedIn)
            }
        }
    }
}
