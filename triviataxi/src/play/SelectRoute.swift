//
//  SelectRoute.swift
//  triviataxi
//
//  Created by Alex Joy Schenning on 2/11/26.
//


import SwiftUI
import MapboxMaps
internal import Combine
import FirebaseAuth


struct RouteSelectionView: View {
    @Binding var showRoutes: Bool

    var body: some View {
        ZStack {

            // 🟡 Base Yellow Background
            Color.backgroundYellow
                .ignoresSafeArea()

            // ✨ Gold Fade Overlay
            GoldFadeOverlay()
            .ignoresSafeArea()
            .blendMode(.overlay)

            VStack(spacing: 0) {

                // 🔒 Static Header
                Header(title: "SELECT CITY") {
                    showRoutes = false
                }

                // 📜 Scrollable Cities
                ScrollView {
                    VStack(spacing: 28) {

//                        Text("SELECT CITY")
//                            .font(.system(size: 32, weight: .semibold))
//                            .italic()
//                            .foregroundColor(.black)
//                            .padding(.top, 24)

                        RouteCard(journeyID: "100", city: "New York").padding(.top, 24)
                        //RouteCard(city: "Washington DC")
                        //RouteCard(city: "Miami")
                        //RouteCard(city: "Boston")
                        //RouteCard(city: "Paris")

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 21)
                }
            }
        }
    }
}



//struct RouteHeader: View {
//    let onHomeTapped: () -> Void
//
//    var body: some View {
//        ZStack {
//
//            Button(action: onHomeTapped) {
//                Circle()
//                    .fill(Color(red: 1, green: 0.84, blue: 0))
//                    .frame(width: 44, height: 44)
//                    .overlay(
//                        Image(systemName: "house.fill")
//                            .font(.system(size: 18, weight: .bold))
//                            .foregroundColor(.black)
//                    )
//            }
//            .offset(x: -150)
//
//            Text("SELECT CITY")
//                .font(.system(size: 32, weight: .semibold))
//                .italic()
//                .foregroundColor(.black)
//
//            HStack(spacing: 6) {
//                Image(systemName: "dollarsign.circle.fill")
//                    .foregroundColor(.black)
//
//                Text("1000")
//                    .font(.system(size: 15, weight: .semibold))
//            }
//            .offset(x: 150)
//        }
//        .frame(height: 44)
//        .padding(.top, 34)
//        .padding(.bottom, 12)
////        .background(Color(red: 1, green: 0.98, blue: 0.80))
//    }
//}

struct RouteCard: View {
    @State private var showNavigation = false
    @State private var isProcessing = false
    
    let journeyID: String
    
    let city: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(
                    color: Color(red: 0.71, green: 0.74, blue: 0.79, opacity: 0.14),
                    radius: 20,
                    y: 6
                )

            VStack(spacing: 16) {

                // City Title
                Text(city)
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Full-width Equal Buttons
                HStack(spacing: 8) {
                    difficultyButton(title: "SHORT")
                    difficultyButton(title: "MEDIUM")
                    difficultyButton(title: "LONG")
                }
                .frame(height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
        .frame(height: 140)
    }

    private func difficultyButton(title: String) -> some View {
        Button(action: {
            // TODO: start route
            startRoute()
            showNavigation = true
        }) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .cornerRadius(10)
        }
    }
    
    private func startRoute() {
        print("hello")
        // 1. Prevent duplicate taps while the request is loading
        isProcessing = true
        
        Task {
            do {
                // 2. Fetch the current Firebase user and their ID Token
                guard let user = Auth.auth().currentUser else {
                    print("🚨 Error: No user logged in. Cannot fetch token.")
                    await MainActor.run { isProcessing = false }
                    return
                }
                
                let token = try await user.getIDToken()
                
                // 3. Request the new session from your FastAPI backend
                // Note: Replace 'self.journeyId' with whatever variable stores your city/route ID
                let session = try await NetworkService.shared.createSession(
                    journeyId: self.journeyID,
                    token: token
                )
                
                // 4. Update UI state on the Main Thread to trigger navigation
                await MainActor.run {
                    print("hi")
                    self.isProcessing = false
                    self.showNavigation = true
                }
                
                print("✅ Session Started: \(session.sessionId)")
                
            } catch {
                // 5. Handle errors (Network timeout, 401 Unauthorized, etc.)
                await MainActor.run {
                    print("🚨 API Error: \(error.localizedDescription)")
                    self.isProcessing = false
                }
            }
        }
    }
}


#Preview {
    RouteSelectionView(showRoutes: .constant(false))
}
