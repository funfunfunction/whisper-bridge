import AVFoundation
import SwiftUI

@MainActor
class AudioRecorderManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingPermissionGranted = false
    @Published var audioLevels: Float = 0.0
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var recordingURL: URL?
    private var levelTimer: Timer?
    
    override init() {
        super.init()
        checkRecordingPermission()
    }
    
    func checkRecordingPermission() {
        switch audioSession.recordPermission {
        case .granted:
            recordingPermissionGranted = true
        case .denied, .undetermined:
            requestRecordingPermission()
        @unknown default:
            requestRecordingPermission()
        }
    }
    
    private func requestRecordingPermission() {
        audioSession.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.recordingPermissionGranted = granted
            }
        }
    }
    
    func startRecording() {
        guard recordingPermissionGranted else {
            checkRecordingPermission()
            return
        }
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
            recordingURL = documentsPath.appendingPathComponent(fileName)
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isRecording = true
            startLevelMonitoring()
            
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopLevelMonitoring()
        
        do {
            try audioSession.setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    
    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.audioRecorder?.updateMeters()
            let averagePower = self?.audioRecorder?.averagePower(forChannel: 0) ?? -160
            let normalizedLevel = max(0.0, (averagePower + 160.0) / 160.0)
            self?.audioLevels = normalizedLevel
        }
    }
    
    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevels = 0.0
    }
    
    func getRecordingURL() -> URL? {
        return recordingURL
    }
    
    func cleanupOldRecordings() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            let recordings = files.filter { $0.pathExtension == "m4a" && $0.lastPathComponent.hasPrefix("recording_") }
            
            let sortedRecordings = recordings.sorted { url1, url2 in
                let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return date1! > date2!
            }
            
            if sortedRecordings.count > 10 {
                for recording in sortedRecordings.dropFirst(10) {
                    try fileManager.removeItem(at: recording)
                }
            }
        } catch {
            print("Failed to cleanup old recordings: \(error.localizedDescription)")
        }
    }
}

extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Recording finished successfully")
        } else {
            print("Recording failed")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Recording error: \(error.localizedDescription)")
        }
    }
}