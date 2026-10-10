//
//  PairingSessionManager.swift
//  CodeFlow Mac
//

import Foundation
import Security

public actor PairingSessionManager {
    public struct ActiveToken: Sendable {
        public let token: String
        public let expiresAt: Date

        public init(token: String, expiresAt: Date) {
            self.token = token
            self.expiresAt = expiresAt
        }
    }

    public struct ConnectedClient: Sendable {
        public let clientName: String
        public let pairedAt: Date

        public init(clientName: String, pairedAt: Date) {
            self.clientName = clientName
            self.pairedAt = pairedAt
        }
    }

    private var activeToken: ActiveToken?
    private var connectedClient: ConnectedClient?

    public init() {}

    /// Generates a cryptographically random short-lived pairing token (default 5 minutes).
    public func generateToken(validityDuration: TimeInterval = 300) -> String {
        var randomBytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        
        let token: String
        if status == errSecSuccess {
            token = randomBytes.map { String(format: "%02x", $0) }.joined()
        } else {
            // Fallback in the rare event SecRandom fails
            token = UUID().uuidString.replacingOccurrences(of: "-", with: "") + UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }

        self.activeToken = ActiveToken(
            token: token,
            expiresAt: Date().addingTimeInterval(validityDuration)
        )
        return token
    }

    /// Validates the provided pairing token and records the connected client if successful.
    public func validateAndPair(token: String, clientName: String) -> Bool {
        guard let current = activeToken else {
            return false
        }

        guard Date() <= current.expiresAt else {
            activeToken = nil
            return false
        }

        guard current.token == token else {
            return false
        }

        // Successfully paired: record connection and invalidate single-use pairing token
        self.connectedClient = ConnectedClient(clientName: clientName, pairedAt: Date())
        self.activeToken = nil
        return true
    }

    public var currentConnectedClient: ConnectedClient? {
        connectedClient
    }

    public var isPaired: Bool {
        connectedClient != nil
    }
}
