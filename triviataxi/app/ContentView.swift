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

