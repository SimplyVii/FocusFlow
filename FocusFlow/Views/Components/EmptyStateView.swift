//
//  EmptyStateView.swift
//  FocusFlow
//
//  Created by Vivi on 06.03.26.
//

import SwiftUI

struct EmptyStateView: View {
    let onStartFocus: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text("No sessions yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start a Focus session to create your first entry. Your completed sessions will appear here automatically.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                onStartFocus()
            } label: {
                Text("Start a Focus Session")
                    .frame(maxWidth: 320)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 6)

            Spacer()
        }
        .padding()
    }
}
