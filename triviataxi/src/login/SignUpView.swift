//
//  SignUpView.swift
//  triviataxi
//

import FirebaseAuth
import SwiftUI

struct SignUpView: View {
    @Binding var userIsLoggedIn: Bool
    
    @State private var leaderboardName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                Color("BackgroundYellow").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        Image("taxi")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200)
                            .shadow(
                                color: .black.opacity(0.2),
                                radius: 10,
                                y: 6
                            )
                        
                        Text("NEW DRIVER")
                            .font(.system(size: 36, weight: .bold))
                        
                        // The Form Card
                        VStack(spacing: 20) {
                            
                            // 1. Leaderboard Name
                            TextField(
                                "Leaderboard Name",
                                text: $leaderboardName
                            )
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .textInputAutocapitalization(.words)
                            
                            // 2. Email
                            TextField("Email Address", text: $email)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                            
                            // 3. Password
                            SecureField("Password", text: $password)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                            
                            // 4. Confirm Password
                            SecureField(
                                "Confirm Password",
                                text: $confirmPassword
                            )
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                // Show a checkmark if they match
                                Group {
                                    if !password.isEmpty
                                        && password == confirmPassword
                                    {
                                        Image(
                                            systemName: "checkmark.circle.fill"
                                        )
                                        .foregroundColor(.green)
                                        .padding(.trailing)
                                    }
                                },
                                alignment: .trailing
                            )
                            
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            
                            FancyButton(title: "CREATE ACCOUNT") {
                                register()
                            }
                        }
                        .padding(25)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    func register() {
        // 1. Client-side Validation
        guard !leaderboardName.isEmpty else {
            errorMessage = "Please enter a leaderboard name."
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        // 2. Create User in Firebase
        Auth.auth().createUser(withEmail: email, password: password) {
            result,
            error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            // Save the Display Name (leaderboardName) to Firebase Auth
            if let changeRequest = result?.user.createProfileChangeRequest() {
                changeRequest.displayName = leaderboardName
                changeRequest.commitChanges { error in
                    if let error = error {
                        print(
                            "Failed to save name: \(error.localizedDescription)"
                        )
                    }
                }
            }
            
            // Get the token from the USER
            result?.user.getIDToken { token, error in
                guard let token = token else {
                    return
                }
                
                // Create Profile in Backend
                createUserInBackend(
                    token: token,
                    email: email,
                    username: leaderboardName
                )
            }
            
        }
    }
    func createUserInBackend(token: String, email: String, username: String) {
        guard
            let url = URL(
                string:
                    "https://trivia-taxi-api-423193744278.us-central1.run.app/users/me"
            )
        else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Attach the security token!
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "email": email,
            "username": username,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ NETWORK ERROR: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Status Code: \(httpResponse.statusCode)")  // Should be 200
                
                if httpResponse.statusCode != 200 {
                    print("❌ SERVER ERROR: Code \(httpResponse.statusCode)")
                    // Print what the server actually said (the error message)
                    if let data = data,
                       let responseString = String(data: data, encoding: .utf8)
                    {
                        print("📩 Server Response: \(responseString)")
                    }
                    return
                }
            }
            print("✅ SUCCESS: User Profile created!")
            DispatchQueue.main.async {
                self.userIsLoggedIn = true
            }
        }.resume()
        
    }
}

#Preview {
    SignUpView(userIsLoggedIn: .constant(false))
}
