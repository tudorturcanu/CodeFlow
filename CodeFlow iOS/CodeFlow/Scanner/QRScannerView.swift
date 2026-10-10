//
//  QRScannerView.swift
//  CodeFlow
//

import SwiftUI
import AVFoundation

public struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    public let onCodeScanned: (String) -> Void

    @State private var cameraPermission: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var isFlashlightOn: Bool = false
    @State private var hasScanned: Bool = false
    @State private var manualInputText: String = ""
    @State private var showManualInput: Bool = false

    public init(onCodeScanned: @escaping (String) -> Void) {
        self.onCodeScanned = onCodeScanned
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                switch cameraPermission {
                case .authorized:
                    cameraView
                case .notDetermined:
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                        Text("Requesting camera access...")
                            .foregroundColor(.white)
                    }
                    .onAppear {
                        requestCameraPermission()
                    }
                case .denied, .restricted:
                    permissionDeniedView
                @unknown default:
                    permissionDeniedView
                }
            }
            .navigationTitle("Scan Mac QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .primaryAction) {
                    if cameraPermission == .authorized {
                        Button {
                            toggleFlashlight()
                        } label: {
                            Image(systemName: isFlashlightOn ? "bolt.fill" : "bolt.slash.fill")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showManualInput) {
                manualInputSheet
            }
        }
    }

    private var cameraView: some View {
        ZStack {
            AVScannerRepresentable { code in
                guard !hasScanned else { return }
                hasScanned = true
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                onCodeScanned(code)
                dismiss()
            }
            .ignoresSafeArea()

            // Viewfinder reticle overlay
            VStack {
                Text("Align QR code within the frame")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial.opacity(0.8), in: Capsule())
                    .padding(.top, 24)

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.8), lineWidth: 3)
                        .frame(width: 250, height: 250)

                    // Corner indicators
                    reticleCorners
                }

                Spacer()

                // Manual input or simulator helper
                Button {
                    showManualInput = true
                } label: {
                    Label("Enter Pairing Payload Manually", systemImage: "keyboard")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6), in: Capsule())
                }
                .padding(.bottom, 32)
            }
        }
    }

    private var reticleCorners: some View {
        ZStack {
            let size: CGFloat = 250
            let cornerLen: CGFloat = 28
            let strokeWidth: CGFloat = 4

            // Top-left
            Path { path in
                path.move(to: CGPoint(x: 0, y: cornerLen))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: cornerLen, y: 0))
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)

            // Top-right
            Path { path in
                path.move(to: CGPoint(x: size - cornerLen, y: 0))
                path.addLine(to: CGPoint(x: size, y: 0))
                path.addLine(to: CGPoint(x: size, y: cornerLen))
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)

            // Bottom-left
            Path { path in
                path.move(to: CGPoint(x: 0, y: size - cornerLen))
                path.addLine(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: cornerLen, y: size))
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)

            // Bottom-right
            Path { path in
                path.move(to: CGPoint(x: size - cornerLen, y: size))
                path.addLine(to: CGPoint(x: size, y: size))
                path.addLine(to: CGPoint(x: size, y: size - cornerLen))
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("CodeFlow needs access to your camera to scan the pairing QR code displayed in the Mac Terminal.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 32)

            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                Link(destination: settingsURL) {
                    Text("Open Settings")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 10))
                }
            }

            Button("Enter Payload Manually") {
                showManualInput = true
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            .padding(.top, 8)
        }
    }

    private var manualInputSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Paste the JSON payload generated by the Mac Terminal tool:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextEditor(text: $manualInputText)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    .frame(minHeight: 140)

                Button {
                    let trimmed = manualInputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    showManualInput = false
                    onCodeScanned(trimmed)
                    dismiss()
                } label: {
                    Text("Submit Payload")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(manualInputText.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(manualInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle("Manual Pairing Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showManualInput = false
                    }
                }
            }
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.cameraPermission = granted ? .authorized : .denied
            }
        }
    }

    private func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if isFlashlightOn {
                device.torchMode = .off
                isFlashlightOn = false
            } else {
                try device.setTorchModeOn(level: 1.0)
                isFlashlightOn = true
            }
            device.unlockForConfiguration()
        } catch {
            print("Flashlight error: \(error)")
        }
    }
}

// MARK: - AVScannerRepresentable (UIKit AVFoundation Integration)

private struct AVScannerRepresentable: UIViewControllerRepresentable {
    let onScanned: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanned: onScanned)
    }

    final class Coordinator: NSObject, ScannerViewControllerDelegate {
        let onScanned: (String) -> Void

        init(onScanned: @escaping (String) -> Void) {
            self.onScanned = onScanned
        }

        func didFindCode(_ code: String) {
            onScanned(code)
        }
    }
}

private protocol ScannerViewControllerDelegate: AnyObject {
    func didFindCode(_ code: String)
}

private final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue = DispatchQueue(label: "com.codeflow.camera.session")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCaptureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async { [weak self] in
            guard let session = self?.captureSession, !session.isRunning else { return }
            session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [weak self] in
            guard let session = self?.captureSession, session.isRunning else { return }
            session.stopRunning()
        }
    }

    private func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            let session = AVCaptureSession()
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                return
            }

            let videoInput: AVCaptureDeviceInput
            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                return
            }

            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            } else {
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                return
            }

            DispatchQueue.main.async {
                let preview = AVCaptureVideoPreviewLayer(session: session)
                preview.frame = self.view.layer.bounds
                preview.videoGravity = .resizeAspectFill
                self.view.layer.addSublayer(preview)
                self.previewLayer = preview
                self.captureSession = session
            }
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }

        delegate?.didFindCode(stringValue)
    }
}
