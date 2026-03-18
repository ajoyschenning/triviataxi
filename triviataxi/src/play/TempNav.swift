//
//  TempNav.swift
//  triviataxi
//

import CoreLocation
import MapboxDirections
import MapboxNavigationCore
import MapboxNavigationUIKit
import SwiftUI

struct NavigationViewControllerRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let sessionId: String

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        calculateRoutes(origin: origin, destination: destination) {
            navigationViewController in
            DispatchQueue.main.async {
                // Add coin counter overlay
                let coinCounter = UILabel()
                coinCounter.text = "1000"
                coinCounter.font = UIFont.systemFont(ofSize: 12, weight: .bold)
                coinCounter.textColor = .black
                coinCounter.backgroundColor = UIColor(
                    red: 1,
                    green: 0.84,
                    blue: 0,
                    alpha: 1
                )
                coinCounter.layer.cornerRadius = 20
                coinCounter.layer.masksToBounds = true
                coinCounter.textAlignment = .center
                coinCounter.translatesAutoresizingMaskIntoConstraints = false

                navigationViewController.navigationView.addSubview(coinCounter)
                NSLayoutConstraint.activate([
                    coinCounter.trailingAnchor.constraint(
                        equalTo: navigationViewController.navigationView
                            .safeAreaLayoutGuide.trailingAnchor,
                        constant: -18
                    ),
                    coinCounter.bottomAnchor.constraint(
                        equalTo: navigationViewController.navigationView
                            .safeAreaLayoutGuide.bottomAnchor,
                        constant: -16
                    ),
                    coinCounter.widthAnchor.constraint(
                        greaterThanOrEqualToConstant: 40
                    ),
                    coinCounter.heightAnchor.constraint(equalToConstant: 40),
                ])
                navigationViewController.navigationView.bringSubviewToFront(
                    coinCounter
                )

                // Add home button to top left
                let homeButton = UIButton(type: .system)
                homeButton.backgroundColor = UIColor(
                    red: 1,
                    green: 0.84,
                    blue: 0,
                    alpha: 1
                )
                homeButton.layer.cornerRadius = 22
                homeButton.layer.masksToBounds = true
                homeButton.translatesAutoresizingMaskIntoConstraints = false
                let houseImage = UIImage(systemName: "house.fill")?
                    .withConfiguration(
                        UIImage.SymbolConfiguration(
                            pointSize: 18,
                            weight: .bold
                        )
                    )
                homeButton.setImage(houseImage, for: .normal)
                homeButton.tintColor = .black
                // Optional: add border
                homeButton.layer.borderColor = UIColor.black.cgColor
                homeButton.layer.borderWidth = 2

                // Add action (dismiss navigation) -- handled below

                navigationViewController.navigationView.addSubview(homeButton)
                NSLayoutConstraint.activate([
                    homeButton.leadingAnchor.constraint(
                        equalTo: navigationViewController.navigationView
                            .safeAreaLayoutGuide.leadingAnchor,
                        constant: 16
                    ),
                    homeButton.topAnchor.constraint(
                        equalTo: navigationViewController.navigationView
                            .safeAreaLayoutGuide.topAnchor,
                        constant: 16
                    ),
                    homeButton.widthAnchor.constraint(equalToConstant: 44),
                    homeButton.heightAnchor.constraint(equalToConstant: 44),
                ])
                navigationViewController.navigationView.bringSubviewToFront(
                    homeButton
                )

                // Add selector for home button using closure
                homeButton.addAction(
                    UIAction(handler: { _ in
                        navigationViewController.dismiss(
                            animated: true,
                            completion: nil
                        )
                    }),
                    for: .touchUpInside
                )

                viewController.present(
                    navigationViewController,
                    animated: true,
                    completion: nil
                )
            }
        }
        return viewController
    }

    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: Context
    ) {
        // No updates needed at this point
    }

    @MainActor private func calculateRoutes(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        completion: @escaping (NavigationViewController) -> Void
    ) {
        let mapboxNavigationProvider = MapboxNavigationProvider(
            coreConfig: .init(
                locationSource: .simulation()
            )
        )
        let mapboxNavigation = mapboxNavigationProvider.mapboxNavigation
        let options = NavigationRouteOptions(coordinates: [origin, destination])
        let request = mapboxNavigation.routingProvider().calculateRoutes(
            options: options
        )
        Task {
            switch await request.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let navigationRoutes):

                let navigationOptions = NavigationOptions(
                    mapboxNavigation: mapboxNavigation,
                    voiceController: mapboxNavigationProvider
                        .routeVoiceController,
                    eventsManager: mapboxNavigationProvider.eventsManager()
                )
                let navigationViewController = NavigationViewController(
                    navigationRoutes: navigationRoutes,
                    navigationOptions: navigationOptions
                )

                navigationViewController.showsSpeedLimits = false
                navigationViewController.modalPresentationStyle = .fullScreen
                navigationViewController.navigationView.topBannerContainerView
                    .isHidden = true
                navigationViewController.navigationView.floatingStackView
                    .isHidden = true
                navigationViewController.routeLineTracksTraversal = true
                completion(navigationViewController)
            }
        }
    }
}
