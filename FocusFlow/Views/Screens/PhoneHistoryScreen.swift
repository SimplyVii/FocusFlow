//
//  PhoneHistoryScreen.swift
//  FocusFlow
//
//  Created by Vivi on 09.03.26.
//

import SwiftUI

struct PhoneHistoryScreen: View {
    @ObservedObject var vm: TimerViewModel

    var body: some View {
        List {
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
                        NavigationLink {
                            PhoneLogDetailScreen(vm: vm, logID: item.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Text(item.session.rawValue)
                                        .font(.headline)
                                    Text(item.mood.emoji)
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

                                if !item.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text(item.notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                vm.delete(logID: item.id)
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
                }
            }
        }
        .navigationTitle("History")
        .searchable(text: $vm.searchText, prompt: "Search history")
    }
}
