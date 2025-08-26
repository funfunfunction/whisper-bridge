import SwiftUI
import AVFoundation
import UIKit

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    @State private var isRecording = false
    @State private var transcription = ""
    @State private var isProcessing = false
    @State private var errorMessage: String? = nil
    @State private var showingSettings = false
    @State private var hasValidAPIKey = false

    @State private var autoStopTask: Task<Void, Never>? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack {
                    Text("MurmurMobile")
                        .font(.largeTitle).bold()
                    if !hasValidAPIKey {
                        Text("API Key Required").foregroundColor(.orange).font(.caption)
                    }
                    Spacer()
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear").font(.title2)
                    }
                }
                .padding(.top)

                Spacer()

                Button(action: toggleRecording) {
                    VStack {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 96, height: 96)
                            .foregroundColor(isRecording ? .red : .blue)
                        Text(isRecording ? "Stop Recording" : "Start Recording").font(.headline)
                    }
                }
                .disabled(isProcessing)

                if isProcessing {
                    ProgressView("Transcribing...").padding()
                }

                if let error = errorMessage {
                    Text(error).foregroundColor(.red).multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if !transcription.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transcription:").font(.headline)
                        ScrollView {
                            Text(transcription)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                        Text("✓ Copied to clipboard").font(.caption).foregroundColor(.green)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .onAppear {
                hasValidAPIKey = KeychainManager.shared.hasAPIKey()
            }
            .onChange(of: appState.pendingAction) { newValue in
                guard let action = newValue else { return }
                startRecording()
                if let seconds = action.autoStopSeconds {
                    scheduleAutoStop(after: seconds)
                }
                // clear action to avoid re-triggering
                appState.pendingAction = nil
            }
            .sheet(isPresented: $showingSettings) {
                NavigationView {
                    SettingsView(onKeyChange: {
                        hasValidAPIKey = KeychainManager.shared.hasAPIKey()
                    })
                    .navigationTitle("Settings")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingSettings = false } } }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func toggleRecording() {
        if isRecording { stopRecording() } else { startRecording() }
    }

    private func startRecording() {
        errorMessage = nil
        transcription = ""
        isRecording = true

        // Request mic permission and begin
        AudioRecorder.shared.startRecording()
    }

    private func stopRecording() {
        isRecording = false
        isProcessing = true
        autoStopTask?.cancel()
        autoStopTask = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard let url = AudioRecorder.shared.stopRecording() else {
                isProcessing = false
                errorMessage = "No recording was captured."
                return
            }
            // Ensure API key exists
            hasValidAPIKey = KeychainManager.shared.hasAPIKey()
            guard hasValidAPIKey else {
                isProcessing = false
                errorMessage = "Add your ElevenLabs API key in Settings."
                showingSettings = true
                return
            }

            TranscriptionService.shared.transcribeAudio(fileURL: url) { result in
                switch result {
                case .success(let text):
                    transcription = text
                    UIPasteboard.general.string = text
                    errorMessage = nil
                    // If a return URL was provided (or stored), jump back
                    if let ret = appState.returnURL {
                        UIApplication.shared.open(ret)
                        appState.returnURL = nil
                    } else if let stored = UserDefaults.standard.string(forKey: "returnURL"),
                              let ret = URL(string: stored), !stored.isEmpty {
                        UIApplication.shared.open(ret)
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
                isProcessing = false
            }
        }
    }

    private func scheduleAutoStop(after seconds: Int) {
        autoStopTask?.cancel()
        autoStopTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
            if !Task.isCancelled, isRecording {
                stopRecording()
            }
        }
    }
}
