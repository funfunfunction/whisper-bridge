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