//
//  SettingsScreen.swift
//  FocusFlow
//
//  Created by Vivi on 09.03.26.
//

import SwiftUI

struct SettingsScreen: View {
    var showsDoneButton: Bool = false
    var onImport: (() -> Void)? = nil
    var onExport: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @AppStorage("settings.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("settings.autoResetEnabled") private var autoResetEnabled = true
    @AppStorage("settings.showVersionWatermark") private var showVersionWatermark = true
    @AppStorage("settings.isDevModeEnabled") private var isDevModeEnabled = true

    @AppStorage("settings.focusMinutes") private var focusMinutes = 25
    @AppStorage("settings.shortBreakMinutes") private var shortBreakMinutes = 5
    @AppStorage("settings.longBreakMinutes") private var longBreakMinutes = 15

    @AppStorage("settings.devFocusSeconds") private var devFocusSeconds = 10
    @AppStorage("settings.devShortBreakSeconds") private var devShortBreakSeconds = 5
    @AppStorage("settings.devLongBreakSeconds") private var devLongBreakSeconds = 8

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                    Toggle("Auto-reset after completion", isOn: $autoResetEnabled)
                    Toggle("Show version watermark", isOn: $showVersionWatermark)
                    Toggle("Dev Mode", isOn: $isDevModeEnabled)
                }

                Section("Standard Durations (minutes)") {
                    Stepper("Focus: \(focusMinutes) min", value: $focusMinutes, in: 1...180)
                    Stepper("Short Break: \(shortBreakMinutes) min", value: $shortBreakMinutes, in: 1...60)
                    Stepper("Long Break: \(longBreakMinutes) min", value: $longBreakMinutes, in: 1...120)
                }

                Section("Dev Durations (seconds)") {
                    Stepper("Focus: \(devFocusSeconds) s", value: $devFocusSeconds, in: 3...120)
                    Stepper("Short Break: \(devShortBreakSeconds) s", value: $devShortBreakSeconds, in: 3...120)
                    Stepper("Long Break: \(devLongBreakSeconds) s", value: $devLongBreakSeconds, in: 3...120)
                }

                if onImport != nil || onExport != nil {
                    Section("Data") {
                        if let onImport {
                            Button {
                                onImport()
                            } label: {
                                Label("Import CSV", systemImage: "square.and.arrow.down")
                            }
                        }

                        if let onExport {
                            Button {
                                onExport()
                            } label: {
                                Label("Export CSV", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                }

                Section {
                    Text("These settings are stored locally on the device and apply immediately.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
