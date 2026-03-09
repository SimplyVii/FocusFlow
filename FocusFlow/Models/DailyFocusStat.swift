//
//  DailyFocusStat.swift
//  FocusFlow
//
//  Created by Vivi on 07.03.26.
//

import Foundation

struct DailyFocusStat: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
}
