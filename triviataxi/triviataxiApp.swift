//
//  triviataxiApp.swift
//  triviataxi
//
//  Created by Alex Joy Schenning on 1/23/26.
//

import SwiftUI
import FirebaseCore

// 1. Create the "Switchboard" (AppDelegate)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // This is where we turn the key to start Firebase
        FirebaseApp.configure()
        return true
    }
}

@main
struct triviataxiApp: App {
    // 2. Tell SwiftUI to use our Switchboard
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
}
