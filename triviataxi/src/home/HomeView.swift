//
//  HomeView.swift
//  triviataxi
//
//  Created by Alex Joy Schenning on 2/2/26.
//

import SwiftUI
import MapboxMaps
internal import Combine

// MARK: Dollar Rain
struct DollarRainBackground: View {
    let backgroundColor = Color(hex: "#FFECA1")
    let dollarColor = Color(hex: "#FFD700")

    @State private var animate = false
    private let dollarCount = 40

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                ForEach(0..<dollarCount, id: \.self) { index in
                    let x = CGFloat.random(in: 0...geo.size.width)
                    let size = CGFloat.random(in: 18...34)
                    let duration = Double.random(in: 4...9)
                    let delay = Double.random(in: 0...5)

                    Text("$")
                        .font(.system(size: size, weight: .bold))
                        .foregroundColor(dollarColor)
                        .position(x: x, y: -100)
                        .offset(y: animate ? geo.size.height + 100 : 0)
                        .animation(
                            .linear(duration: duration)
                                .delay(delay)
                                .repeatForever(autoreverses: false),
                            value: animate
                        )
                }
            }
            .onAppear {
                animate = true
            }
        }
    }
}


// MARK: - Gradient Background
struct GoldFadeOverlay: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#FFD700"),
                Color(hex: "#FFD700").opacity(0.0),
                Color(hex: "#FFD700").opacity(0.0),
                Color(hex: "#FFD700").opacity(0.0),
                Color(hex: "#FFD700").opacity(0.0),
                Color(hex: "#FFD700").opacity(0.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}




// MARK: - Fancy Button
struct FancyButton: View {
    let title: String
    let action: () -> Void

    @State private var pressed = false
    @State private var coins: [Coin] = []
    
    // TODO: fix padding on double outline

    var body: some View {
        ZStack {
            // Coins
            ForEach(coins) { coin in
                ZStack {
                    Circle()
                        .fill(Color.yellow)
                    Text("$")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.black)
                }
                .frame(width: 14, height: 14)
                .offset(coin.offset)
                .rotationEffect(.degrees(coin.rotation))
                .opacity(coin.opacity)
            }

            Button(action: {
                pressedAnimation()
                action()
            }) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .kerning(1.2)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.black)

                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white, lineWidth: 3)
                        .padding(4)
                }
            )
            .scaleEffect(pressed ? 0.96 : 1)
            .offset(y: pressed ? 3 : 0)
            .shadow(color: .black.opacity(0.25), radius: 6, y: 6)
        }
    }

    private func pressedAnimation() {
        pressed = true
        spawnCoins()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            pressed = false
        }
    }

    private func spawnCoins() {
        coins = (0..<18).map { _ in
            Coin(
                offset: .zero,
                velocity: CGSize(
                    width: CGFloat.random(in: -200...200),   // horizontal speed
                    height: CGFloat.random(in: -200...200)   // vertical speed
                ),
                rotation: Double.random(in: -30...30),      // small rotation for visual flair
                opacity: 1
            )
        }

        for index in coins.indices {
            // Burst out in straight lines immediately
            withAnimation(.linear(duration: 1)) {
                coins[index].offset.width += coins[index].velocity.width
                coins[index].offset.height += coins[index].velocity.height
                // Keep small rotation only; don't rotate dynamically
            }

            // Start fading after 0.5 second delay
            withAnimation(.linear(duration: 0.25).delay(0.6)) {
                coins[index].opacity = 0
            }
        }
    }

}

struct Coin: Identifiable {
    let id = UUID()
    var offset: CGSize
    var velocity: CGSize
    var rotation: Double
    var opacity: Double = 1
}
