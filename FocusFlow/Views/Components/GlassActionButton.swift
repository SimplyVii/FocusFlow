//
//  GlassActionButton.swift
//  FocusFlow
//
//  Created by Vivi on 07.03.26.
//

import SwiftUI

struct GlassActionButton: View {
    let title: String
    let systemImage: String?
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.buttonTap()
            action()
        } label: {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                }

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                ZStack {
                    Capsule()
                        .fill(.ultraThinMaterial)

                    Capsule()
                        .fill(tint.opacity(0.12))

                    Capsule()
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)

                    Capsule()
                        .strokeBorder(tint.opacity(0.18), lineWidth: 1)
                        .blur(radius: 0.4)
                }
            )
            .shadow(color: tint.opacity(0.16), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
