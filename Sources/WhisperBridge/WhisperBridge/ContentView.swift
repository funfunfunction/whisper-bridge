//
//  ContentView.swift
//  WhisperBridge
//
//  Created by David Jurelius on 2025-08-22.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorderManager()
    @StateObject private var speechRecognitionManager = SpeechRecognitionManager()
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                StatusCardView(
                    isRecording: audioRecorder.isRecording,
                    isTranscribing: speechRecognitionManager.isTranscribing,
                    modelStatus: speechRecognitionManager.getModelStatus()
                )
                
                AudioVisualizerView(audioLevels: audioRecorder.audioLevels)
                
                RecordButtonView(
                    isRecording: audioRecorder.isRecording,
                    isTranscribing: transcriptionManager.isTranscribing,
                    action: {
                        if audioRecorder.isRecording {
                            stopRecordingAndTranscribe()
                        } else {
                            startRecording()
                        }
                    }
                )
                
                TranscriptionView(
                    text: transcriptionManager.transcriptionText,
                    isTranscribing: transcriptionManager.isTranscribing,
                    progress: transcriptionManager.transcriptionProgress,
                    errorMessage: transcriptionManager.errorMessage
                )
                
                if !transcriptionManager.transcriptionText.isEmpty {
                    ActionButtonsView(
                        onShare: { showingShareSheet = true },
                        onClear: { transcriptionManager.clearTranscription() }
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("WhisperBridge")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [transcriptionManager.transcriptionText])
            }
        }
    }
    
    private func startRecording() {
        transcriptionManager.clearTranscription()
        audioRecorder.startRecording()
    }
    
    private func stopRecordingAndTranscribe() {
        audioRecorder.stopRecording()
        
        if let recordingURL = audioRecorder.getRecordingURL() {
            Task {
                await transcriptionManager.transcribeAudio(from: recordingURL)
                audioRecorder.cleanupOldRecordings()
            }
        }
    }
}

struct StatusCardView: View {
    let isRecording: Bool
    let isTranscribing: Bool
    let modelStatus: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                Text(statusText)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack {
                Text(modelStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        if isRecording {
            return .red
        } else if isTranscribing {
            return .orange
        } else {
            return .green
        }
    }
    
    private var statusText: String {
        if isRecording {
            return "Recording..."
        } else if isTranscribing {
            return "Transcribing..."
        } else {
            return "Ready"
        }
    }
}

struct AudioVisualizerView: View {
    let audioLevels: Float
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue.opacity(audioLevels > Float(index) / 20.0 ? 0.8 : 0.2))
                    .frame(width: 4, height: CGFloat(10 + index * 2))
                    .animation(.easeInOut(duration: 0.1), value: audioLevels)
            }
        }
        .frame(height: 50)
    }
}

struct RecordButtonView: View {
    let isRecording: Bool
    let isTranscribing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.blue)
                    .frame(width: 100, height: 100)
                    .scaleEffect(isRecording ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isRecording)
                
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.title)
                    .foregroundColor(.white)
            }
        }
        .disabled(isTranscribing)
        .opacity(isTranscribing ? 0.6 : 1.0)
    }
}

struct TranscriptionView: View {
    let text: String
    let isTranscribing: Bool
    let progress: Double
    let errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transcription")
                    .font(.headline)
                Spacer()
                if isTranscribing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            ScrollView {
                Text(text.isEmpty && !isTranscribing ? "Transcribed text will appear here..." : text)
                    .font(.body)
                    .foregroundColor(text.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(minHeight: 120)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct ActionButtonsView: View {
    let onShare: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button("Share", action: onShare)
                .buttonStyle(.bordered)
            
            Button("Clear", action: onClear)
                .buttonStyle(.bordered)
                .tint(.red)
            
            Spacer()
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}
