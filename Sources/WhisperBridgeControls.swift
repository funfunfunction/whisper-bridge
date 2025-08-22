import WidgetKit
import SwiftUI
import AppIntents

// Control Widget for iOS 18 Control Center
@available(iOS 18.0, *)
struct WhisperBridgeControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.yourname.WhisperBridge.RecordControl"
        ) {
            ControlWidgetButton(action: QuickRecordIntent()) {
                Label("Record", systemImage: "mic.fill")
            }
        }
        .displayName("Voice Record")
        .description("Quick record a voice note")
    }
}

// Toggle Control (for recording state)
@available(iOS 18.0, *)
struct RecordingToggleControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: "com.yourname.WhisperBridge.RecordingToggle",
            intent: RecordVoiceIntent.self
        ) { configuration in
            ControlWidgetToggle(
                isOn: false,  // This would need to read from app state
                action: {
                    // Toggle action
                }
            ) {
                Label("Recording", systemImage: "waveform")
            }
        }
        .displayName("Voice Recording")
        .description("Start/stop voice recording")
    }
}

// Enhanced Control with Recording Status
@available(iOS 18.0, *)
struct VoiceRecordingStatusControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.yourname.WhisperBridge.StatusControl"
        ) {
            ControlWidgetButton(action: QuickRecordIntent()) {
                HStack {
                    Image(systemName: "mic.circle.fill")
                        .foregroundColor(.red)
                    Text("WhisperBridge")
                        .font(.caption)
                }
            }
        }
        .displayName("WhisperBridge Status")
        .description("View recording status and quick record")
    }
}

// Interactive Control with Duration Selection
@available(iOS 18.0, *)
struct VoiceRecordingDurationControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: "com.yourname.WhisperBridge.DurationControl",
            intent: RecordVoiceIntent.self
        ) { configuration in
            ControlWidgetButton(action: configuration.intent) {
                VStack(spacing: 2) {
                    Image(systemName: "timer")
                        .font(.caption)
                    Text("\(configuration.intent.duration)s")
                        .font(.caption2)
                }
            }
        }
        .displayName("Timed Recording")
        .description("Record with custom duration")
    }
}

// Widget Bundle
@available(iOS 18.0, *)
struct WhisperBridgeWidgetBundle: WidgetBundle {
    var body: some Widget {
        WhisperBridgeControl()
        RecordingToggleControl()
        VoiceRecordingStatusControl()
        VoiceRecordingDurationControl()
    }
}

// MARK: - Supporting Views and Intents

// Custom Intent for Duration-based Recording
struct TimedRecordIntent: AppIntent {
    static let title: LocalizedStringResource = "Timed Record"
    static let description = IntentDescription("Record for a specific duration")
    
    @Parameter(title: "Duration (seconds)", default: 30)
    var duration: Int
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let recorder = AppRecordingService.shared
        
        let recordingStarted = await recorder.startRecordingFromIntent(duration: duration)
        
        if !recordingStarted {
            throw RecordingError.failedToStart
        }
        
        let audioURL = try await recorder.waitForRecording(timeout: TimeInterval(duration + 5))
        let transcription = try await recorder.transcribeRecording(audioURL: audioURL)
        
        return .result(value: transcription)
    }
}

// Status Intent for Control Center
struct RecordingStatusIntent: AppIntent {
    static let title: LocalizedStringResource = "Check Recording Status"
    static let description = IntentDescription("Check if app is currently recording")
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let isRecording = AppRecordingService.shared.audioRecorder.isRecording
        let status = isRecording ? "Recording in progress..." : "Ready to record"
        return .result(value: status)
    }
}

// MARK: - Control Center Integration Helper

@available(iOS 18.0, *)
extension WhisperBridgeWidgetBundle {
    // Helper to register widgets with the system
    static func registerControlCenterWidgets() {
        // This would be called from the main app to ensure widgets are registered
        print("WhisperBridge Control Center widgets registered")
    }
}

// MARK: - Legacy iOS Support (for non-iOS 18 devices)

// Fallback struct for devices that don't support Control Center widgets
struct WhisperBridgeLegacyWidget {
    static func isControlCenterSupported() -> Bool {
        if #available(iOS 18.0, *) {
            return true
        } else {
            return false
        }
    }
    
    static func showUnsupportedAlert() {
        print("Control Center widgets require iOS 18 or later")
    }
}

// MARK: - Widget Configuration

// Helper for widget configuration in Xcode
extension WhisperBridgeControl {
    static func configurationInstructions() -> String {
        return """
        To add WhisperBridge controls to Control Center:
        1. Go to Settings → Control Center
        2. Under "More Controls", find "Voice Record"
        3. Tap the green + to add it
        4. Customize position by dragging in "Included Controls"
        
        For Action Button (iPhone 15 Pro+):
        1. Go to Settings → Action Button
        2. Swipe to "Controls" or "Shortcut"
        3. Select "Voice Record" or create custom shortcut
        """
    }
}