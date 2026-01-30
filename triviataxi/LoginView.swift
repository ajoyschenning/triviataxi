//
//  LoginView.swift
//  triviataxi
//
//  Created by Cami Krugel on 1/23/26.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Binding var userIsLoggedIn: Bool // Connected to ContentView
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isPasswordVisible = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("TaxiYellow").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "car.fill")
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
                                .tracking(2)
                        }
                        .padding(.top, 60)
                        
                        // Login Form
                        VStack(spacing: 20) {
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.gray)
                                TextField("Email Address", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                if isPasswordVisible {
                                    TextField("Password", text: $password)
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField("Password", text: $password)
                                }
                                
                                Button(action: { isPasswordVisible.toggle() }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                        .frame(width: 20)
                                }
                            }
                            .padding()
                            .frame(height: 55)
                            .background(Color.white)
                            .cornerRadius(12)
                            
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            
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
                            
                            NavigationLink(destination: SignUpView(userIsLoggedIn: $userIsLoggedIn)) {
                                Text("New Passenger? Sign Up")
                                    .font(.footnote)
                                    .foregroundColor(.black.opacity(0.7))
                                    .underline()
                            }
                        }
                        .padding(25)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // Logic
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                userIsLoggedIn = true
            }
        }
    }
}

#Preview {
    LoginView(userIsLoggedIn: .constant(false))
}
