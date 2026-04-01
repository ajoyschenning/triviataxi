//
//  LeaderboardView.swift
//  triviataxi
//
//  Created by Alex Joy Schenning on 2/2/26.
//

import SwiftUI
import MapboxMaps
internal import Combine
import FirebaseAuth


// MARK: Leaderboard
enum LeaderboardTab {

    case week

    case allTime

}

struct LeaderboardView: View {
    @Binding var showLeaderboard: Bool
    @State private var selectedTab: LeaderboardTab = .allTime // Default to allTime since we built that first
    @State private var leaderboardEntries: [LeaderboardEntry] = []
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            Header(title: "LEADERBOARD") {
                showLeaderboard = false
            }

            LeaderboardTabs(selectedTab: $selectedTab)

            if isLoading {
                ProgressView("Loading Drivers...")
                    .padding()
            }

            ScrollView {
                VStack(spacing: 16) {
                    // 🚀 Filter the data based on the selected tab
                    ForEach(leaderboardEntries.filter { $0.timeframe == selectedTab.toNetworkType }) { entry in
                        LeaderboardRow(entry: entry)
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 21)
                .padding(.top, 16)
            }
        }
        .background(Color.backgroundYellow)
        .task {
            await loadLeaderboard()
        }
    }

    private func loadLeaderboard() async {
        isLoading = true
        do {
            // 🚀 Use the NetworkService we just fixed
            let token = try await Auth.auth().currentUser?.getIDToken() ?? ""
            self.leaderboardEntries = try await NetworkService.shared.fetchLeaderboard(token: token)
        } catch {
            print("🚨 Failed to load leaderboard: \(error)")
        }
        isLoading = false
    }
}
extension LeaderboardTab {
    var toNetworkType: LeaderboardTimeframe {
        switch self {
        case .week: return .weekly
        case .allTime: return .allTime
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 16) {
            Text("#\(entry.rank)")
                .font(.system(size: 14, weight: .bold))
                .frame(width: 36)

            Text(entry.username)
                .font(.system(size: 15, weight: .semibold))

            Spacer()

            HStack(spacing: 6) {
                // 🚀 Swapped dollar sign for road icon
                Image(systemName: "road.lanes")
                Text(String(format: "%.1f mi", entry.milesTraveled)) // 🚀 1 decimal place
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentYellow)
            .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(
                    color: Color.shadow,
                    radius: 12,
                    y: 4
                )
        )
    }
}


struct LeaderboardTabs: View {
    @Binding var selectedTab: LeaderboardTab

    var body: some View {
        HStack(spacing: 12) {
            tabButton(title: "THIS WEEK", tab: .week)
            tabButton(title: "ALL TIME", tab: .allTime)
        }
        .padding(.horizontal, 21)
        .padding(.bottom, 12)
    }

    private func tabButton(title: String, tab: LeaderboardTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(selectedTab == tab ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    selectedTab == tab
                    ? Color.black
                    : Color.accentYellow
                )
                .cornerRadius(10)
        }
    }
}

extension LeaderboardView {
    func data(for tab: LeaderboardTab) -> [LeaderboardEntry] {
        switch tab {
        case .week:
            return [
                
            ]

        case .allTime:
            return [
                
            ]
        }
    }
}

#Preview {
    LeaderboardView(showLeaderboard: .constant(true))
}
