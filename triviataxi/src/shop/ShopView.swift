//
//  ShopView.swift
//  triviataxi
//

internal import Combine
import MapboxMaps
import SwiftUI

// MARK: Shop View

struct ShopView: View {
    @Binding var showShop: Bool  // control navigation
    @StateObject private var viewModel = ShopViewModel()
    @EnvironmentObject var userManager: UserManager

    var body: some View {
        VStack(spacing: 0) {

            Header(title: "SHOP") {
                showShop = false
            }

            // Scrollable Destinations
            ScrollView {
                VStack(spacing: 28) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 24)
                    }

                    // Purchase error alert
                    if let error = viewModel.lastPurchaseError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 21)
                        .padding(.top, 8)
                    }

                    ForEach(viewModel.destinations) { item in
                        DestinationCard(
                            id: item.id,
                            city: item.city,
                            miles: item.miles,
                            price: item.price,
                            imageUrl: item.imageUrl,
                            isPurchasing: viewModel.purchasingItemId == item.id,
                            buyAction: {
                                Task { await viewModel.purchase(item, userManager: userManager) }
                            }
                        )
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 21)
                .task {
                    await viewModel.load(userManager: userManager)
                }
            }
        }
        .background(Color.backgroundYellow)
    }
}

struct DestinationCard: View {
    let id: String?
    let city: String
    let miles: String
    let price: Int
    let imageUrl: String?
    let isPurchasing: Bool
    let buyAction: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(
                    color: Color.shadow,
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
                        .fill(
                            Color(red: 0.50, green: 0.23, blue: 0.27).opacity(
                                0.5
                            )
                        )
                        .frame(width: 95, height: 116)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(miles)
                        .font(.system(size: 16))
                        .foregroundColor(.black)

                    Text(city)
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundColor(.black)

                    Spacer()

                    HStack(spacing: 10) {

                        HStack(spacing: 6) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.black)

                            Text("\(price)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentYellow)
                        .cornerRadius(8)

                        Button(action: buyAction) {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .frame(height: 16)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                            } else {
                                Text("BUY NOW")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                            }
                        }
                        .background(Color.black)
                        .cornerRadius(8)
                        .disabled(isPurchasing)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .frame(height: 140)
    }
}

#Preview {
    ShopView(showShop: .constant(true))
}
