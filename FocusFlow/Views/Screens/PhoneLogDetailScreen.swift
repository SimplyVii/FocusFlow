//
//  PhoneLogDetailScreen.swift
//  FocusFlow
//
//  Created by Vivi on 09.03.26.
//

import SwiftUI

struct PhoneLogDetailScreen: View {
    @ObservedObject var vm: TimerViewModel
    let logID: SessionLog.ID

    private var notesBinding: Binding<String> {
        Binding(
            get: { vm.log(for: logID)?.notes ?? "" },
            set: { vm.updateNotes($0, for: logID) }
        )
    }

    private var moodBinding: Binding<Mood> {
        Binding(
            get: { vm.log(for: logID)?.mood ?? .good },
            set: { vm.updateMood($0, for: logID) }
        )
    }

    private var tagsBinding: Binding<String> {
        Binding(
            get: { vm.log(for: logID)?.tags.joined(separator: ", ") ?? "" },
            set: { vm.updateTags(from: $0, for: logID) }
        )
    }

    var body: some View {
        Form {
            if let log = vm.log(for: logID) {
                Section("Session") {
                    LabeledContent("Type", value: log.session.rawValue)
                    LabeledContent("Mood", value: log.mood.displayName)
                    LabeledContent("Minutes", value: "\(log.minutes)")
                    LabeledContent("Date", value: log.date.formatted(date: .abbreviated, time: .shortened))
                }

                Section("Mood") {
                    Picker("Mood", selection: moodBinding) {
                        ForEach(Mood.allCases) { mood in
                            Text(mood.displayName).tag(mood)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Tags") {
                    TextField("study, swiftui, deep work", text: tagsBinding)
                        .textInputAutocapitalization(.never)

                    if !log.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(log.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color(.secondarySystemBackground))
                                        )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: notesBinding)
                        .frame(minHeight: 180)
                }
            } else {
                Section {
                    Text("This session could not be found.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.selectLog(logID)
        }
    }
}
