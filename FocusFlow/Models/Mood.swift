//
//  Mood.swift
//  FocusFlow
//
//  Created by Vivi on 07.03.26.
//

import Foundation

enum Mood: String, CaseIterable, Identifiable, Codable {
    case great = "Great"
    case good = "Good"
    case okay = "Okay"
    case tough = "Tough"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .great: return "🔥"
        case .good: return "🙂"
        case .okay: return "😐"
        case .tough: return "😵"
        }
    }

    var displayName: String {
        "\(emoji) \(rawValue)"
    }
}
