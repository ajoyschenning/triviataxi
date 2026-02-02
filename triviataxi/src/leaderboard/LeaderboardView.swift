//
//  LeaderboardView.swift
//  triviataxi
//
//  Created by Alex Joy Schenning on 2/2/26.
//

import SwiftUI
import MapboxMaps
internal import Combine

// MARK: Leaderboard

struct LeaderboardView: View {
    @Binding var showLeaderboard: Bool
    @State private var selectedTab: LeaderboardTab = .week

    var body: some View {
        VStack(spacing: 0) {

            // 🔒 Static Header
            LeaderboardHeader {
                showLeaderboard = false
            }

            // Tabs
            LeaderboardTabs(selectedTab: $selectedTab)

            // Scrollable content
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(data(for: selectedTab)) { entry in
                        LeaderboardRow(entry: entry)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 21)
                .padding(.top, 16)
            }
        }
        .background(Color(red: 1, green: 0.98, blue: 0.80))
        .ignoresSafeArea(edges: .top)
    }
}

enum LeaderboardTab {
    case week
    case allTime
}

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let earnings: Int
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 16) {

            Text("#\(entry.rank)")
                .font(.system(size: 14, weight: .bold))
                .frame(width: 36)

            Text(entry.name)
                .font(.system(size: 15, weight: .semibold))

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                Text("\(entry.earnings)")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(red: 1, green: 0.84, blue: 0))
            .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(
                    color: Color(red: 0.71, green: 0.74, blue: 0.79, opacity: 0.14),
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
                    : Color(red: 1, green: 0.84, blue: 0)
                )
                .cornerRadius(10)
        }
    }
}


struct LeaderboardHeader: View {
    let onHomeTapped: () -> Void

    var body: some View {
        ZStack {
            Button(action: onHomeTapped) {
                Circle()
                    .fill(Color(red: 1, green: 0.84, blue: 0))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "house.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                    )
            }
            .offset(x: -150)

            Text("Leaderboard")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.11, green: 0.12, blue: 0.16))
        }
        .frame(height: 44)
        .padding(.top, 34)
        .padding(.bottom, 12)
        .background(Color(red: 1, green: 0.98, blue: 0.80))
    }
}

extension LeaderboardView {
    func data(for tab: LeaderboardTab) -> [LeaderboardEntry] {
        switch tab {
        case .week:
            return [
                LeaderboardEntry(rank: 1, name: "Alex J.S.", earnings: 1240),
                LeaderboardEntry(rank: 2, name: "Sophia P.", earnings: 980),
                LeaderboardEntry(rank: 3, name: "Jordan K.", earnings: 860),
                LeaderboardEntry(rank: 4, name: "Sam T.", earnings: 740),
                LeaderboardEntry(rank: 5, name: "Taylor P.", earnings: 610)
            ]

        case .allTime:
            return [
                LeaderboardEntry(rank: 1, name: "Chris D.", earnings: 18420),
                LeaderboardEntry(rank: 2, name: "Alex S.", earnings: 16210),
                LeaderboardEntry(rank: 3, name: "Mia R.", earnings: 14980),
                LeaderboardEntry(rank: 4, name: "Jordan K.", earnings: 13240),
                LeaderboardEntry(rank: 5, name: "Sam T.", earnings: 12110)
            ]
        }
    }
}
