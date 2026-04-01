//
//  EndSummary.swift
//  triviataxi
//

import SwiftUI

struct EndSummary: View {
//    @EnvironmentObject var gameManager: GameManager
//    @EnvironmentObject var userManager: UserManager
//    @EnvironmentObject var navigationManager: NavigationManager
    
    let cityName: String
    let routeLength: String // "short", "medium", or "long"
    let milesTraveled: Double
    let timeElapsed: Int
    let questionsAnswered: Int
    let earnings: Int
    let strikes: Int
    
    var body: some View {
        ZStack {
            // Background with overlays
            DollarRainBackground()
            GoldFadeOverlay()
            
            VStack(spacing: 25) {
                // Title section
                VStack(spacing: 8) {
                    Text("SUMMARY")
                        .font(.system(size: 60, weight: .bold).italic())
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
                    Text("\(cityName.uppercased()) - \(routeLength.uppercased())")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 75)
                .padding(.bottom, 20)
                
//                // Stats section
//                VStack(spacing: 20) {
//                    StatRow(label: "Miles Travelled", value: String(format: "%.1f", gameManager.milesTravelled))
//                    StatRow(label: "Time", value: formatTime(gameManager.timeElapsed))
//                    StatRow(label: "Questions Answered", value: "\(gameManager.questionsAnswered)")
//                    StatRow(label: "Coins Earned", value: "\(Int(gameManager.earnings))")
//                    StatRow(label: "Strikes", value: "\(gameManager.strikes)")
//                }
                // Stats section
                 VStack(spacing: 40) {
                    StatRow(label: "Miles Traveled", value: String(format: "%.1f", milesTraveled))
                     StatRow(label: "Time", value: formatTime(timeElapsed))
                     StatRow(label: "Questions Answered", value: "\(questionsAnswered)")
                     StatRow(label: "Coins Earned", value: "\(Int(earnings))")
                     StatRow(label: "Strikes", value: "\(strikes)")
                 }
                 .padding(.horizontal, 20)
                 .padding(.vertical, 30)
                 .background(Color.white.opacity(0.7))
                 .cornerRadius(16)
                 .padding(.horizontal, 20)
                
//                Spacer()
                
                // Buttons section
                VStack(spacing: 12) {
                    FancyButton(
                        title: "Ride Again?",
                        action: {
//                            navigationManager.navigateTo(.selectRoute)
                        }
                    )
                    
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
        }
    }
}

#Preview {
//    EndSummary(cityName: "Nashville", routeLength: "long")
//        .environmentObject(GameManager())
//        .environmentObject(UserManager())
//        .environmentObject(NavigationManager())
}

