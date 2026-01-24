//
//  ContentView.swift
//  triviataxi
//
//  Created by Alex Joy Schenning on 1/23/26.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    // This connects to the 'userIsLoggedIn' switch in LoginView
    @Binding var userIsLoggedIn: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            Button("Log Out") {
                // 1. Tell Firebase to close the session
                try? Auth.auth().signOut()
                // 2. Flip the switch to show the Login Screen again
                userIsLoggedIn = false
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
    }
}

// This helps the preview window work without crashing
#Preview {
    ContentView(userIsLoggedIn: .constant(true))
}
