//
//  SessionLog.swift
//  FocusFlow
//
//  Created by Vivi on 07.03.26.
//

import Foundation

struct SessionLog: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let session: TimerViewModel.Session
    let minutes: Int
    var notes: String
    var mood: Mood
    var tags: [String]

    init(
        id: UUID,
        date: Date,
        session: TimerViewModel.Session,
        minutes: Int,
        notes: String = "",
        mood: Mood = .good,
        tags: [String] = []
    ) {
        self.id = id
        self.date = date
        self.session = session
        self.minutes = minutes
        self.notes = notes
        self.mood = mood
        self.tags = tags
    }

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case session
        case minutes
        case notes
        case mood
        case tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        session = try container.decode(TimerViewModel.Session.self, forKey: .session)
        minutes = try container.decode(Int.self, forKey: .minutes)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        mood = try container.decodeIfPresent(Mood.self, forKey: .mood) ?? .good
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}
