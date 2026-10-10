//
//  main.swift
//  CodeFlow Mac
//

import Foundation
import Vapor
import QRCode

// 1. Discover primary LAN IPv4 address
let lanIP = LANAddressFinder.getPrimaryIPv4Address() ?? "127.0.0.1"
let port = 8080
let serverURL = "http://\(lanIP):\(port)"
let deviceName = Host.current().localizedName ?? ProcessInfo.processInfo.hostName

// 2. Generate cryptographically random short-lived pairing token (5 minutes)
let sessionManager = PairingSessionManager()
let token = await sessionManager.generateToken(validityDuration: 300)

// 3. Create pairing payload JSON
let payload = PairingPayload(serverURL: serverURL, token: token, deviceName: deviceName)
guard let payloadData = try? JSONEncoder().encode(payload),
      let payloadString = String(data: payloadData, encoding: .utf8) else {
    fatalError("Failed to encode pairing payload")
}

// 4. Render QR code directly in Terminal
print("\n╔════════════════════════════════════════════════════════════╗")
print("║                   CodeFlow Mac Server                      ║")
print("╚════════════════════════════════════════════════════════════╝")
print("LAN IPv4 Address:  \(lanIP)")
print("Server URL:        \(serverURL)")
print("Device Name:       \(deviceName)")
print("Pairing Token:     \(token)")
print("Token Validity:    5 minutes")
print("──────────────────────────────────────────────────────────────")
print("Scan this QR code with the CodeFlow iOS app:\n")

TerminalQRRenderer.render(payload: payloadString)

print("\n──────────────────────────────────────────────────────────────")
print("Waiting for CodeFlow iOS to connect...")
print("══════════════════════════════════════════════════════════════\n")

// 5. Configure and start Vapor HTTP server on port 8080 using async Application lifecycle
var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = try await Application.make(env)

app.http.server.configuration.hostname = "0.0.0.0"
app.http.server.configuration.port = port

// Route: POST /pair
app.post("pair") { req async throws -> Response in
    let body = try req.content.decode(PairingRequest.self)
    let isSuccess = await sessionManager.validateAndPair(token: body.token, clientName: body.clientName)

    if isSuccess {
        req.logger.info("Successfully paired with iOS client: \(body.clientName)")
        print("\n[CodeFlow] Successfully paired with iOS device: \(body.clientName)!\n")
        let res = PairingResponse(
            success: true,
            serverName: deviceName,
            message: "Successfully paired with \(deviceName)"
        )
        return try await res.encodeResponse(status: .ok, for: req)
    } else {
        req.logger.warning("Rejected pairing attempt from: \(body.clientName)")
        print("\n[CodeFlow] Rejected pairing attempt from: \(body.clientName) (invalid or expired token)\n")
        let res = PairingResponse(
            success: false,
            serverName: deviceName,
            message: "Invalid or expired pairing token."
        )
        return try await res.encodeResponse(status: .unauthorized, for: req)
    }
}

// Route: GET /status
app.get("status") { req async -> [String: String] in
    let client = await sessionManager.currentConnectedClient
    return [
        "status": "online",
        "device": deviceName,
        "pairedClient": client?.clientName ?? "none"
    ]
}

do {
    try await app.execute()
} catch {
    try? await app.asyncShutdown()
    throw error
}
try await app.asyncShutdown()
