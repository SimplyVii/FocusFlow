//
//  TimerView.swift
//  FocusFlow
//
//  Created by Vivi on 06.03.26.
//

import SwiftUI
import UniformTypeIdentifiers

struct TimerScreen: View {
    @StateObject private var vm = TimerViewModel()
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var isShowingStats = false
    @State private var isShowingSettings = false
    @State private var isExportingCSV = false
    @State private var isImportingCSV = false
    @State private var timerTextScale: CGFloat = 1.0
    @State private var selectedPhoneTab: PhoneTab = .home
    @State private var importAlertMessage = ""
    @State private var isShowingImportAlert = false

    private enum PhoneTab {
        case home
        case history
        case stats
        case settings
    }

    private var selectedNotesBinding: Binding<String> {
        Binding(
            get: { vm.selectedLog?.notes ?? "" },
            set: { vm.updateNotesForSelectedLog($0) }
        )
    }

    private var selectedMoodBinding: Binding<Mood> {
        Binding(
            get: { vm.selectedLog?.mood ?? .good },
            set: { vm.updateMoodForSelectedLog($0) }
        )
    }

    private var selectedTagsTextBinding: Binding<String> {
        Binding(
            get: { vm.selectedLog?.tags.joined(separator: ", ") ?? "" },
            set: { vm.updateTagsForSelectedLog(from: $0) }
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
        .sheet(isPresented: $isShowingSettings) {
            SettingsScreen(
                showsDoneButton: true,
                onImport: { isImportingCSV = true },
                onExport: { isExportingCSV = true }
            )
        }
        .fileExporter(
            isPresented: $isExportingCSV,
            document: vm.csvExportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "FocusFlow-Export"
        ) { _ in }
        .fileImporter(
            isPresented: $isImportingCSV,
            allowedContentTypes: [.commaSeparatedText]
        ) { result in
            handleImport(result)
        }
        .alert("Import CSV", isPresented: $isShowingImportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importAlertMessage)
        }
        .onChange(of: vm.completionEventCount) {
            animateTimerBounce()
        }
    }

    private var phoneLayout: some View {
        TabView(selection: $selectedPhoneTab) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        timerHeader
                        phoneSummaryCards
                        phoneRecentSection
                    }
                    .padding()
                }
                .navigationTitle("FocusFlow")
                .overlay(alignment: .bottomTrailing) {
                    if UserDefaults.standard.object(forKey: "settings.showVersionWatermark") as? Bool ?? true,
                       vm.isDevModeEnabled {
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
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(PhoneTab.home)

            NavigationStack {
                PhoneHistoryScreen(vm: vm)
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(PhoneTab.history)

            StatsScreen(vm: vm, showsDoneButton: false)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.xaxis")
                }
                .tag(PhoneTab.stats)

            SettingsScreen(
                showsDoneButton: false,
                onImport: { isImportingCSV = true },
                onExport: { isExportingCSV = true }
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(PhoneTab.settings)
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

                Section {
                    Picker("Filter", selection: $vm.historyFilter) {
                        ForEach(TimerViewModel.HistoryFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("History") {
                    if vm.filteredHistory.isEmpty {
                        Text(vm.searchText.isEmpty ? "No matching sessions." : "No results for your search.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.filteredHistory) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(item.session.rawValue)
                                            .font(.headline)
                                        Text(item.mood.emoji)
                                    }

                                    Text(item.date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    if !item.tags.isEmpty {
                                        Text(item.tags.joined(separator: " • "))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    if !item.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text(item.notes)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                Text("\(item.minutes) min")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(item.id)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    if let index = vm.filteredHistory.firstIndex(where: { $0.id == item.id }) {
                                        vm.deleteFilteredHistory(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    vm.clearNotes(for: item.id)
                                } label: {
                                    Label("Clear Notes", systemImage: "eraser")
                                }
                                .tint(.orange)
                            }
                        }
                        .onDelete(perform: vm.deleteFilteredHistory)
                    }
                }
            }
            .navigationTitle("History")
            .searchable(text: $vm.searchText, prompt: "Search history")
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
                            notes: selectedNotesBinding,
                            mood: selectedMoodBinding,
                            tagsText: selectedTagsTextBinding
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .navigationTitle("FocusFlow")
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            isShowingStats = true
                        } label: {
                            Image(systemName: "chart.bar.xaxis")
                        }

                        Button {
                            isShowingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if UserDefaults.standard.object(forKey: "settings.showVersionWatermark") as? Bool ?? true,
                       vm.isDevModeEnabled {
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
        VStack(spacing: 16) {
            Picker("Session", selection: $vm.selectedSession) {
                ForEach(TimerViewModel.Session.allCases) { session in
                    Text(session.rawValue).tag(session)
                }
            }
            .pickerStyle(.segmented)

            ZStack {
                TimerProgressRing(
                    progress: vm.timerProgress,
                    ringColor: vm.timerRingColor,
                    isRunning: vm.isRunning
                )
                .frame(width: 196, height: 196)

                Text(vm.formattedTime())
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(vm.timerRingColor)
                    .scaleEffect(timerTextScale)
            }
            .padding(.top, 4)

            HStack(spacing: 14) {
                GlassActionButton(
                    title: vm.isRunning ? "Pause" : "Start",
                    systemImage: vm.isRunning ? "pause.fill" : "play.fill",
                    tint: vm.timerRingColor
                ) {
                    vm.toggleStartPause()
                }

                GlassActionButton(
                    title: "Reset",
                    systemImage: "arrow.counterclockwise",
                    tint: .secondary
                ) {
                    vm.reset()
                }
            }
        }
    }

    private var phoneSummaryCards: some View {
        HStack(spacing: 12) {
            phoneCard(
                title: "Today",
                value: "\(vm.todayFocusMinutes) min"
            )

            phoneCard(
                title: "Sessions",
                value: "\(vm.totalFocusSessions)"
            )
        }
    }

    private func phoneCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var phoneRecentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Session")
                    .font(.headline)

                Spacer()

                Button("See All") {
                    selectedPhoneTab = .history
                }
                .font(.subheadline)
            }

            if vm.recentHistory.isEmpty {
                Text("No sessions yet. Finish a focus session and it will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.secondarySystemBackground))
                    )
            } else {
                VStack(spacing: 10) {
                    ForEach(vm.recentHistory) { item in
                        NavigationLink {
                            PhoneLogDetailScreen(vm: vm, logID: item.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Text(item.session.rawValue)
                                            .font(.headline)
                                        Text(item.mood.emoji)
                                    }

                                    Spacer()

                                    Text("\(item.minutes) min")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if !item.tags.isEmpty {
                                    Text(item.tags.joined(separator: " • "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func animateTimerBounce() {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.58)) {
            timerTextScale = 1.08
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                timerTextScale = 1.0
            }
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                let count = try vm.importCSV(from: url)
                importAlertMessage = "Imported \(count) session(s)."
            } catch {
                importAlertMessage = "Import failed: \(error.localizedDescription)"
            }
            isShowingImportAlert = true

        case .failure(let error):
            importAlertMessage = "Import failed: \(error.localizedDescription)"
            isShowingImportAlert = true
        }
    }
}
