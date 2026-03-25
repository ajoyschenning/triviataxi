//
//  ForgotPasswordView.swift
//  triviataxi
//

import FirebaseAuth
import SwiftUI

struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var isProcessing: Bool = false
    @State private var message: String? = nil
    @State private var isSuccess: Bool = false

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {

            ZStack {

                Color("BackgroundYellow").ignoresSafeArea()
                GoldFadeOverlay()
                ScrollView {

                    VStack(spacing: 30) {

                        Image("taxi")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300)
                            .shadow(
                                color: .black.opacity(0.2),
                                radius: 10,
                                y: 6
                            ).padding(.top, 60)

                        VStack(spacing: 20) {
                            Text("Reset Password")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.black)

                            Text(
                                "Enter the email address associated with your account and we'll send you a link to reset your password."
                            )
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)

                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.gray)
                                TextField("Email Address", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)

                            // 2. Status Message (Error or Success)
                            if let msg = message {
                                Text(msg)
                                    .font(.system(size: 14, weight: .semibold))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)
                            }

                            // 3. Submit Button
                            FancyButton(title: "SEND LINK") {
                                sendResetEmail()
                            }
                            .disabled(email.isEmpty || isProcessing)  // Prevent empty submissions

                        }.padding(25)
                    }
                }
            }
        }
    }

    private func sendResetEmail() {
        // Basic validation
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        isProcessing = true
        message = nil

        // Firebase Auth call
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            // Always update UI on the Main thread
            DispatchQueue.main.async {
                self.isProcessing = false

                if let error = error {
                    self.isSuccess = false
                    self.message = error.localizedDescription
                } else {
                    self.isSuccess = true
                    self.message =
                        "Check your inbox! We sent a reset link to \(self.email)."
                    self.email = ""  // Clear the field on success
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
}
