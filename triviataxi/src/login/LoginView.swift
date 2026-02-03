//
//  LoginView.swift
//  triviataxi
//
//  Created by Cami Krugel on 1/23/26.
//

import SwiftUI
import FirebaseAuth
internal import Combine


struct LoginView: View {
    @Binding var userIsLoggedIn: Bool // Connected to ContentView
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isPasswordVisible = false

    var body: some View {
        NavigationStack {
        
            ZStack {
                
                Color("BackgroundYellow").ignoresSafeArea()
                GoldFadeOverlay()
                ScrollView{
                    
                    
                    VStack(spacing: 30) {
                        
                        // Header
                        
                        
                        Image("taxi")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300)
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 6).padding(.top, 60)
                        
                        
                        
                        
                        
                        
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
                            
                            FancyButton(title: "START RIDE") {
                                login()
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
                }}
        }
        }
    
    
    // Logic
func login() {
    Auth.auth().signIn(withEmail: email, password: password) { result, error in
        if let error = error {
            errorMessage = error.localizedDescription
        } else {
            errorMessage = ""
            userIsLoggedIn = true
        }
    }
}
}

#Preview {
    LoginView(userIsLoggedIn: .constant(false))
}
