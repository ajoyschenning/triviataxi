//
//  SelectRoute.swift
//  triviataxi
//

internal import Combine
import CoreLocation
import FirebaseAuth
import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import SwiftUI

enum RouteDifficulty: String {
    case short, medium, long
}

struct RouteSelectionView: View {
    @Binding var showRoutes: Bool

    @State private var showNavigation = false
    @State private var selectedOrigin: CLLocationCoordinate2D? = nil
    @State private var selectedDestination: CLLocationCoordinate2D? = nil
    @State private var destinationId: String? = nil

    @State private var ownedDestinations: [DestinationData] = []
    @State private var isLoadingDestinations = false

    var body: some View {
        ZStack {
            Color.backgroundYellow
                .ignoresSafeArea()
            GoldFadeOverlay()
                .ignoresSafeArea()
                .blendMode(.overlay)

            VStack(spacing: 0) {
                Header(title: "SELECT CITY") {
                    showRoutes = false
                }

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
                            ForEach(ownedDestinations, id: \.id) {
                                destination in
                                RouteCard(
                                    journeyID: destination.id,
                                    city: destination.city,
                                    onDifficultySelected: { difficulty in
                                        await prepareJourney(
                                            destinationId: destination.id,
                                            difficulty: difficulty
                                        )
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
        .navigationDestination(isPresented: $showNavigation) {
            if let origin = selectedOrigin,
                let destination = selectedDestination,
                let destinationId = destinationId
            {

                NavigationViewControllerRepresentable(
                    origin: origin,
                    destination: destination,
                    destinationId: destinationId
                )
                .edgesIgnoringSafeArea(.all)
                // Hides the default iOS back button so your custom Mapbox UI takes over
                //  .navigationBarBackButtonHidden(true)
            }
        }
    }
}

// MARK: - API Logic
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
                let userProfile = try await NetworkService.shared
                    .fetchUserProfile(token: token)

                var destinations: [DestinationData] = []
                for destinationId in userProfile.owned ?? [] {
                    let destination = try await NetworkService.shared
                        .fetchDestination(id: destinationId, token: token)
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

    private func prepareJourney(
        destinationId: String,
        difficulty: RouteDifficulty
    ) async {
        do {
            guard let user = Auth.auth().currentUser else {
                print("🚨 Error: No user logged in")
                return
            }
            let token = try await user.getIDToken()

            // 1. Fetch Coordinates
            let coords = try await NetworkService.shared.fetchRouteCoordinates(
                destinationId: destinationId,
                difficulty: difficulty.rawValue,
                token: token
            )



            // 3. Trigger the navigation push ONLY when both are successful
            await MainActor.run {
                self.selectedOrigin = CLLocationCoordinate2D(
                    latitude: coords.originLat,
                    longitude: coords.originLng
                )
                self.selectedDestination = CLLocationCoordinate2D(
                    latitude: coords.destinationLat,
                    longitude: coords.destinationLng
                )
                self.destinationId = destinationId
                self.showNavigation = true
            }
            print("✅ Journey Prepared! Destination: \(destinationId)")

        } catch {
            print("🚨 Journey Preparation Error: \(error)")
        }
    }
}

// MARK: - UI Components
struct RouteCard: View {
    @State private var isProcessing = false

    let journeyID: String
    let city: String
    let onDifficultySelected: (RouteDifficulty) async -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(
                    color: Color(
                        red: 0.71,
                        green: 0.74,
                        blue: 0.79,
                        opacity: 0.14
                    ),
                    radius: 20,
                    y: 6
                )

            VStack(spacing: 16) {
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
            .padding()
        }
        .frame(height: 140)
    }

    private func difficultyButton(title: String, difficulty: RouteDifficulty)
        -> some View
    {
        Button(action: {
            isProcessing = true
            Task {
                await onDifficultySelected(difficulty)
                await MainActor.run { isProcessing = false }
            }
        }) {
            ZStack {
                Color.black
                if isProcessing {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(10)
        }
        .disabled(isProcessing)
    }
}

#Preview {
    RouteSelectionView(showRoutes: .constant(true))
}
