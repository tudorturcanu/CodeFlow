# CodeFlow

CodeFlow connects your Mac and iOS device seamlessly over your local network via terminal QR-code pairing.

## Overview

- **CodeFlow Mac**: A lightweight Vapor-based macOS service that discovers the Mac's primary LAN IPv4 address, generates a cryptographically secure short-lived pairing token (5-minute validity), and renders a scannable ASCII QR code in the terminal.
- **CodeFlow iOS**: A SwiftUI iOS companion app with a camera QR code scanner that detects the payload, performs local network pairing with the Mac server (`POST /pair`), and verifies connection status.

## Architecture & Features

- **Terminal QR Code Generation**: Uses `QRCode` to render high-contrast terminal QR codes directly in your console.
- **Zero Configuration Discovery**: Detects the active IPv4 interface on the Mac and binds an HTTP server (`0.0.0.0:8080`).
- **Secure Ephemeral Pairing**: Tokens expire automatically after 5 minutes and single-use validation prevents replay attempts.
- **Vapor & SwiftUI**: Modern Swift concurrency (`async`/`await`) across macOS and iOS.

## Getting Started

### 1. CodeFlow Mac
Open `CodeFlow Mac/CodeFlow Mac.xcodeproj` in Xcode and run the scheme. The terminal will print the LAN IP, server URL, pairing token, and QR code.

### 2. CodeFlow iOS
Open `CodeFlow iOS/CodeFlow.xcodeproj` in Xcode, run on an iOS device or simulator connected to the same Wi-Fi network, and scan the terminal QR code to pair.
