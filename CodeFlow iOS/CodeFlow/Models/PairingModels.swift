//
//  PairingModels.swift
//  CodeFlow
//

import Foundation

/// Payload decoded from the Mac's terminal QR code
public struct PairingPayload: Codable, Sendable, Equatable {
    public let serverURL: String
    public let token: String
    public let deviceName: String

    public init(serverURL: String, token: String, deviceName: String) {
        self.serverURL = serverURL
        self.token = token
        self.deviceName = deviceName
    }
}

/// Request sent to POST /pair on the Mac server
public struct PairingRequest: Codable, Sendable {
    public let token: String
    public let clientName: String

    public init(token: String, clientName: String) {
        self.token = token
        self.clientName = clientName
    }
}

/// Response returned from the Mac server
public struct PairingResponse: Codable, Sendable {
    public let success: Bool
    public let serverName: String
    public let message: String

    public init(success: Bool, serverName: String, message: String) {
        self.success = success
        self.serverName = serverName
        self.message = message
    }
}

/// Representation of a connected Mac displayed on the iOS home screen
public struct ConnectedMac: Codable, Sendable, Identifiable, Equatable {
    public var id: String { serverURL }
    public let serverURL: String
    public let name: String
    public let connectedAt: Date

    public init(serverURL: String, name: String, connectedAt: Date = Date()) {
        self.serverURL = serverURL
        self.name = name
        self.connectedAt = connectedAt
    }
}
