//
//  TimerViewModel.swift
//  FocusFlow
//
//  Created by Vivi on 06.03.26.
//

import SwiftUI
import Foundation
import Combine

final class TimerViewModel: ObservableObject {

    // MARK: - Session Types

    enum Session: String, CaseIterable, Identifiable, Codable {
        case focus = "Focus"
        case shortBreak = "Short Break"
        case longBreak = "Long Break"

        var id: String { rawValue }
    }

    // MARK: - History Model

    struct SessionLog: Identifiable, Codable {
        let id: UUID
        let date: Date
        let session: Session
        let minutes: Int
    }

    // MARK: - Published State

    @Published var isDevModeEnabled: Bool = true {
        didSet { reset() }
    }

    @Published var selectedSession: Session = .focus {
        didSet { reset() }
    }

    @Published var isRunning: Bool = false
    @Published var remainingSeconds: Int = 0

    @Published private(set) var history: [SessionLog] = []

    // MARK: - Private

    private var timer: AnyCancellable?
    private let historyKey = "FocusFlow.history.v1"

    // MARK: - Init

    init() {
        loadHistory()
        remainingSeconds = durationSeconds(for: selectedSession)
    }

    // MARK: - Durations

    private func durationSeconds(for session: Session) -> Int {
        if isDevModeEnabled {
            // Dev: superschnell testen
            switch session {
            case .focus: return 10
            case .shortBreak: return 5
            case .longBreak: return 8
            }
        } else {
            // Realistisch
            switch session {
            case .focus: return 25 * 60
            case .shortBreak: return 5 * 60
            case .longBreak: return 15 * 60
            }
        }
    }

    private func minutesForLogging(for session: Session) -> Int {
        // Für Dev-Mode loggen wir 1 Minute, damit "Today" sichtbar hochgeht.
        if isDevModeEnabled && session == .focus {
            return 1
        }
        return durationSeconds(for: session) / 60
    }

    // MARK: - Derived (computed)

    var todayFocusMinutes: Int {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())

        return history
            .filter { $0.session == .focus && $0.date >= startOfToday }
            .map { $0.minutes }
            .reduce(0, +)
    }

    // MARK: - Formatting

    func formattedTime() -> String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Controls

    func toggleStartPause() {
        isRunning ? pause() : start()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func pause() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }

    func reset() {
        pause()
        remainingSeconds = durationSeconds(for: selectedSession)
    }

    // MARK: - Completion + Logging

    private func tick() {
        guard remainingSeconds > 0 else {
            pause()
            return
        }

        remainingSeconds -= 1

        if remainingSeconds == 0 {
            pause()
            handleSessionFinished()
        }
    }

    private func handleSessionFinished() {
        // Wir loggen nur Focus-Sessions
        guard selectedSession == .focus else { return }

        let minutes = minutesForLogging(for: selectedSession)
        let entry = SessionLog(
            id: UUID(),
            date: Date(),
            session: selectedSession,
            minutes: minutes
        )

        history.insert(entry, at: 0)
        saveHistory()
    }

    // MARK: - History Helpers

    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    // MARK: - Persistence (UserDefaults + JSON)

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            // später: Fehlerhandling
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return }
        do {
            history = try JSONDecoder().decode([SessionLog].self, from: data)
        } catch {
            history = []
        }
    }
}
