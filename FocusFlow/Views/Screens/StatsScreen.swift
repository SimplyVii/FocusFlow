//
//  StatsView.swift
//  FocusFlow
//
//  Created by Vivi on 07.03.26.
//

import SwiftUI
import Charts

struct StatsScreen: View {
    @ObservedObject var vm: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCards

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last 7 Days")
                            .font(.headline)

                        Chart(vm.last7DaysFocusStats) { item in
                            BarMark(
                                x: .value("Day", item.date, unit: .day),
                                y: .value("Minutes", item.minutes)
                            )
                        }
                        .frame(height: 240)

                        Text("Focus minutes completed per day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .padding()
            }
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statCard(
                    title: "Today",
                    value: "\(vm.todayFocusMinutes) min",
                    systemImage: "calendar"
                )

                statCard(
                    title: "Sessions",
                    value: "\(vm.totalFocusSessions)",
                    systemImage: "checkmark.circle"
                )
            }

            statCard(
                title: "Total Focus Minutes",
                value: "\(vm.totalFocusMinutes) min",
                systemImage: "chart.bar"
            )
        }
    }

    private func statCard(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
