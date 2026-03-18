//
//  SelectRoute.swift
//  triviataxi
//
//  Created by Alex Joy Schenning on 2/11/26.
//


import SwiftUI
import MapboxMaps
import MapboxDirections
import MapboxNavigationCore
import MapboxNavigationUIKit
import CoreLocation
internal import Combine
import FirebaseAuth



struct RouteSelectionView: View {
    @Binding var showRoutes: Bool
    @State private var showNavigation = false
    @State private var selectedOrigin: CLLocationCoordinate2D? = nil
    @State private var selectedDestination: CLLocationCoordinate2D? = nil
    @State private var ownedDestinations: [DestinationResponse] = []
    @State private var isLoadingDestinations = false

    var body: some View {
        ZStack {

            Color.backgroundYellow
                .ignoresSafeArea()
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
                        if isLoadingDestinations {
                            ProgressView()
                                .padding()
                        } else if ownedDestinations.isEmpty {
                            Text("No destinations owned")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(ownedDestinations, id: \.id) { destination in
                                RouteCard(
                                    journeyID: destination.id,
                                    city: destination.city,
                                    imageUrl: destination.imageUrl,
                                    onDifficultySelected: { difficulty in
                                        fetchRouteCoordinates(destinationId: destination.id, difficulty: difficulty)
                                    }
                                )
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 21)
                }
                .onAppear {
                    fetchOwnedDestinations()
                }
            }
        }
        .fullScreenCover(isPresented: $showNavigation) {
            if let origin = selectedOrigin, let destination = selectedDestination {
                NavigationViewControllerRepresentable(origin: origin, destination: destination)
                    .edgesIgnoringSafeArea(.all)
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


enum RouteDifficulty: String {
    case short, medium, long
}

struct RouteCard: View {
    @State private var showNavigation = false
    @State private var isProcessing = false
    
    let journeyID: String
    
    let city: String
    let imageUrl: String?
    let onDifficultySelected: (RouteDifficulty) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(
                    color: Color(red: 0.71, green: 0.74, blue: 0.79, opacity: 0.14),
                    radius: 20,
                    y: 6
                )

            HStack(spacing: 16) {

                // Image (from URL if available)
                if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.3))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.3))
                        @unknown default:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(width: 95, height: 116)
                    .clipped()
                    .cornerRadius(16)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.5))
                        .frame(width: 95, height: 116)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(city)
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    HStack(spacing: 8) {
                        difficultyButton(title: "SHORT", difficulty: .short)
                        difficultyButton(title: "MEDIUM", difficulty: .medium)
                        difficultyButton(title: "LONG", difficulty: .long)
                    }
                    .frame(height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Spacer()
            }
            .padding()
        }
        .frame(height: 140)
    }

    private func difficultyButton(title: String, difficulty: RouteDifficulty) -> some View {
        Button(action: {
            onDifficultySelected(difficulty)
            startRoute(journeyID: journeyID)
        }) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .cornerRadius(10)
        }
    }
    
    private func startRoute(journeyID: String) {
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
                let session = try await NetworkService.shared.createSession(
                    journeyId: journeyID,
                    token: token
                )
                
                // 4. Update UI state on the Main Thread to trigger navigation
                await MainActor.run {
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

extension RouteSelectionView {
    private func fetchOwnedDestinations() {
        isLoadingDestinations = true
        Task {
            do {
                guard let user = Auth.auth().currentUser else {
                    print("🚨 Error: No user logged in")
                    await MainActor.run { isLoadingDestinations = false }
                    return
                }

                let token = try await user.getIDToken()
                let userProfile = try await NetworkService.shared.fetchUserProfile(token: token)
                
                var destinations: [DestinationResponse] = []
                for destinationId in userProfile.owned ?? [] {
                    let destination = try await NetworkService.shared.fetchDestination(id: destinationId, token: token)
                    destinations.append(destination)
                }

                await MainActor.run {
                    self.ownedDestinations = destinations
                    isLoadingDestinations = false
                }
            } catch {
                print("🚨 Error fetching owned destinations: \(error)")
                await MainActor.run { isLoadingDestinations = false }
            }
        }
    }

    private func fetchRouteCoordinates(destinationId: String, difficulty: RouteDifficulty) {
        Task {
            do {
                guard let user = Auth.auth().currentUser else {
                    print("🚨 Error: No user logged in")
                    return
                }

                let token = try await user.getIDToken()
                let coords = try await NetworkService.shared.fetchRouteCoordinates(
                    destinationId: destinationId,
                    difficulty: difficulty.rawValue,
                    token: token
                )
                
                await MainActor.run {
                    selectedOrigin = CLLocationCoordinate2D(
                        latitude: coords.originLat,
                        longitude: coords.originLng
                    )
                    selectedDestination = CLLocationCoordinate2D(
                        latitude: coords.destinationLat,
                        longitude: coords.destinationLng
                    )
                    print(selectedOrigin)
                    print(selectedDestination)
                    showNavigation = true
                }
            } catch {
                print("🚨 Error fetching route coordinates: \(error)")
            }
        }
    }
}


#Preview {
    RouteSelectionView(showRoutes: .constant(false))
}
