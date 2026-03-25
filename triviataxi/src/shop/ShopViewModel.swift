//
//  ShopViewModel.swift
//  triviataxi
//

internal import Combine
import Foundation
import SwiftUI

@MainActor
class ShopViewModel: ObservableObject {
    struct DestinationItem: Identifiable {
        let id: String
        let city: String
        let miles: String
        let price: Int
        let imageUrl: String?
    }

    @Published var destinations: [DestinationItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var purchasingItemId: String? = nil
    @Published var lastPurchaseError: String? = nil


    func load(userManager: UserManager) async {
        isLoading = true
        errorMessage = nil

        

        do {
            let responses = try await NetworkService.shared.fetchDestinations()

            // Try fetch owned ids; if it fails, assume none owned to avoid blocking shop access
            let ownedIds = userManager.ownedDestinations.map { $0.id }
            
            let items = responses
                            .filter { !ownedIds.contains($0.id) }
                            .map { resp in
                                DestinationItem(
                                    id: resp.id,
                                    city: resp.city,
                                    miles: resp.miles ?? "",
                                    price: resp.price,
                                    imageUrl: resp.imageUrl
                                )
                            }
                            .sorted { $0.price < $1.price }
                        
                        destinations = items


            // Map responses to items, filter out owned, and sort by price ascending
          
    

       
            
        } catch {
            errorMessage = "Failed to load"
            print("Error loading destinations: \(error)")
        }

        isLoading = false
    }

    func purchase(_ item: DestinationItem, userManager: UserManager) async {
        guard let userId = userManager.currentUserId else {
            lastPurchaseError = "User not authenticated"
            return
        }

        purchasingItemId = item.id
        lastPurchaseError = nil

        do {
            let response = try await NetworkService.shared.purchaseDestination(
                userId: userId,
                destinationId: item.id
            )

            if response.success {
                // Update coin balance from server response
                if let newBalance = response.newCoinBalance {
                                    userManager.coins = newBalance
                                }
                // Remove item locally so it disappears from shop
                destinations.removeAll { $0.id == item.id }
                await userManager.loadUserProfile()
            } else {
                // Server returned success: false
                lastPurchaseError =
                    response.message.isEmpty
                    ? "Purchase failed. Please try again." : response.message
            }
        } catch {
            print("Purchase failed: \(error)")
            lastPurchaseError =
                "Failed to complete purchase. Please check your connection."
        }

        purchasingItemId = nil
    }
}
