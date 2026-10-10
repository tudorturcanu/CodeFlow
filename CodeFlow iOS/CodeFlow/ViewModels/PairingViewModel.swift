//
//  PairingViewModel.swift
//  CodeFlow
//

import Foundation
import SwiftUI
import UIKit
import Combine

@MainActor
public final class PairingViewModel: ObservableObject {
    @Published public var connectedMac: ConnectedMac?
    @Published public var isScanning: Bool = false
    @Published public var isPairing: Bool = false
    @Published public var errorMessage: String?
    @Published public var showErrorAlert: Bool = false

    private let pairingClient = PairingClient()

    public init() {}

    /// Decodes the scanned QR code payload and initiates pairing with the Mac server.
    public func handleScannedCode(_ rawCode: String) {
        guard !isPairing else { return }
        self.isScanning = false
        self.isPairing = true
        self.errorMessage = nil

        Task {
            do {
                guard let data = rawCode.data(using: .utf8) else {
                    throw PairingError.invalidPayload
                }

                let payload = try JSONDecoder().decode(PairingPayload.self, from: data)
                let clientDeviceName = UIDevice.current.name

                let response = try await pairingClient.pair(payload: payload, clientName: clientDeviceName)

                let macName = response.serverName.isEmpty ? payload.deviceName : response.serverName
                self.connectedMac = ConnectedMac(
                    serverURL: payload.serverURL,
                    name: macName,
                    connectedAt: Date()
                )
                self.isPairing = false
            } catch {
                self.isPairing = false
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }

    public func disconnect() {
        self.connectedMac = nil
    }
}
