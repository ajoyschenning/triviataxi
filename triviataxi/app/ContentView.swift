//
//  ContentView.swift
//  triviataxi
//
internal import Combine
import FirebaseAuth
import MapboxMaps
import SwiftUI

struct ContentView: View {
    @State private var userIsLoggedIn = Auth.auth().currentUser != nil

    var body: some View {
        Group {
            if userIsLoggedIn {
                HomeView(userIsLoggedIn: $userIsLoggedIn)
            } else {
                LoginView(userIsLoggedIn: $userIsLoggedIn)
            }
        }
    }
}
