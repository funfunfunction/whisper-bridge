//
//  SpeechRecognitionManager.swift
//  WhisperBridge
//
//  Created by David Jurelius on 2025-08-22.
//

import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechRecognitionManager: ObservableObject {
    @Published var transcriptionText = ""
    @Published var isTranscribing = false
    @Published var transcriptionProgress: Double = 0.0
    @Published var errorMessage: String?
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechURLRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    init() {
        speechRecognizer = SFSpeechRecognizer()
    }
    
    func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                DispatchQueue.main.async {
                    switch authStatus {
                    case .authorized:
                        print("Speech recognition authorized")
                        continuation.resume(returning: true)
                    case .denied:
                        print("Speech recognition denied")
                        self.errorMessage = "Speech recognition access denied"
                        continuation.resume(returning: false)
                    case .restricted:
                        print("Speech recognition restricted")
                        self.errorMessage = "Speech recognition restricted on this device"
                        continuation.resume(returning: false)
                    case .notDetermined:
                        print("Speech recognition not determined")
                        self.errorMessage = "Speech recognition permission not determined"
                        continuation.resume(returning: false)
                    @unknown default:
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    func transcribeAudio(from url: URL) async {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition not available"
            return
        }
        
        // Check authorization status
        let isAuthorized = await requestAuthorization()
        guard isAuthorized else {
            return
        }
        
        isTranscribing = true
        transcriptionProgress = 0.0
        errorMessage = nil
        transcriptionText = ""
        
        // Cancel any ongoing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create recognition request
        recognitionRequest = SFSpeechURLRecognitionRequest(url: url)
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create speech recognition request"
            isTranscribing = false
            return
        }
        
        // Configure request for best accuracy
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Speech recognition failed: \(error.localizedDescription)"
                    self.isTranscribing = false
                    self.transcriptionProgress = 0.0
                    print("Speech recognition error: \(error)")
                    return
                }
                
                if let result = result {
                    // Update transcription text with best result
                    self.transcriptionText = result.bestTranscription.formattedString
                    
                    // Update progress based on completion
                    if result.isFinal {
                        self.isTranscribing = false
                        self.transcriptionProgress = 1.0
                        print("Final transcription: \(self.transcriptionText)")
                    } else {
                        // Show partial progress
                        self.transcriptionProgress = 0.7
                        print("Partial transcription: \(self.transcriptionText)")
                    }
                }
            }
        }
    }
    
    func clearTranscription() {
        transcriptionText = ""
        errorMessage = nil
        transcriptionProgress = 0.0
        
        // Cancel any ongoing recognition
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isTranscribing = false
    }
    
    func getModelStatus() -> String {
        guard let speechRecognizer = speechRecognizer else {
            return "Speech recognition not available"
        }
        
        if speechRecognizer.isAvailable {
            return "Ready for speech recognition"
        } else {
            return "Speech recognition unavailable"
        }
    }
    
    func isAuthorizationStatusAuthorized() -> Bool {
        return SFSpeechRecognizer.authorizationStatus() == .authorized
    }
    
    deinit {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
}