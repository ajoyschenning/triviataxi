//
//  TempNav.swift
//  triviataxi
//
//  Created by Alex Joy Schenning on 2/2/26.
//

import CoreLocation
import SwiftUI
import MapboxDirections
import MapboxNavigationCore
import MapboxNavigationUIKit




// MARK: NavigationViewController UI
struct NavigationViewControllerRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController() // Placeholder UIViewController for now
        
        calculateRoutes { navigationViewController in
            DispatchQueue.main.async {
                // display the NavigationViewController
                viewController.present(navigationViewController, animated: true, completion: nil)
            }
        }
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed at this point
    }
    
    @MainActor private func calculateRoutes(completion: @escaping (NavigationViewController) -> Void) {
        
        // create a new navigation provider using simulated device location
        let mapboxNavigationProvider = MapboxNavigationProvider(
            coreConfig: .init(
                locationSource: .simulation() // replace with .live to use the device's location
            )
        )
        
        let mapboxNavigation = mapboxNavigationProvider.mapboxNavigation
        
        // set up navigation by specifying origin and destination coordinates
        let origin = CLLocationCoordinate2DMake(36.08555, -86.48548)
        let destination = CLLocationCoordinate2DMake(36.09439, -86.46279)
        let options = NavigationRouteOptions(coordinates: [origin, destination])

        // create the navigation request
        let request = mapboxNavigation.routingProvider().calculateRoutes(options: options)
        
        Task {
            switch await request.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let navigationRoutes):
                
                // set up options for NavigationViewController
                let navigationOptions = NavigationOptions(
                    mapboxNavigation: mapboxNavigation,
                    voiceController: mapboxNavigationProvider.routeVoiceController,
                    eventsManager: mapboxNavigationProvider.eventsManager()
                )
                
                // create the NavigationViewController, combining the returned routes and the options defined above
                let navigationViewController = NavigationViewController(
                    navigationRoutes: navigationRoutes,
                    navigationOptions: navigationOptions
                )
                
                // set additional options on the NavigationViewController
                navigationViewController.modalPresentationStyle = .fullScreen
                // Render part of the route that has been traversed with full transparency, to give the illusion of a disappearing route.
                navigationViewController.routeLineTracksTraversal = true
                
                // Return the navigation view controller in the completion handler
                completion(navigationViewController)
            }
        }
    }
}
