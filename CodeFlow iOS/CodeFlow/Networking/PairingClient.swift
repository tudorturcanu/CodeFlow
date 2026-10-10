//
//  PairingClient.swift
//  CodeFlow
//

import Foundation

public enum PairingError: LocalizedError {
    case invalidURL
    case invalidResponse(Int)
    case serverRejected(String)
    case networkError(String)
    case invalidPayload

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The server URL in the pairing code is invalid."
        case .invalidResponse(let statusCode):
            return "Server responded with HTTP status code \(statusCode)."
        case .serverRejected(let message):
            return message
        case .networkError(let details):
            return "Failed to connect to the Mac: \(details)"
        case .invalidPayload:
            return "The scanned QR code is not a valid CodeFlow pairing payload."
        }
    }
}

public actor PairingClient {
    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    /// Sends a POST /pair request to the Mac server with the pairing token and client device name.
    public func pair(payload: PairingPayload, clientName: String) async throws -> PairingResponse {
        guard let baseURL = URL(string: payload.serverURL) else {
            throw PairingError.invalidURL
        }

        let pairEndpoint = baseURL.appendingPathComponent("pair")
        var request = URLRequest(url: pairEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15.0

        let body = PairingRequest(token: payload.token, clientName: clientName)
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw PairingError.invalidPayload
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            throw PairingError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PairingError.networkError("Invalid HTTP response received.")
        }

        let decodedResponse = try? JSONDecoder().decode(PairingResponse.self, from: data)

        if httpResponse.statusCode == 200 {
            if let decoded = decodedResponse, decoded.success {
                return decoded
            } else {
                throw PairingError.serverRejected(decodedResponse?.message ?? "Pairing failed.")
            }
        } else {
            let errorMsg = decodedResponse?.message ?? "Pairing rejected by Mac (HTTP \(httpResponse.statusCode))."
            throw PairingError.serverRejected(errorMsg)
        }
    }
}
