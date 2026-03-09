//
//  FocusFlowCSVDocument.swift
//  FocusFlow
//
//  Created by Vivi on 07.03.26.
//

import SwiftUI
import UniformTypeIdentifiers

struct FocusFlowCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    let csvText: String

    init(csvText: String) {
        self.csvText = csvText
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let text = String(data: data, encoding: .utf8) {
            self.csvText = text
        } else {
            self.csvText = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(csvText.utf8)
        return .init(regularFileWithContents: data)
    }
}
