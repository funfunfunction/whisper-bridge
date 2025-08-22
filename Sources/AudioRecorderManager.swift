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

// Debug helper extensions
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