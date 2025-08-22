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