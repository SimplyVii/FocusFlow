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

    enum HistoryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case focusOnly = "Focus"
        case withNotes = "With Notes"

        var id: String { rawValue }
    }

    @Published var isDevModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDevModeEnabled, forKey: "settings.isDevModeEnabled")
            reset()
        }
    }

    @Published var selectedSession: Session = .focus {
        didSet { reset() }
    }

    @Published var isRunning: Bool = false
    @Published var remainingSeconds: Int = 0

    @Published private(set) var history: [SessionLog] = []
    @Published var selectedLogID: SessionLog.ID?

    @Published var searchText: String = ""
    @Published var historyFilter: HistoryFilter = .all

    @Published private(set) var completionEventCount: Int = 0

    private var timer: AnyCancellable?
    private var settingsObserver: AnyCancellable?
    private let historyKey = "FocusFlow.history.v1"

    init() {
        self.isDevModeEnabled = UserDefaults.standard.object(forKey: "settings.isDevModeEnabled") as? Bool ?? true

        loadHistory()
        remainingSeconds = durationSeconds(for: selectedSession)
        selectedLogID = history.first?.id

        settingsObserver = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.applySettingsFromDefaults()
            }
    }

    private func applySettingsFromDefaults() {
        let newDevMode = UserDefaults.standard.object(forKey: "settings.isDevModeEnabled") as? Bool ?? true
        let oldDuration = currentSessionDuration

        if isDevModeEnabled != newDevMode {
            isDevModeEnabled = newDevMode
            return
        }

        let newDuration = durationSeconds(for: selectedSession)

        guard oldDuration > 0 else {
            remainingSeconds = newDuration
            return
        }

        if isRunning {
            let elapsed = oldDuration - remainingSeconds
            let elapsedFraction = max(0, min(1, Double(elapsed) / Double(oldDuration)))
            let recalculated = Int(round(Double(newDuration) * (1 - elapsedFraction)))
            remainingSeconds = max(0, min(newDuration, recalculated))
        } else {
            remainingSeconds = newDuration
        }
    }

    private func durationSeconds(for session: Session) -> Int {
        if isDevModeEnabled {
            switch session {
            case .focus:
                return UserDefaults.standard.object(forKey: "settings.devFocusSeconds") as? Int ?? 10
            case .shortBreak:
                return UserDefaults.standard.object(forKey: "settings.devShortBreakSeconds") as? Int ?? 5
            case .longBreak:
                return UserDefaults.standard.object(forKey: "settings.devLongBreakSeconds") as? Int ?? 8
            }
        } else {
            switch session {
            case .focus:
                return (UserDefaults.standard.object(forKey: "settings.focusMinutes") as? Int ?? 25) * 60
            case .shortBreak:
                return (UserDefaults.standard.object(forKey: "settings.shortBreakMinutes") as? Int ?? 5) * 60
            case .longBreak:
                return (UserDefaults.standard.object(forKey: "settings.longBreakMinutes") as? Int ?? 15) * 60
            }
        }
    }

    private var autoResetEnabled: Bool {
        UserDefaults.standard.object(forKey: "settings.autoResetEnabled") as? Bool ?? true
    }

    private func minutesForLogging(for session: Session) -> Int {
        if isDevModeEnabled && session == .focus { return 1 }
        return durationSeconds(for: session) / 60
    }

    var currentSessionDuration: Int {
        durationSeconds(for: selectedSession)
    }

    var timerProgress: Double {
        guard currentSessionDuration > 0 else { return 0 }
        return Double(remainingSeconds) / Double(currentSessionDuration)
    }

    var timerRingColor: Color {
        switch selectedSession {
        case .focus:
            return .pink
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        }
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

    var recentHistory: [SessionLog] {
        Array(history.prefix(1))
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

    var filteredHistory: [SessionLog] {
        history.filter { item in
            matchesFilter(item) && matchesSearch(item)
        }
    }

    var csvExportDocument: FocusFlowCSVDocument {
        FocusFlowCSVDocument(csvText: makeCSV(from: filteredHistory))
    }

    func log(for id: SessionLog.ID) -> SessionLog? {
        history.first(where: { $0.id == id })
    }

    func selectLog(_ id: SessionLog.ID) {
        selectedLogID = id
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
            Haptics.timerCompleted()
            completionEventCount += 1

            if autoResetEnabled {
                remainingSeconds = durationSeconds(for: selectedSession)
            }
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
            notes: "",
            mood: .good,
            tags: []
        )

        history.insert(entry, at: 0)
        selectedLogID = entry.id
        saveHistory()
    }

    func updateNotesForSelectedLog(_ notes: String) {
        guard let id = selectedLogID else { return }
        updateNotes(notes, for: id)
    }

    func updateNotes(_ notes: String, for logID: SessionLog.ID) {
        guard let index = history.firstIndex(where: { $0.id == logID }) else { return }
        history[index].notes = notes
        saveHistory()
    }

    func updateMoodForSelectedLog(_ mood: Mood) {
        guard let id = selectedLogID else { return }
        updateMood(mood, for: id)
    }

    func updateMood(_ mood: Mood, for logID: SessionLog.ID) {
        guard let index = history.firstIndex(where: { $0.id == logID }) else { return }
        history[index].mood = mood
        saveHistory()
    }

    func updateTagsForSelectedLog(from text: String) {
        guard let id = selectedLogID else { return }
        updateTags(from: text, for: id)
    }

    func updateTags(from text: String, for logID: SessionLog.ID) {
        guard let index = history.firstIndex(where: { $0.id == logID }) else { return }

        let parsedTags = text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        history[index].tags = Array(NSOrderedSet(array: parsedTags)) as? [String] ?? parsedTags
        saveHistory()
    }

    func clearNotes(for logID: SessionLog.ID) {
        guard let index = history.firstIndex(where: { $0.id == logID }) else { return }
        history[index].notes = ""
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

    func deleteFilteredHistory(at offsets: IndexSet) {
        let idsToDelete = offsets.map { filteredHistory[$0].id }
        history.removeAll { idsToDelete.contains($0.id) }
        saveHistory()

        if let selectedLogID, !history.contains(where: { $0.id == selectedLogID }) {
            self.selectedLogID = history.first?.id
        }
    }

    func delete(logID: SessionLog.ID) {
        history.removeAll { $0.id == logID }
        saveHistory()

        if let selectedLogID, !history.contains(where: { $0.id == selectedLogID }) {
            self.selectedLogID = history.first?.id
        }
    }

    func clearHistory() {
        history.removeAll()
        selectedLogID = nil
        saveHistory()
    }

    func importCSV(from url: URL) throws -> Int {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let text = try String(contentsOf: url, encoding: .utf8)
        let importedLogs = try parseCSV(text)

        history.insert(contentsOf: importedLogs, at: 0)
        history.sort { $0.date > $1.date }

        if selectedLogID == nil {
            selectedLogID = history.first?.id
        }

        saveHistory()
        return importedLogs.count
    }

    private func parseCSV(_ text: String) throws -> [SessionLog] {
        let rows = splitCSVRows(text)
        guard !rows.isEmpty else { return [] }

        let parsedRows = rows.map(parseCSVColumns)

        let dataRows: [[String]]
        if let first = parsedRows.first,
           first.map({ $0.lowercased() }) == ["date", "session", "minutes", "mood", "tags", "notes"] {
            dataRows = Array(parsedRows.dropFirst())
        } else {
            dataRows = parsedRows
        }

        return dataRows.compactMap { columns in
            guard columns.count >= 6 else { return nil }

            let date = parseDate(columns[0]) ?? Date()
            let session = Session(rawValue: columns[1]) ?? .focus
            let minutes = Int(columns[2]) ?? 0
            let mood = Mood(rawValue: columns[3]) ?? .good
            let tags = columns[4]
                .split(separator: ";")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let notes = columns[5]

            return SessionLog(
                id: UUID(),
                date: date,
                session: session,
                minutes: minutes,
                notes: notes,
                mood: mood,
                tags: tags
            )
        }
    }

    private func splitCSVRows(_ text: String) -> [String] {
        var rows: [String] = []
        var current = ""
        var insideQuotes = false

        for char in text {
            if char == "\"" {
                insideQuotes.toggle()
                current.append(char)
            } else if char == "\n" && !insideQuotes {
                rows.append(current)
                current = ""
            } else if char == "\r" {
                continue
            } else {
                current.append(char)
            }
        }

        if !current.isEmpty {
            rows.append(current)
        }

        return rows.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func parseCSVColumns(_ row: String) -> [String] {
        var columns: [String] = []
        var current = ""
        var insideQuotes = false
        let chars = Array(row)
        var index = 0

        while index < chars.count {
            let char = chars[index]

            if char == "\"" {
                if insideQuotes, index + 1 < chars.count, chars[index + 1] == "\"" {
                    current.append("\"")
                    index += 1
                } else {
                    insideQuotes.toggle()
                }
            } else if char == "," && !insideQuotes {
                columns.append(current)
                current = ""
            } else {
                current.append(char)
            }

            index += 1
        }

        columns.append(current)
        return columns
    }

    private func parseDate(_ value: String) -> Date? {
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: value) {
            return date
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        return formatter.date(from: value)
    }

    private func matchesFilter(_ item: SessionLog) -> Bool {
        switch historyFilter {
        case .all:
            return true
        case .focusOnly:
            return item.session == .focus
        case .withNotes:
            return !item.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func matchesSearch(_ item: SessionLog) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        let dateText = item.date.formatted(date: .abbreviated, time: .shortened)
        let tagsText = item.tags.joined(separator: ", ")

        return item.session.rawValue.localizedCaseInsensitiveContains(query)
            || item.notes.localizedCaseInsensitiveContains(query)
            || item.mood.rawValue.localizedCaseInsensitiveContains(query)
            || tagsText.localizedCaseInsensitiveContains(query)
            || dateText.localizedCaseInsensitiveContains(query)
            || "\(item.minutes)".localizedCaseInsensitiveContains(query)
    }

    private func makeCSV(from items: [SessionLog]) -> String {
        let header = ["date", "session", "minutes", "mood", "tags", "notes"]
            .joined(separator: ",")

        let iso = ISO8601DateFormatter()

        let rows = items.map { item in
            [
                escapedCSVField(iso.string(from: item.date)),
                escapedCSVField(item.session.rawValue),
                escapedCSVField(String(item.minutes)),
                escapedCSVField(item.mood.rawValue),
                escapedCSVField(item.tags.joined(separator: "; ")),
                escapedCSVField(item.notes)
            ]
            .joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n")
    }

    private func escapedCSVField(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
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
