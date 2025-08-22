import AppIntents
import SwiftUI

// Main App Intent for recording
struct RecordVoiceIntent: AppIntent {
    static let title: LocalizedStringResource = "Record Voice Note"
    static let description = IntentDescription("Start recording a voice note for transcription")
    
    // Parameters (optional - for future features)
    @Parameter(title: "Duration", default: 30)
    var duration: Int
    
    @Parameter(title: "Auto-transcribe", default: true)
    var autoTranscribe: Bool
    
    // Main perform function
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Get shared instance of our recording service
        let recorder = AppRecordingService.shared
        
        // Start recording
        let recordingStarted = await recorder.startRecordingFromIntent(duration: duration)
        
        if !recordingStarted {
            throw RecordingError.failedToStart
        }
        
        // Wait for recording to complete (with timeout)
        let audioURL = try await recorder.waitForRecording(timeout: TimeInterval(duration + 5))
        
        // Transcribe if requested
        if autoTranscribe {
            let transcription = try await recorder.transcribeRecording(audioURL: audioURL)
            
            // Save to app's shared container for later access
            UserDefaults.standard.set(transcription, forKey: "lastTranscription")
            
            return .result(value: transcription)
        } else {
            return .result(value: "Recording saved successfully")
        }
    }
    
    static var openAppIntent: OpenIntent {
        OpenIntent()
    }
}

// Quick Record Intent (no parameters)
struct QuickRecordIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Record"
    static let description = IntentDescription("Quickly record and transcribe audio")
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & OpensIntent {
        // This opens the app and starts recording immediately
        return .result(
            value: "Opening VoiceScribe...",
            opensIntent: OpenIntent()
        )
    }
}

// Open App Intent
struct OpenIntent: AppIntent {
    static var title: LocalizedStringResource = "Open VoiceScribe"
    static var description = IntentDescription("Opens the VoiceScribe app")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Trigger recording when opened from shortcut
        NotificationCenter.default.post(name: .startRecordingFromShortcut, object: nil)
        return .result()
    }
}

// App Shortcuts Provider
struct VoiceScribeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: QuickRecordIntent(),
                phrases: [
                    "Record with \\(.applicationName)",
                    "Start \\(.applicationName)",
                    "New voice note in \\(.applicationName)"
                ],
                shortTitle: "Quick Record",
                systemImageName: "mic.circle.fill"
            ),
            
            AppShortcut(
                intent: RecordVoiceIntent(),
                phrases: [
                    "Record voice note with \\(.applicationName)",
                    "Start recording in \\(.applicationName)"
                ],
                shortTitle: "Record Voice Note",
                systemImageName: "waveform.circle.fill"
            )
        ]
    }
}

// Recording Service (Singleton)
class AppRecordingService {
    static let shared = AppRecordingService()
    private let audioRecorder = AudioRecorderManager()
    private let transcriptionManager = TranscriptionManager()
    
    private init() {
        Task {
            await setupServices()
        }
    }
    
    private func setupServices() async {
        await audioRecorder.setupRecording()
        await transcriptionManager.setupWhisperKit()
    }
    
    func startRecordingFromIntent(duration: Int) async -> Bool {
        await MainActor.run {
            audioRecorder.startRecording()
            
            // Auto-stop after duration
            Timer.scheduledTimer(withTimeInterval: TimeInterval(duration), repeats: false) { _ in
                _ = self.audioRecorder.stopRecording()
            }
            
            return true
        }
    }
    
    func waitForRecording(timeout: TimeInterval) async throws -> URL {
        let startTime = Date()
        
        while audioRecorder.isRecording {
            if Date().timeIntervalSince(startTime) > timeout {
                throw RecordingError.timeout
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        guard let url = audioRecorder.stopRecording() else {
            throw RecordingError.noRecording
        }
        
        return url
    }
    
    func transcribeRecording(audioURL: URL) async throws -> String {
        return try await transcriptionManager.transcribe(audioURL: audioURL)
    }
}

// Errors
enum RecordingError: LocalizedError {
    case failedToStart
    case timeout
    case noRecording
    
    var errorDescription: String? {
        switch self {
        case .failedToStart: return "Failed to start recording"
        case .timeout: return "Recording timeout"
        case .noRecording: return "No recording found"
        }
    }
}

// Notification extension
extension Notification.Name {
    static let startRecordingFromShortcut = Notification.Name("startRecordingFromShortcut")
}