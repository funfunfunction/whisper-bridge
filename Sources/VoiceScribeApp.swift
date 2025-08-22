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