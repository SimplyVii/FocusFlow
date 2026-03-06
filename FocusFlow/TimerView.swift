//
//  TimerView.swift
//  FocusFlow
//
//  Created by Vivi on 06.03.26.
//

import SwiftUI

struct TimerView: View {
    @StateObject private var vm = TimerViewModel()

    var body: some View {
        NavigationStack {
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
                .padding(.top, 4)

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
                .padding(.top, 6)

                List {
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
                .listStyle(.insetGrouped)

            }
            .padding()
            .navigationTitle("FocusFlow")
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
}
