//
//  TempNav.swift
//  triviataxi
//

import CoreLocation
import MapboxDirections
import MapboxNavigationCore
import MapboxNavigationUIKit
import SwiftUI


@MainActor
final class NavigationManager {
    static let shared = NavigationManager()
    let provider = MapboxNavigationProvider(coreConfig: .init(locationSource: .simulation()))
    private init() {}
}
struct NavigationViewControllerRepresentable: UIViewControllerRepresentable {
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let destinationId: String
    let questions: [Question]?
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var userManager: UserManager
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = UIColor(Color.backgroundYellow)
        
        // Set the route/session id once the view controller is being created
        self.gameManager.setRouteId(routeId: destinationId)
        
        
        calculateRoutes(origin: origin, destination: destination) { navVC in
                    DispatchQueue.main.async {
                        
                        // 1. SAFELY UNWRAP (From the bottom block)
                        guard let navigationViewController = navVC else {
                            self.dismiss() // If route fails, instantly exit back to SwiftUI
                            return
                        }
                        
                        // 2. ASSIGN DELEGATE FOR THE BACK BUTTON (From the bottom block)
                        navigationViewController.delegate = context.coordinator

                        // 3. ADD QUESTION OVERLAY (From the top block)
                        if let questions = questions, !questions.isEmpty {
                            let questionOverlay = UIHostingController(
                                rootView: QuestionOverlayView(questions: questions, destinationId: destinationId)
                            )
                            questionOverlay.view.backgroundColor = .clear
                            questionOverlay.view.translatesAutoresizingMaskIntoConstraints = false
                            
                            navigationViewController.navigationView.addSubview(questionOverlay.view)
                            NSLayoutConstraint.activate([
                                questionOverlay.view.topAnchor.constraint(
                                    equalTo: navigationViewController.navigationView.topAnchor
                                ),
                                questionOverlay.view.leadingAnchor.constraint(
                                    equalTo: navigationViewController.navigationView.leadingAnchor
                                ),
                                questionOverlay.view.trailingAnchor.constraint(
                                    equalTo: navigationViewController.navigationView.trailingAnchor
                                ),
                                questionOverlay.view.bottomAnchor.constraint(
                                    equalTo: navigationViewController.navigationView.bottomAnchor
                                ),
                            ])
                            navigationViewController.navigationView.bringSubviewToFront(questionOverlay.view)
                        }
                        
                        // --- Coin Counter UI ---
                let coinCounter = UILabel()
                coinCounter.text = "1000" // Note: You can pass your UserManager in here later!
                coinCounter.font = UIFont.systemFont(ofSize: 12, weight: .bold)
                coinCounter.textColor = .black
                coinCounter.backgroundColor = UIColor(red: 1, green: 0.84, blue: 0, alpha: 1)
                coinCounter.layer.cornerRadius = 20
                coinCounter.layer.masksToBounds = true
                coinCounter.textAlignment = .center
                coinCounter.translatesAutoresizingMaskIntoConstraints = false

                navigationViewController.navigationView.addSubview(coinCounter)
                NSLayoutConstraint.activate([
                    coinCounter.trailingAnchor.constraint(equalTo: navigationViewController.navigationView.safeAreaLayoutGuide.trailingAnchor, constant: -18),
                    coinCounter.bottomAnchor.constraint(equalTo: navigationViewController.navigationView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                    coinCounter.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
                    coinCounter.heightAnchor.constraint(equalToConstant: 40),
                ])
                navigationViewController.navigationView.bringSubviewToFront(coinCounter)

                // --- Native Clear Circle Back Button UI ---
                                let backButton = UIButton(type: .system)
                                backButton.translatesAutoresizingMaskIntoConstraints = false

                                // Use modern iOS Button Configuration for the native frosted glass circle
                                var config = UIButton.Configuration.plain()
                                config.image = UIImage(systemName: "chevron.left")?
                                    .withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))
                                config.baseForegroundColor = .black
                                
                                // 🚀 This applies the exact Apple native frosted glass "clear" effect
                                config.background.visualEffect = UIBlurEffect(style: .systemThickMaterial)
                                config.cornerStyle = .capsule
                                
                                backButton.configuration = config

                                navigationViewController.navigationView.addSubview(backButton)
                                
                                // Pin it to the top left with equal width/height to make a perfect circle
                                NSLayoutConstraint.activate([
                                    backButton.leadingAnchor.constraint(equalTo: navigationViewController.navigationView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
                                    backButton.topAnchor.constraint(equalTo: navigationViewController.navigationView.safeAreaLayoutGuide.topAnchor, constant: 16),
                                    backButton.widthAnchor.constraint(equalToConstant: 36),
                                    backButton.heightAnchor.constraint(equalToConstant: 36)
                                ])
                                navigationViewController.navigationView.bringSubviewToFront(backButton)

                // 🚀 The Bridge
                                backButton.addAction(
                                    UIAction(handler: { _ in
                                        
                                        // 2. THE FIX: Tell the Brain to end the game and save the data!
                                        self.gameManager.quitSessionEarly(userManager: userManager)
                                        
                                        // 3. Slide the map away
                                        navigationViewController.dismiss(animated: true) {
                                            self.dismiss()
                                        }
                                    }),
                                    for: .touchUpInside
                                )
                
                viewController.present(navigationViewController, animated: true, completion: nil)
            }
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    // MARK: - Mapbox Routing (Using Singleton)
    @MainActor private func calculateRoutes(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        completion: @escaping (NavigationViewController?) -> Void
    ) {
        let provider = NavigationManager.shared.provider
        let mapboxNavigation = provider.mapboxNavigation
        
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        let request = mapboxNavigation.routingProvider().calculateRoutes(options: options)
        
        Task {
            switch await request.result {
            case .failure(let error):
                print("🚨 Mapbox Route Error: \(error.localizedDescription)")
                completion(nil)
            case .success(let navigationRoutes):
                let navigationOptions = NavigationOptions(
                    mapboxNavigation: mapboxNavigation,
                    voiceController: provider.routeVoiceController,
                    eventsManager: provider.eventsManager()
                )
                let navigationViewController = NavigationViewController(
                    navigationRoutes: navigationRoutes,
                    navigationOptions: navigationOptions
                )

                navigationViewController.showsSpeedLimits = false
                navigationViewController.modalPresentationStyle = .fullScreen
                navigationViewController.navigationView.topBannerContainerView.isHidden = true
                navigationViewController.navigationView.floatingStackView.isHidden = true
                navigationViewController.routeLineTracksTraversal = true
                
                completion(navigationViewController)
            }
        }
    }
    

    class Coordinator: NSObject, NavigationViewControllerDelegate {
        var parent: NavigationViewControllerRepresentable

        init(_ parent: NavigationViewControllerRepresentable) {
            self.parent = parent
        }

        func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
            parent.dismiss()
        }
    }
}

