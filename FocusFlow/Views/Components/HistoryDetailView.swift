//
//  HistoryDetailView.swift
//  FocusFlow
//
//  Created by Vivi on 06.03.26.
//

import SwiftUI

struct HistoryDetailView: View {
    let log: SessionLog?
    @Binding var notes: String
    @Binding var mood: Mood
    @Binding var tagsText: String

    var body: some View {
        Group {
            if let log {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(log.session.rawValue)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        HStack(spacing: 10) {
                            Label("\(log.minutes) min", systemImage: "clock")
                            Spacer()
                            Label(
                                log.date.formatted(date: .abbreviated, time: .shortened),
                                systemImage: "calendar"
                            )
                        }
                        .font(.headline)
                        .foregroundStyle(.secondary)

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mood")
                                .font(.headline)

                            Picker("Mood", selection: $mood) {
                                ForEach(Mood.allCases) { item in
                                    Text(item.displayName).tag(item)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.headline)

                            Text("Separate tags with commas, for example: study, swiftui, deep work")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            TextField("Add tags", text: $tagsText)
                                .textFieldStyle(.roundedBorder)

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
                                }
                            }
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)

                            Text("Add context for this session, for example what you worked on or how focused you felt.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            TextEditor(text: $notes)
                                .frame(minHeight: 180)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                )
                        }

                        Spacer(minLength: 0)
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "No Selection",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Select a session on the left to see details.")
                )
                .padding()
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
