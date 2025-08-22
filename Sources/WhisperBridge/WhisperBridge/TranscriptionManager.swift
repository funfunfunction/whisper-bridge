import Foundation
import WhisperKit
import AVFoundation

@MainActor
class TranscriptionManager: ObservableObject {
    @Published var transcriptionText = ""
    @Published var isTranscribing = false
    @Published var transcriptionProgress: Double = 0.0
    @Published var errorMessage: String?
    
    private var whisperKit: WhisperKit?
    private var isModelLoaded = false
    
    init() {
        Task {
            await loadModel()
        }
    }
    
    private func loadModel() async {
        do {
            let modelName = "openai_whisper-base"
            whisperKit = try await WhisperKit(modelFolder: modelName)
            isModelLoaded = true
            print("WhisperKit model loaded successfully: \(modelName)")
        } catch {
            print("Failed to load WhisperKit model: \(error.localizedDescription)")
            errorMessage = "Failed to load transcription model: \(error.localizedDescription)"
            
            do {
                whisperKit = try await WhisperKit(modelFolder: "openai_whisper-tiny")
                isModelLoaded = true
                print("Fallback to tiny model successful")
                errorMessage = nil
            } catch {
                print("Failed to load fallback model: \(error.localizedDescription)")
                errorMessage = "Failed to load any transcription model"
            }
        }
    }
    
    func transcribeAudio(from url: URL) async {
        guard isModelLoaded, let whisperKit = whisperKit else {
            errorMessage = "Transcription model not loaded"
            return
        }
        
        isTranscribing = true
        transcriptionProgress = 0.0
        errorMessage = nil
        transcriptionText = ""
        
        do {
            let transcriptionResult = try await whisperKit.transcribe(audioPath: url.path)
            
            if let segments = transcriptionResult.first?.segments {
                let fullText = segments.compactMap { $0.text }.joined(separator: " ")
                transcriptionText = fullText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            } else {
                transcriptionText = "No transcription available"
            }
            
        } catch {
            print("Transcription failed: \(error.localizedDescription)")
            errorMessage = "Transcription failed: \(error.localizedDescription)"
            transcriptionText = ""
        }
        
        isTranscribing = false
        transcriptionProgress = 1.0
    }
    
    func clearTranscription() {
        transcriptionText = ""
        errorMessage = nil
        transcriptionProgress = 0.0
    }
    
    func getModelStatus() -> String {
        if isModelLoaded {
            return "Model loaded"
        } else if whisperKit == nil {
            return "Loading model..."
        } else {
            return "Model failed to load"
        }
    }
    
    func getAvailableModels() -> [String] {
        return [
            "openai_whisper-tiny",
            "openai_whisper-base", 
            "openai_whisper-small",
            "openai_whisper-medium",
            "openai_whisper-large"
        ]
    }
    
    func switchModel(to modelName: String) async {
        isModelLoaded = false
        whisperKit = nil
        
        do {
            whisperKit = try await WhisperKit(modelFolder: modelName)
            isModelLoaded = true
            errorMessage = nil
            print("Switched to model: \(modelName)")
        } catch {
            print("Failed to switch to model \(modelName): \(error.localizedDescription)")
            errorMessage = "Failed to switch model: \(error.localizedDescription)"
            
            await loadModel()
        }
    }
}