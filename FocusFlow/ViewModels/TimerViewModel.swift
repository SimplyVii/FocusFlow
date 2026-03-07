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

    enum Session: String, CaseIterable, Identifiable, Codable {
        case focus = "Focus"
        case shortBreak = "Short Break"
        case longBreak = "Long Break"

        var id: String { rawValue }
    }

    struct SessionLog: Identifiable, Codable, Equatable {
        let id: UUID
        let date: Date
        let session: Session
        let minutes: Int
        var notes: String

        init(
            id: UUID,
            date: Date,
            session: Session,
            minutes: Int,
            notes: String = ""
        ) {
            self.id = id
            self.date = date
            self.session = session
            self.minutes = minutes
            self.notes = notes
        }

        enum CodingKeys: String, CodingKey {
            case id
            case date
            case session
            case minutes
            case notes
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            date = try container.decode(Date.self, forKey: .date)
            session = try container.decode(Session.self, forKey: .session)
            minutes = try container.decode(Int.self, forKey: .minutes)
            notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        }
    }

    struct DailyFocusStat: Identifiable {
        let id = UUID()
        let date: Date
        let minutes: Int
    }

    @Published var isDevModeEnabled: Bool = true {
        didSet { reset() }
    }

    @Published var selectedSession: Session = .focus {
        didSet { reset() }
    }

    @Published var isRunning: Bool = false
    @Published var remainingSeconds: Int = 0

    @Published private(set) var history: [SessionLog] = []
    @Published var selectedLogID: SessionLog.ID?

    private var timer: AnyCancellable?
    private let historyKey = "FocusFlow.history.v1"

    init() {
        loadHistory()
        remainingSeconds = durationSeconds(for: selectedSession)
        selectedLogID = history.first?.id
    }

    private func durationSeconds(for session: Session) -> Int {
        if isDevModeEnabled {
            switch session {
            case .focus: return 10
            case .shortBreak: return 5
            case .longBreak: return 8
            }
        } else {
            switch session {
            case .focus: return 25 * 60
            case .shortBreak: return 5 * 60
            case .longBreak: return 15 * 60
            }
        }
    }

    private func minutesForLogging(for session: Session) -> Int {
        if isDevModeEnabled && session == .focus { return 1 }
        return durationSeconds(for: session) / 60
    }

    var todayFocusMinutes: Int {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())

        return history
            .filter { $0.session == .focus && $0.date >= startOfToday }
            .map { $0.minutes }
            .reduce(0, +)
    }

    var totalFocusMinutes: Int {
        history
            .filter { $0.session == .focus }
            .map { $0.minutes }
            .reduce(0, +)
    }

    var totalFocusSessions: Int {
        history.filter { $0.session == .focus }.count
    }

    var selectedLog: SessionLog? {
        guard let id = selectedLogID else { return nil }
        return history.first(where: { $0.id == id })
    }

    var last7DaysFocusStats: [DailyFocusStat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day

            let minutes = history
                .filter {
                    $0.session == .focus &&
                    $0.date >= day &&
                    $0.date < nextDay
                }
                .map { $0.minutes }
                .reduce(0, +)

            return DailyFocusStat(date: day, minutes: minutes)
        }
    }

    func formattedTime() -> String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

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
        guard selectedSession == .focus else { return }

        let minutes = minutesForLogging(for: selectedSession)
        let entry = SessionLog(
            id: UUID(),
            date: Date(),
            session: selectedSession,
            minutes: minutes,
            notes: ""
        )

        history.insert(entry, at: 0)
        selectedLogID = entry.id
        saveHistory()
    }

    func updateNotesForSelectedLog(_ notes: String) {
        guard let id = selectedLogID,
              let index = history.firstIndex(where: { $0.id == id }) else {
            return
        }

        history[index].notes = notes
        saveHistory()
    }

    func deleteHistory(at offsets: IndexSet) {
        let currentSelected = selectedLogID
        history.remove(atOffsets: offsets)
        saveHistory()

        if let currentSelected, !history.contains(where: { $0.id == currentSelected }) {
            selectedLogID = history.first?.id
        }
    }

    func clearHistory() {
        history.removeAll()
        selectedLogID = nil
        saveHistory()
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch { }
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
