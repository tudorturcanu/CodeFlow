//
//  TerminalQRRenderer.swift
//  CodeFlow Mac
//

import Foundation
import QRCode

public enum TerminalQRRenderer {
    /// Renders a scannable QR code directly into the terminal standard output.
    public static func render(payload: String) {
        do {
            let doc = try QRCode.Document(utf8String: payload)
            // smallAsciiRepresentation is a String property in QRCode
            let representation = doc.smallAsciiRepresentation
            print(representation)
        } catch {
            let doc = QRCode.Document()
            doc.utf8String = payload
            let representation = doc.smallAsciiRepresentation
            print(representation)
        }
    }
}
