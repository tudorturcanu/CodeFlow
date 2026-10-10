//
//  HomeView.swift
//  CodeFlow
//

import SwiftUI

public struct HomeView: View {
    @StateObject private var viewModel = PairingViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection

                        if let mac = viewModel.connectedMac {
                            connectedMacCard(mac: mac)
                        } else {
                            unpairedCard
                        }

                        quickInstructionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }

                if viewModel.isPairing {
                    pairingOverlay
                }
            }
            .navigationTitle("CodeFlow")
            .sheet(isPresented: $viewModel.isScanning) {
                QRScannerView { scannedPayload in
                    viewModel.handleScannedCode(scannedPayload)
                }
            }
            .alert("Pairing Failed", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unexpected error occurred while pairing.")
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("CodeFlow")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(viewModel.connectedMac != nil ? "Paired & Ready" : "Terminal Companion")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            statusBadge
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(viewModel.connectedMac != nil ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            Text(viewModel.connectedMac != nil ? "Connected" : "Disconnected")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(viewModel.connectedMac != nil ? .green : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            (viewModel.connectedMac != nil ? Color.green : Color.gray)
                .opacity(0.12),
            in: Capsule()
        )
    }

    private var unpairedCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 90, height: 90)

                Image(systemName: "macbook.and.iphone")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)

            VStack(spacing: 8) {
                Text("No Mac Connected")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("Pair with the CodeFlow macOS command line tool by scanning the QR code in your terminal.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }

            Button {
                viewModel.isScanning = true
            } label: {
                Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 4)
        }
        .padding(24)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func connectedMacCard(mac: ConnectedMac) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 52, height: 52)

                    Image(systemName: "laptopcomputer")
                        .font(.title2)
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(mac.name)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Connected via Local Network")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }

                Spacer()
            }

            Divider()

            VStack(spacing: 12) {
                detailRow(title: "Server Endpoint", value: mac.serverURL, icon: "network")
                detailRow(title: "Connected At", value: mac.connectedAt.formatted(date: .omitted, time: .standard), icon: "clock")
                detailRow(title: "Status", value: "Active", icon: "checkmark.circle.fill", valueColor: .green)
            }

            Divider()

            HStack {
                Button(role: .destructive) {
                    viewModel.disconnect()
                } label: {
                    Label("Disconnect", systemImage: "xmark.circle")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }

                Spacer()

                Button {
                    viewModel.isScanning = true
                } label: {
                    Label("Re-pair", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func detailRow(title: String, value: String, icon: String, valueColor: Color = .primary) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }

    private var quickInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Setup Instructions")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 12) {
                stepRow(number: "1", text: "Launch the CodeFlow Mac target in Xcode or Terminal.")
                stepRow(number: "2", text: "Ensure your iPhone and Mac are on the same Wi-Fi network.")
                stepRow(number: "3", text: "Tap 'Scan QR Code' above and point the camera at the Terminal.")
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func stepRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(width: 20, height: 20)
                .background(Color.blue.opacity(0.12), in: Circle())

            Text(text)
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pairingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(.white)

                Text("Pairing with Mac...")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Sending token to /pair endpoint")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
