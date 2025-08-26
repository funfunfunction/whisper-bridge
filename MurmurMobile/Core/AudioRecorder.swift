import AVFoundation
import Foundation
import os.log

final class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    static let shared = AudioRecorder()

    private var audioRecorder: AVAudioRecorder?
    private let recordingURL = FileManager.default.temporaryDirectory.appendingPathComponent("recording.m4a")
    private let logger = OSLog(subsystem: "dev.fff.murmurmobile", category: "AudioRecorder")

    private override init() {
        super.init()
    }

    // MARK: - Recording Controls

    func startRecording() {
        // If already recording, stop first
        if audioRecorder?.isRecording == true { _ = stopRecording() }

        // Configure audio session and request permission
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            os_log("Audio session error: %{public}@", log: logger, type: .error, error.localizedDescription)
        }

        session.requestRecordPermission { [weak self] allowed in
            guard let self else { return }
            DispatchQueue.main.async {
                guard allowed else {
                    os_log("Microphone access denied", log: self.logger, type: .error)
                    return
                }
                self.setupAndStartRecording()
            }
        }
    }

    private func setupAndStartRecording() {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 64000,
        ]

        try? FileManager.default.removeItem(at: recordingURL)

        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            let started = audioRecorder?.record() ?? false
            if started {
                os_log("Recording started: %{public}@", log: logger, type: .info, recordingURL.path)
            } else {
                os_log("Failed to start recording", log: logger, type: .error)
            }
        } catch {
            os_log("Could not start recording: %{public}@", log: logger, type: .error, error.localizedDescription)
        }
    }

    func stopRecording() -> URL? {
        guard let recorder = audioRecorder else {
            os_log("No recorder available", log: logger, type: .error)
            return nil
        }
        recorder.stop()
        audioRecorder = nil

        // Deactivate session (best effort)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        usleep(100_000) // 100ms to flush to disk

        if FileManager.default.fileExists(atPath: recordingURL.path),
           let attrs = try? FileManager.default.attributesOfItem(atPath: recordingURL.path),
           let size = attrs[.size] as? UInt64, size > 0 {
            os_log("Recording size: %d bytes", log: logger, type: .debug, size)
            return recordingURL
        } else {
            os_log("Recording file missing or empty", log: logger, type: .error)
            return nil
        }
    }
}

