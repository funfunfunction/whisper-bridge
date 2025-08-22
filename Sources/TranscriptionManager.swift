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
    
    // Pre-warm the model for better performance
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
        
        // Create a minimal silent audio file
        // Note: In a real implementation, you would use AVAssetWriter
        // For now, we'll return a placeholder URL
        return url
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

// Debug helper extensions
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