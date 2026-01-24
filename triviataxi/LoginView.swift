//
//  LoginView.swift
//  triviataxi
//
//  Created by Cami Krugel on 1/23/26.

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var userIsLoggedIn = false
    @State private var isPasswordVisible = false

    var body: some View {
        if userIsLoggedIn {
                    ContentView(userIsLoggedIn: $userIsLoggedIn)
        } else {
            ZStack {
                // 1. The Background Layer
                Color("TaxiYellow")
                    .ignoresSafeArea()
                
                // 2. The Content Layer
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // Header Section
                        VStack(spacing: 10) {
                            Image(systemName: "taxi.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.black)
                                .padding()
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                                )
                            
                            Text("TRIVIA TAXI")
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                                .tracking(2) // Spacing between letters
                        }
                        .padding(.top, 60)
                        
                        // Form Section (The Card)
                        VStack(spacing: 20) {
                            
                            // Email Input
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.gray)
                                TextField("Email Address", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                            }
                            .padding()
                            .frame(height: 55)
                            .background(Color.white)
                            .cornerRadius(12)
                            
                            // Password Input
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                if isPasswordVisible {
                                    TextField("Password", text: $password).textInputAutocapitalization(.never)
                                } else {
                                    SecureField("Password", text: $password)
                                }
                                // The Eye Button
                                Button(action: {
                                    isPasswordVisible.toggle()
                                }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .frame(height: 55)
                            .background(Color.white)
                            .cornerRadius(12)
                            
                            // Error Message
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Action Buttons
                            Button(action: login) {
                                Text("START RIDE")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black)
                                    .cornerRadius(12)
                                    .shadow(radius: 5)
                            }
                            
                            Button(action: register) {
                                Text("New Passenger? Sign Up")
                                    .font(.footnote)
                                    .foregroundColor(.black.opacity(0.7))
                            }
                        }
                        .padding(25)
                        
                        Spacer()
                    }
                }
            }
            .onAppear {
                if Auth.auth().currentUser != nil {
                    userIsLoggedIn = true
                }
            }
        }
    }
    
    // MARK: - Logic 
    
    func login() {
        errorMessage = ""
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                userIsLoggedIn = true
            }
        }
    }
    
    func register() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                userIsLoggedIn = true
            }
        }
    }
}

#Preview {
    LoginView()
}
