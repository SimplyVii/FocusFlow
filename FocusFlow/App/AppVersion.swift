//
//  AppVersion.swift
//  FocusFlow
//
//  Created by Vivi on 06.03.26.
//

import Foundation

enum AppVersion {
    static var marketing: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    static var displayString: String {
        "v\(marketing) (\(build))"
    }
}
