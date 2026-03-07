//
//  TimerView.swift
//  FocusFlow
//
//  Created by Vivi on 06.03.26.
//

import SwiftUI

struct TimerScreen: View {
    @StateObject private var vm = TimerViewModel()
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var isShowingStats = false

    private var selectedNotesBinding: Binding<String> {
        Binding(
            get: { vm.selectedLog?.notes ?? "" },
            set: { vm.updateNotesForSelectedLog($0) }
        )
    }

    var body: some View {
        Group {
            if hSizeClass == .regular {
                splitLayout
            } else {
                phoneLayout
            }
        }
        .sheet(isPresented: $isShowingStats) {
            StatsScreen(vm: vm)
        }
    }

    private var phoneLayout: some View {
        NavigationStack {
            VStack(spacing: 18) {
                timerHeader

                List {
                    historySection
                }
                .listStyle(.insetGrouped)
            }
            .padding()
            .navigationTitle("FocusFlow")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingStats = true
                    } label: {
                        Image(systemName: "chart.bar.xaxis")
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if vm.isDevModeEnabled {
                    Text(AppVersion.displayString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 6)
                        .padding(.bottom, 6)
                        .opacity(0.75)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var splitLayout: some View {
        NavigationSplitView {
            List(selection: $vm.selectedLogID) {
                Section("Today") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(vm.todayFocusMinutes) min focus")
                                .font(.headline)
                            Text("Completed focus time today")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            vm.clearHistory()
                        } label: {
                            Text("Clear")
                        }
                    }
                }

                Section("History") {
                    if vm.history.isEmpty {
                        Text("No sessions yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.history) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.session.rawValue)
                                        .font(.headline)
                                    Text(item.date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(item.minutes) min")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(item.id)
                        }
                        .onDelete(perform: vm.deleteHistory)
                    }
                }
            }
            .navigationTitle("History")
        } detail: {
            NavigationStack {
                VStack(spacing: 0) {
                    timerHeader
                        .padding()

                    Divider()

                    if vm.history.isEmpty {
                        EmptyStateView {
                            vm.selectedSession = .focus
                            vm.reset()
                            vm.start()
                        }
                    } else if vm.selectedLog == nil {
                        ContentUnavailableView(
                            "No Selection",
                            systemImage: "list.bullet.rectangle",
                            description: Text("Select a session on the left to see details.")
                        )
                        .padding()
                    } else {
                        HistoryDetailView(
                            log: vm.selectedLog,
                            notes: selectedNotesBinding
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .navigationTitle("FocusFlow")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingStats = true
                        } label: {
                            Image(systemName: "chart.bar.xaxis")
                        }
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if vm.isDevModeEnabled {
                        Text(AppVersion.displayString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 8)
                            .padding(.bottom, 8)
                            .opacity(0.75)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
    }

    private var timerHeader: some View {
        VStack(spacing: 18) {
            Picker("Session", selection: $vm.selectedSession) {
                ForEach(TimerViewModel.Session.allCases) { session in
                    Text(session.rawValue).tag(session)
                }
            }
            .pickerStyle(.segmented)

            Text(vm.formattedTime())
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
                .padding(.top, 6)

            HStack(spacing: 12) {
                Button {
                    vm.toggleStartPause()
                } label: {
                    Text(vm.isRunning ? "Pause" : "Start")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    vm.reset()
                } label: {
                    Text("Reset")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Toggle(isOn: $vm.isDevModeEnabled) {
                Text("Dev Mode (short timers)")
            }
        }
    }

    @ViewBuilder
    private var historySection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.headline)
                    Text("\(vm.todayFocusMinutes) min focus")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(role: .destructive) {
                    vm.clearHistory()
                } label: {
                    Text("Clear")
                }
            }
        }

        Section("History") {
            if vm.history.isEmpty {
                Text("No sessions yet. Finish a Focus session to log it.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vm.history) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.session.rawValue)
                                .font(.headline)
                            Text(item.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(item.minutes) min")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: vm.deleteHistory)
            }
        }
    }
}
