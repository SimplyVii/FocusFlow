//
//  TimerProgressRing.swift
//  FocusFlow
//
//  Created by Vivi on 07.03.26.
//

import SwiftUI

struct TimerProgressRing: View {
    let progress: Double   // 0.0 ... 1.0
    let ringColor: Color
    let isRunning: Bool

    @State private var glowPulse = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color(.secondarySystemBackground),
                    style: StrokeStyle(lineWidth: 10)
                )

            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .scaleEffect(x: -1, y: 1)
                .shadow(
                    color: ringColor.opacity(isRunning ? (glowPulse ? 0.30 : 0.16) : 0.08),
                    radius: isRunning ? (glowPulse ? 12 : 6) : 2,
                    x: 0,
                    y: 0
                )
                .animation(.easeInOut(duration: 0.35), value: progress)
                .animation(.easeInOut(duration: 0.25), value: isRunning)
                .animation(.easeInOut(duration: 0.25), value: ringColor)
        }
        .onAppear {
            updateGlowAnimation()
        }
        .onChange(of: isRunning) { _ in
            updateGlowAnimation()
        }
    }

    private func updateGlowAnimation() {
        if isRunning {
            glowPulse = false
            withAnimation(
                .easeInOut(duration: 1.35)
                    .repeatForever(autoreverses: true)
            ) {
                glowPulse = true
            }
        } else {
            glowPulse = false
        }
    }
}
