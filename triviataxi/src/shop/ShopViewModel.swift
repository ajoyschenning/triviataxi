import Foundation
import SwiftUI
import FirebaseAuth

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
    @Published var coinBalance: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var purchasingItemId: String? = nil
    @Published var lastPurchaseError: String? = nil

    // Get current user ID from Firebase Auth
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        guard let userId = currentUserId else {
            errorMessage = "User not authenticated"
            isLoading = false
            return
        }

        do {
            let responses = try await NetworkService.shared.fetchDestinations()

            // Try fetch owned ids; if it fails, assume none owned to avoid blocking shop access
            var owned: [String] = []
            do {
                owned = try await NetworkService.shared.fetchOwnedDestinationIDs(for: userId)
            } catch {
                print("Could not fetch owned destinations: \(error)")
            }

            // Map responses to items, filter out owned, and sort by price ascending
            let items = responses
                .filter { !owned.contains($0.id) }
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
        } catch {
            errorMessage = "Failed to load destinations"
            print("Error loading destinations: \(error)")
        }

        isLoading = false
    }

    func purchase(_ item: DestinationItem) async {
        guard let userId = currentUserId else {
            lastPurchaseError = "User not authenticated"
            return
        }

        purchasingItemId = item.id
        lastPurchaseError = nil

        do {
            let response = try await NetworkService.shared.purchaseDestination(userId: userId, destinationId: item.id)

            if response.success {
                // Update coin balance from server response
                if let newBalance = response.newCoinBalance {
                    coinBalance = newBalance
                }
                // Remove item locally so it disappears from shop
                destinations.removeAll { $0.id == item.id }
            } else {
                // Server returned success: false
                lastPurchaseError = response.message.isEmpty ? "Purchase failed. Please try again." : response.message
            }
        } catch {
            print("Purchase failed: \(error)")
            lastPurchaseError = "Failed to complete purchase. Please check your connection."
        }

        purchasingItemId = nil
    }
}
