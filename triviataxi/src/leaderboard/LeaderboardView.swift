//
//  LeaderboardView.swift
//  triviataxi
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
    @State private var currentUserID: String? = Auth.auth().currentUser?.uid
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
                    
                    ForEach(leaderboardEntries) { entry in
                    LeaderboardRow(
                        entry: entry,
                       isCurrentUser: entry.firebaseUid == currentUserID
                    )
                }
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 21)
                .padding(.top, 16)
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
    let isCurrentUser: Bool // 🚀 New property
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            Text("#\(entry.rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isCurrentUser ? .black : .secondary)
                .frame(width: 36)
            
            // Name + "YOU" Badge
            HStack {
                Text(entry.username)
                    .font(.system(size: 15, weight: isCurrentUser ? .bold : .semibold))
                
                if isCurrentUser {
                    Text("YOU")
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Miles
            HStack(spacing: 6) {
                Image(systemName: "road.lanes")
                Text(String(format: "%.1f mi", entry.milesTraveled))
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isCurrentUser ? Color.black : Color.accentYellow)
            .foregroundColor(isCurrentUser ? .white : .black)
            .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCurrentUser ? Color.white : Color.white)
            // 🚀 Add a gold border if it's the current user
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isCurrentUser ? Color.black : Color.clear, lineWidth: 2)
                
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
