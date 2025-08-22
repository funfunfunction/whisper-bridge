# Phase 1: Building an iOS Voice Recording App with WhisperKit & Shortcuts

## Overview
This guide will walk you through building a voice recording iOS app that:
- Records audio when triggered (via app button or Shortcuts)
- Transcribes audio using WhisperKit (on-device)
- Shares transcribed text to other apps
- Works with iPhone Action Button through Shortcuts

**Time estimate:** 2-3 weeks for a junior developer
**Required:** Mac with Xcode 15+, iPhone with iOS 17+, Apple Developer Account ($99/year)

---

## Part 1: Project Setup (Day 1)

### Step 1: Create New Xcode Project

1. Open Xcode → Click "Create New Project"
2. Choose: **iOS** → **App** → Click "Next"
3. Configure project:
   - **Product Name:** `VoiceScribe`
   - **Team:** Select your Apple Developer account
   - **Organization Identifier:** `com.yourname` (replace with your identifier)
   - **Bundle Identifier:** Will auto-fill as `com.yourname.VoiceScribe`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None (uncheck all options)
4. Click "Next" → Choose location → Click "Create"

### Step 2: Configure Project Settings

1. Select project file in navigator (top blue icon)
2. Under **TARGETS** → Select "VoiceScribe"
3. Go to **Signing & Capabilities** tab:
   - Ensure "Automatically manage signing" is checked
   - Team should be your developer account
4. Click **"+ Capability"** button and add:
   - **Background Modes** (check "Audio, AirPlay, and Picture in Picture")
   - **App Groups** (we'll configure this later)

### Step 3: Add Privacy Permissions

1. Select **Info.plist** in navigator
2. Right-click → "Add Row" → Add these keys:

```xml
NSMicrophoneUsageDescription
String: "VoiceScribe needs microphone access to record your voice for transcription."

NSSpeechRecognitionUsageDescription  
String: "VoiceScribe uses speech recognition to transcribe your recordings."
```

### Step 4: Add WhisperKit Package

1. In Xcode: **File** → **Add Package Dependencies**
2. Enter URL: `https://github.com/argmaxinc/WhisperKit`
3. Click "Add Package"
4. Dependency Rule: **Up to Next Major Version** (1.0.0 < 2.0.0)
5. Click "Add Package" → Wait for download
6. Select "WhisperKit" → Add to "VoiceScribe" target → Click "Add Package"

---

## Part 2: Create Basic UI (Day 2)

### Step 1: Create Main Recording View

Replace contents of `ContentView.swift` with:

```swift
import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorderManager()
    @StateObject private var transcriptionManager = TranscriptionManager()
    @State private var transcribedText = ""
    @State private var isTranscribing = false
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Status Section
                StatusCard(
                    isRecording: audioRecorder.isRecording,
                    isTranscribing: isTranscribing
                )
                
                // Main Record Button
                RecordButton(
                    isRecording: audioRecorder.isRecording,
                    action: handleRecordButtonTap
                )
                
                // Transcribed Text Display
                TranscriptionView(
                    text: transcribedText,
                    isTranscribing: isTranscribing
                )
                
                // Action Buttons
                HStack(spacing: 20) {
                    Button(action: clearTranscription) {
                        Label("Clear", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(transcribedText.isEmpty)
                    
                    Button(action: { showingShareSheet = true }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(transcribedText.isEmpty)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("VoiceScribe")
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(text: transcribedText)
            }
            .onAppear {
                Task {
                    await setupManagers()
                }
            }
        }
    }
    
    private func handleRecordButtonTap() {
        if audioRecorder.isRecording {
            stopRecordingAndTranscribe()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        audioRecorder.startRecording()
    }
    
    private func stopRecordingAndTranscribe() {
        guard let audioURL = audioRecorder.stopRecording() else { return }
        
        isTranscribing = true
        Task {
            do {
                let text = try await transcriptionManager.transcribe(audioURL: audioURL)
                await MainActor.run {
                    self.transcribedText = text
                    self.isTranscribing = false
                }
            } catch {
                await MainActor.run {
                    self.transcribedText = "Transcription failed: \(error.localizedDescription)"
                    self.isTranscribing = false
                }
            }
        }
    }
    
    private func clearTranscription() {
        transcribedText = ""
    }
    
    private func setupManagers() async {
        await audioRecorder.setupRecording()
        await transcriptionManager.setupWhisperKit()
    }
}
```

### Step 2: Create UI Components

Create a new file `UIComponents.swift`:

```swift
import SwiftUI

// Status Card Component
struct StatusCard: View {
    let isRecording: Bool
    let isTranscribing: Bool
    
    var statusText: String {
        if isRecording {
            return "Recording..."
        } else if isTranscribing {
            return "Transcribing..."
        } else {
            return "Ready to Record"
        }
    }
    
    var statusColor: Color {
        if isRecording {
            return .red
        } else if isTranscribing {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 8)
                        .scaleEffect(isRecording ? 2.0 : 1.0)
                        .opacity(isRecording ? 0 : 1)
                        .animation(
                            isRecording ? .easeOut(duration: 1.0).repeatForever(autoreverses: false) : .default,
                            value: isRecording
                        )
                )
            
            Text(statusText)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Record Button Component
struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.blue)
                    .frame(width: 120, height: 120)
                
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isRecording ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isRecording)
    }
}

// Transcription Display Component
struct TranscriptionView: View {
    let text: String
    let isTranscribing: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Transcription")
                        .font(.headline)
                    Spacer()
                    if isTranscribing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    }
                }
                
                if text.isEmpty && !isTranscribing {
                    Text("Your transcribed text will appear here")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    Text(text)
                        .font(.body)
                        .textSelection(.enabled)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 200)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// Share Sheet Component
struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
```

---

## Part 3: Audio Recording Manager (Day 3)

Create a new file `AudioRecorderManager.swift`:

```swift
import AVFoundation
import SwiftUI

class AudioRecorderManager: NSObject, ObservableObject {
    @Published var isRecording = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    private var recordingURL: URL?
    
    override init() {
        super.init()
    }
    
    // Setup recording session
    func setupRecording() async {
        audioSession = AVAudioSession.sharedInstance()
        
        // Request microphone permission
        await requestMicrophonePermission()
        
        do {
            // Configure audio session for recording
            try audioSession?.setCategory(.playAndRecord, mode: .default)
            try audioSession?.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // Request microphone permission
    private func requestMicrophonePermission() async {
        let permission = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        if !permission {
            print("Microphone permission denied")
        }
    }
    
    // Start recording
    func startRecording() {
        // Create unique filename with timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "recording_\(timestamp).m4a"
        
        // Get documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                     in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent(fileName)
        
        // Configure recording settings optimized for speech
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,  // 16kHz optimal for speech
            AVNumberOfChannelsKey: 1,   // Mono for speech
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            // Create and start recorder
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            DispatchQueue.main.async {
                self.isRecording = true
            }
            
            print("Recording started: \(fileName)")
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    // Stop recording and return file URL
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        audioRecorder = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        print("Recording stopped: \(recordingURL?.lastPathComponent ?? "")")
        return recordingURL
    }
    
    // Clean up old recordings (call periodically)
    func cleanupOldRecordings(daysToKeep: Int = 7) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                     in: .userDomainMask)[0]
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsPath, 
                                                           includingPropertiesForKeys: [.creationDateKey])
            let recordingFiles = files.filter { $0.lastPathComponent.hasPrefix("recording_") }
            
            let cutoffDate = Date().addingTimeInterval(-Double(daysToKeep * 24 * 60 * 60))
            
            for file in recordingFiles {
                let attributes = try fileManager.attributesOfItem(atPath: file.path)
                if let creationDate = attributes[.creationDate] as? Date,
                   creationDate < cutoffDate {
                    try fileManager.removeItem(at: file)
                    print("Deleted old recording: \(file.lastPathComponent)")
                }
            }
        } catch {
            print("Error cleaning up recordings: \(error)")
        }
    }
}

// AVAudioRecorderDelegate
extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
            DispatchQueue.main.async {
                self.isRecording = false
            }
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Encoding error: \(error?.localizedDescription ?? "Unknown")")
    }
}
```

---

## Part 4: WhisperKit Integration (Day 4-5)

Create a new file `TranscriptionManager.swift`:

```swift
import Foundation
import WhisperKit
import CoreML

@MainActor
class TranscriptionManager: ObservableObject {
    private var whisperKit: WhisperKit?
    @Published var isModelLoaded = false
    @Published var downloadProgress: Float = 0
    @Published var modelSize: String = "base" // base, small, medium, large
    
    // Initialize WhisperKit
    func setupWhisperKit() async {
        do {
            // Use base model for balance of speed and accuracy
            // Options: "tiny", "base", "small", "medium", "large"
            whisperKit = try await WhisperKit(
                model: modelSize,
                download: true,
                modelFolder: getModelFolder(),
                computeOptions: ModelComputeOptions(
                    audioEncoder: MLComputeUnits.cpuAndNeuralEngine,
                    textDecoder: MLComputeUnits.cpuAndNeuralEngine
                )
            )
            
            isModelLoaded = true
            print("WhisperKit loaded successfully with \(modelSize) model")
        } catch {
            print("Failed to initialize WhisperKit: \(error)")
            // Fallback to tiny model if preferred model fails
            if modelSize != "tiny" {
                modelSize = "tiny"
                await setupWhisperKit()
            }
        }
    }
    
    // Get or create model folder
    private func getModelFolder() -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                     in: .userDomainMask).first
        let modelFolder = documentsPath?.appendingPathComponent("WhisperKitModels")
        
        // Create folder if it doesn't exist
        if let folder = modelFolder {
            try? FileManager.default.createDirectory(at: folder, 
                                                    withIntermediateDirectories: true)
        }
        
        return modelFolder
    }
    
    // Main transcription function
    func transcribe(audioURL: URL) async throws -> String {
        guard let whisperKit = whisperKit else {
            // If model not loaded, try to load it
            await setupWhisperKit()
            guard let whisperKit = whisperKit else {
                throw TranscriptionError.modelNotLoaded
            }
            self.whisperKit = whisperKit
        }
        
        print("Starting transcription of: \(audioURL.lastPathComponent)")
        
        // Transcribe audio file
        let result = try await whisperKit.transcribe(
            audioPath: audioURL.path,
            decodeOptions: DecodingOptions(
                language: "en",  // Set to nil for auto-detection
                temperature: 0.0,  // 0 for deterministic, higher for variety
                temperatureFallbackCount: 3,
                sampleLength: 224,  // Optimal for most audio
                topK: 5,
                usePrefillPrompt: true,
                usePrefillCache: true,
                skipSpecialTokens: true,
                withoutTimestamps: false
            )
        )
        
        // Combine all segments into final text
        let transcription = result?.text ?? ""
        
        print("Transcription complete: \(transcription.prefix(100))...")
        
        return transcription.isEmpty ? "No speech detected" : transcription
    }
    
    // Alternative: Transcribe with progress callback
    func transcribeWithProgress(
        audioURL: URL,
        progressHandler: @escaping (Float) -> Void
    ) async throws -> String {
        guard let whisperKit = whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }
        
        var lastProgress: Float = 0
        
        let result = try await whisperKit.transcribe(
            audioPath: audioURL.path,
            decodeOptions: DecodingOptions(language: "en"),
            callback: { progress in
                DispatchQueue.main.async {
                    progressHandler(progress.fractionCompleted)
                }
                return true // Continue transcription
            }
        )
        
        return result?.text ?? "No speech detected"
    }
    
    // Get available models
    func getAvailableModels() -> [String] {
        return ["tiny", "base", "small", "medium", "large"]
    }
    
    // Estimate model size in MB
    func getModelSizeEstimate(for model: String) -> String {
        switch model {
        case "tiny": return "39 MB"
        case "base": return "74 MB"
        case "small": return "244 MB"
        case "medium": return "769 MB"
        case "large": return "1550 MB"
        default: return "Unknown"
        }
    }
}

// Custom errors
enum TranscriptionError: LocalizedError {
    case modelNotLoaded
    case transcriptionFailed
    case audioFileNotFound
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "WhisperKit model not loaded. Please wait for model to download."
        case .transcriptionFailed:
            return "Failed to transcribe audio. Please try again."
        case .audioFileNotFound:
            return "Audio file not found."
        }
    }
}

// Progress tracking structure
struct TranscriptionProgress {
    let fractionCompleted: Float
    let currentSegment: Int
    let totalSegments: Int
}
```

---

## Part 5: Shortcuts Integration (Day 6-7)

### Step 1: Create App Intent

Create a new file `RecordVoiceIntent.swift`:

```swift
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
struct QuickRecordIntent: AudioRecordingIntent {
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
struct OpenIntent: OpenIntent {
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
        AppShortcut(
            intent: QuickRecordIntent(),
            phrases: [
                "Record with \(.applicationName)",
                "Start \(.applicationName)",
                "New voice note in \(.applicationName)"
            ],
            shortTitle: "Quick Record",
            systemImageName: "mic.circle.fill"
        )
        
        AppShortcut(
            intent: RecordVoiceIntent(),
            phrases: [
                "Record voice note with \(.applicationName)",
                "Start recording in \(.applicationName)"
            ],
            shortTitle: "Record Voice Note",
            systemImageName: "waveform.circle.fill"
        )
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
```

### Step 2: Create Control for Control Center

Create a new file `VoiceScribeControls.swift`:

```swift
import WidgetKit
import SwiftUI
import AppIntents

// Control Widget for iOS 18 Control Center
@available(iOS 18.0, *)
struct VoiceScribeControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.yourname.VoiceScribe.RecordControl"
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
            kind: "com.yourname.VoiceScribe.RecordingToggle",
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

// Widget Bundle
@available(iOS 18.0, *)
struct VoiceScribeWidgetBundle: WidgetBundle {
    var body: some Widget {
        VoiceScribeControl()
        RecordingToggleControl()
    }
}
```

### Step 3: Update App file

Update your `VoiceScribeApp.swift`:

```swift
import SwiftUI

@main
struct VoiceScribeApp: App {
    @StateObject private var audioRecorder = AudioRecorderManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: .startRecordingFromShortcut)) { _ in
                    // Start recording when launched from shortcut
                    handleShortcutLaunch()
                }
        }
    }
    
    private func handleShortcutLaunch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Slight delay to ensure UI is ready
            audioRecorder.startRecording()
            
            // Show alert or notification
            showRecordingStartedNotification()
        }
    }
    
    private func showRecordingStartedNotification() {
        // You can implement local notification here
        print("Recording started from shortcut")
    }
}
```

---

## Part 6: Testing & Debugging (Day 8)

### Step 1: Test Checklist

Create a test plan covering these scenarios:

```markdown
## Testing Checklist

### Basic Functionality
- [ ] App launches without crashing
- [ ] Microphone permission request appears
- [ ] Record button starts/stops recording
- [ ] Audio file is created in documents
- [ ] WhisperKit model downloads on first launch
- [ ] Transcription produces text output
- [ ] Share button opens share sheet
- [ ] Clear button clears transcription

### Shortcuts Integration
- [ ] App appears in Shortcuts app
- [ ] "Quick Record" shortcut can be added
- [ ] Shortcut launches app
- [ ] Recording starts from shortcut
- [ ] Control appears in Control Center (iOS 18)
- [ ] Action Button can trigger shortcut

### Edge Cases
- [ ] App handles no microphone permission
- [ ] App handles no internet (for model download)
- [ ] Recording continues in background
- [ ] Long recordings (>5 minutes) work
- [ ] App handles low storage space
- [ ] Transcription handles silence
- [ ] Transcription handles multiple languages
```

### Step 2: Common Issues & Solutions

```swift
// Add this debug helper to your AudioRecorderManager
extension AudioRecorderManager {
    func debugPrintAudioSettings() {
        print("=== Audio Debug Info ===")
        print("Session Category: \(audioSession?.category.rawValue ?? "nil")")
        print("Is Recording: \(isRecording)")
        print("Recording URL: \(recordingURL?.absoluteString ?? "nil")")
        
        if let url = recordingURL, FileManager.default.fileExists(atPath: url.path) {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                print("File Size: \(fileSize) bytes")
            } catch {
                print("Error getting file info: \(error)")
            }
        }
    }
}

// Add this to TranscriptionManager for debugging
extension TranscriptionManager {
    func debugPrintModelInfo() {
        print("=== WhisperKit Debug Info ===")
        print("Model Loaded: \(isModelLoaded)")
        print("Model Size: \(modelSize)")
        print("Model Folder: \(getModelFolder()?.path ?? "nil")")
        
        if let folder = getModelFolder() {
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: folder, 
                    includingPropertiesForKeys: nil)
                print("Model Files: \(contents.map { $0.lastPathComponent })")
            } catch {
                print("Error reading model folder: \(error)")
            }
        }
    }
}
```

---

## Part 7: Configure Action Button (Day 9)

### Device Setup Instructions

```markdown
## Setting Up Action Button Integration

### On iPhone 15 Pro/16 Pro:

1. **Add Shortcut to Action Button:**
   - Go to Settings → Action Button
   - Swipe to "Shortcut"
   - Tap "Choose a Shortcut"
   - Select "Quick Record" from VoiceScribe
   - Tap "Done"

2. **Alternative: Control Center Method (iOS 18):**
   - Go to Settings → Control Center
   - Under "More Controls", find "Voice Record"
   - Tap the green + to add it
   - Go to Settings → Action Button
   - Swipe to "Controls"
   - Select "Voice Record"

3. **Test the Integration:**
   - Press and hold Action Button
   - VoiceScribe should launch and start recording
   - Press Action Button again to stop

### Troubleshooting:
- If shortcut doesn't appear: Open Shortcuts app → Gallery → Search "VoiceScribe"
- If control doesn't appear: Rebuild app with iOS 18 SDK
- If nothing happens: Check Settings → Screen Time → App Limits
```

---

## Part 8: Optimization & Polish (Day 10)

### Performance Improvements

```swift
// Add to TranscriptionManager for better performance
extension TranscriptionManager {
    // Pre-warm the model
    func prewarmModel() async {
        guard let whisperKit = whisperKit else { return }
        
        // Create a short silent audio to pre-warm the model
        let silentAudioURL = createSilentAudio(duration: 0.1)
        _ = try? await transcribe(audioURL: silentAudioURL)
        
        print("Model pre-warmed and ready")
    }
    
    private func createSilentAudio(duration: TimeInterval) -> URL {
        // Implementation for creating silent audio file
        // This helps with first-transcription performance
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                     in: .userDomainMask)[0]
        let url = documentsPath.appendingPathComponent("silence.m4a")
        // ... create silent audio file
        return url
    }
}
```

### Add App Icon & Launch Screen

1. **App Icon:**
   - Open Assets.xcassets
   - Click on AppIcon
   - Add icon images for all required sizes
   - Use SF Symbols for quick prototype: `mic.circle.fill`

2. **Launch Screen:**
   - Keep it simple with app name and icon
   - Match your app's color scheme

---

## Part 9: Build & Deploy (Day 11-12)

### Build Configuration

```markdown
## Deployment Checklist

### Before Building:
1. Set version number (1.0.0)
2. Set build number (1)
3. Select "Any iOS Device" as build target
4. Product → Archive
5. Distribute App → App Store Connect

### App Store Preparation:
1. Create app in App Store Connect
2. Add screenshots (use Simulator)
3. Write description emphasizing:
   - On-device transcription (privacy)
   - Action Button support
   - Shortcuts integration
4. Select category: Productivity
5. Set age rating: 4+

### TestFlight:
1. Upload build from Xcode
2. Add internal testers
3. Test on real devices
4. Collect feedback for 1 week
```

---

## Part 10: Next Steps & Improvements

### Future Enhancements (Phase 2)

```swift
// Features to add after Phase 1 is working:

// 1. Cloud backup with iCloud
extension TranscriptionManager {
    func saveToiCloud(text: String) {
        // Use CloudKit or iCloud Documents
    }
}

// 2. History view
struct HistoryView: View {
    @State private var recordings: [Recording] = []
    // Show list of past recordings
}

// 3. Settings screen
struct SettingsView: View {
    @AppStorage("modelSize") private var modelSize = "base"
    @AppStorage("autoTranscribe") private var autoTranscribe = true
    // User preferences
}

// 4. Export options
extension ContentView {
    func exportAsTextFile() { }
    func exportAsPDF() { }
    func sendToNotes() { }
}
```

---

## Troubleshooting Guide

### Common Problems & Solutions

**Problem: WhisperKit model won't download**
```swift
// Solution: Add network check
func checkNetworkAndDownload() async {
    let config = URLSessionConfiguration.default
    config.allowsCellularAccess = true
    config.allowsExpensiveNetworkAccess = true
    // Retry download with better config
}
```

**Problem: Recording stops when app backgrounds**
```markdown
Solution: Ensure Background Modes capability is enabled
- Project Settings → Capabilities → Background Modes
- Check "Audio, AirPlay, and Picture in Picture"
```

**Problem: Shortcuts don't appear**
```swift
// Solution: Register shortcuts in App init
init() {
    VoiceScribeShortcuts.updateAppShortcutParameters()
}
```

**Problem: Transcription is slow**
```markdown
Solutions:
1. Use smaller model (tiny/base)
2. Pre-warm model on app launch
3. Limit recording length
4. Show progress indicator
```

---

## Final Testing Protocol

Before considering Phase 1 complete:

1. **Fresh Install Test:** Delete app, reinstall, test all features
2. **Permissions Test:** Deny microphone, verify error handling
3. **Shortcuts Test:** Add all shortcuts, test Action Button
4. **Performance Test:** Record 5-minute audio, measure transcription time
5. **Background Test:** Start recording, background app, verify continues
6. **Share Test:** Share to Notes, Messages, Mail
7. **Storage Test:** Record 10 times, verify cleanup works
8. **Model Test:** Try different model sizes

---

## Success Metrics

Your Phase 1 is complete when:
- ✅ App records audio reliably
- ✅ WhisperKit transcribes accurately
- ✅ Shortcuts work from Action Button
- ✅ Text can be shared to other apps
- ✅ App doesn't crash in 30 minutes of testing
- ✅ Recording works in background
- ✅ UI is responsive during transcription

## Support Resources

- [WhisperKit Documentation](https://github.com/argmaxinc/WhisperKit)
- [Apple Shortcuts Guide](https://developer.apple.com/documentation/appintents)
- [AVAudioRecorder Reference](https://developer.apple.com/documentation/avfaudio/avaudiorecorder)
- [iOS 18 Controls Documentation](https://developer.apple.com/documentation/widgetkit/controls)

---

**Congratulations!** You've built a fully functional voice transcription app with Action Button support! 🎉
