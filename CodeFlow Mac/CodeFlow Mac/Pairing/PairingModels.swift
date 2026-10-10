//
//  PairingModels.swift
//  CodeFlow Mac
//

import Foundation
import Vapor

/// Payload encoded in the QR code scanned by iOS
public struct PairingPayload: Codable, Sendable {
    public let serverURL: String
    public let token: String
    public let deviceName: String

    public init(serverURL: String, token: String, deviceName: String) {
        self.serverURL = serverURL
        self.token = token
        self.deviceName = deviceName
    }
}

/// Request sent by iOS to POST /pair
public struct PairingRequest: Content, Sendable {
    public let token: String
    public let clientName: String

    public init(token: String, clientName: String) {
        self.token = token
        self.clientName = clientName
    }
}

/// Response returned by Mac to iOS
public struct PairingResponse: Content, Sendable {
    public let success: Bool
    public let serverName: String
    public let message: String

    public init(success: Bool, serverName: String, message: String) {
        self.success = success
        self.serverName = serverName
        self.message = message
    }
}
