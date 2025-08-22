# WhisperBridge - iOS Voice Recording & Transcription App

A Swift iOS app that records audio and transcribes it using on-device AI with WhisperKit. Features include Action Button support, Shortcuts integration, and Control Center widgets.

## Features

🎙️ **Voice Recording** - High-quality audio recording with AVFoundation  
🧠 **On-Device AI** - Local transcription using WhisperKit (privacy-focused)  
⚡ **Action Button** - iPhone 15 Pro+ Action Button support  
🔗 **Shortcuts** - iOS Shortcuts integration with voice activation  
📱 **Control Center** - iOS 18 Control Center widgets  
📤 **Share Integration** - Native iOS sharing with other apps  
🔄 **Background Recording** - Continue recording when app is backgrounded  

## Requirements

- **Mac**: macOS with Xcode 15+
- **Device**: iPhone with iOS 17+ 
- **Account**: Apple Developer Account ($99/year)
- **Storage**: ~2GB for WhisperKit models

## Quick Start

### 1. Clone Repository

```bash
git clone git@github.com:yourusername/whisper-bridge.git
cd whisper-bridge
```

### 2. Create Xcode Project

1. Open Xcode → **Create New Project**
2. Choose: **iOS** → **App** → **Next**
3. Configure:
   - **Product Name**: `WhisperBridge`
   - **Organization Identifier**: `com.yourname.WhisperBridge`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Use Core Data**: Unchecked

### 3. Add Package Dependencies

1. **File** → **Add Package Dependencies**
2. Enter URL: `https://github.com/argmaxinc/WhisperKit`
3. Version: **Up to Next Major** (1.0.0 < 2.0.0)
4. Add to target: **WhisperBridge**

### 4. Configure Project Settings

**Signing & Capabilities:**
- ✅ Automatically manage signing
- ➕ Add Capability: **Background Modes**
  - ☑️ Audio, AirPlay, and Picture in Picture
- ➕ Add Capability: **App Groups** (configure later)

### 5. Import Source Files

Replace/add these files from the `Sources/` directory:

- `WhisperBridgeApp.swift` → Replace default app file
- `ContentView.swift` → Replace default content view
- `UIComponents.swift` → Add new file
- `AudioRecorderManager.swift` → Add new file
- `TranscriptionManager.swift` → Add new file
- `RecordVoiceIntent.swift` → Add new file
- `WhisperBridgeControls.swift` → Add new file

### 6. Configure Info.plist

Copy privacy permissions from `Resources/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>WhisperBridge needs microphone access to record your voice for transcription.</string>

<key>NSSpeechRecognitionUsageDescription</key>  
<string>WhisperBridge uses speech recognition to transcribe your recordings.</string>
```

### 7. Build & Test

1. Select your device or simulator
2. **Product** → **Build** (⌘+B)
3. **Product** → **Run** (⌘+R)

## Usage

### Basic Recording
1. Launch app
2. Tap the blue microphone button to start recording
3. Tap the red stop button to stop and transcribe
4. Use **Share** button to export transcription
5. Use **Clear** button to reset

### Shortcuts Integration
1. Open **Shortcuts** app
2. Search for "WhisperBridge" intents
3. Add "Quick Record" shortcut
4. Configure Action Button (iPhone 15 Pro+):
   - Settings → Action Button → Shortcut → Quick Record

### Control Center (iOS 18+)
1. Settings → Control Center
2. Find "Voice Record" under "More Controls"
3. Tap **+** to add
4. Drag to reorder position

## Architecture

### Core Components

**AudioRecorderManager**: Handles audio recording with AVFoundation
- Optimized settings for speech (16kHz, mono, AAC)
- Background recording support
- Automatic cleanup of old files

**TranscriptionManager**: WhisperKit integration for on-device AI
- Multiple model sizes (tiny/base/small/medium/large)
- CoreML optimization for Neural Engine
- Progress tracking and error handling

**UI Components**: SwiftUI interface elements
- StatusCard: Visual recording state indicator
- RecordButton: Animated recording control
- TranscriptionView: Text display with sharing
- ShareSheet: Native iOS sharing

**Shortcuts Integration**: App Intents for system integration
- RecordVoiceIntent: Parameterized recording
- QuickRecordIntent: One-tap recording
- Control Center widgets for iOS 18

### Data Flow

```
User Input → AudioRecorder → Audio File → WhisperKit → Transcription → UI Display
```

## Customization

### Model Selection

Edit `TranscriptionManager.swift`:

```swift
@Published var modelSize: String = "base" // tiny, base, small, medium, large
```

**Model Comparison:**
- **tiny**: 39MB, fastest, basic accuracy
- **base**: 74MB, balanced (recommended)
- **small**: 244MB, better accuracy
- **medium**: 769MB, high accuracy, slower
- **large**: 1550MB, best accuracy, much slower

### Recording Settings

Edit `AudioRecorderManager.swift`:

```swift
let settings: [String: Any] = [
    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
    AVSampleRateKey: 16000.0,  // Adjust sample rate
    AVNumberOfChannelsKey: 1,   // Mono/stereo
    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
]
```

### UI Customization

Edit colors and styles in `UIComponents.swift`:

```swift
var statusColor: Color {
    if isRecording { return .red }
    else if isTranscribing { return .orange }
    else { return .green }
}
```

## Troubleshooting

### Common Issues

**❌ WhisperKit model won't download**
- Check internet connection
- Try smaller model (tiny/base)
- Clear app data and retry

**❌ Recording stops when app backgrounds**
- Ensure Background Modes capability is enabled
- Check "Audio, AirPlay, and Picture in Picture"

**❌ Shortcuts don't appear**
- Rebuild app after adding intents
- Check Shortcuts app → Gallery → Search "WhisperBridge"

**❌ Microphone permission denied**
- Settings → Privacy & Security → Microphone → WhisperBridge

**❌ Transcription is slow/inaccurate**
- Use smaller model for speed
- Ensure quiet recording environment
- Check device Neural Engine availability

### Performance Tips

- **First Launch**: WhisperKit model download required (~74MB for base)
- **Cold Start**: First transcription slower due to model loading
- **Pre-warming**: Model loaded on app launch for better UX
- **Cleanup**: Old recordings automatically deleted after 7 days

## Development Workflow

This project is developed on VPS/Ubuntu and built on Mac with Xcode:

1. **VPS**: Create/edit Swift files, git commits
2. **Mac**: Pull changes, build in Xcode, test on device
3. **Iteration**: Report issues via git, continue development

See `CLAUDE.md` for detailed development workflow.

## Testing

### Manual Testing Checklist

**Basic Functionality:**
- [ ] App launches without crashing
- [ ] Microphone permission requested
- [ ] Recording starts/stops correctly
- [ ] Audio file created in Documents
- [ ] WhisperKit model downloads
- [ ] Transcription produces text
- [ ] Share functionality works
- [ ] Clear button resets state

**Shortcuts Integration:**
- [ ] Shortcuts appear in Shortcuts app
- [ ] Quick Record shortcut functions
- [ ] Action Button integration works
- [ ] Control Center widget appears (iOS 18)

**Edge Cases:**
- [ ] No microphone permission handling
- [ ] No internet during model download
- [ ] Background recording continues
- [ ] Long recordings (>5 minutes)
- [ ] Low storage space handling
- [ ] Silent audio transcription

## Contributing

1. Fork repository
2. Create feature branch: `git checkout -b feature/awesome-feature`
3. Commit changes: `git commit -m 'feat: add awesome feature'`
4. Push to branch: `git push origin feature/awesome-feature`
5. Open Pull Request

### Commit Convention
- `feat:` New features
- `fix:` Bug fixes
- `ui:` Interface changes
- `config:` Project configuration
- `docs:` Documentation updates

## License

MIT License - see LICENSE file for details.

## Support

- 📖 [Phase 1 Implementation Guide](ios-voice-app-phase1-guide.md)
- 🔧 [Detailed Setup Instructions](SETUP.md)
- 💬 [WhisperKit Documentation](https://github.com/argmaxinc/WhisperKit)
- 🍎 [iOS Shortcuts Guide](https://developer.apple.com/documentation/appintents)

---

**Built with ❤️ using SwiftUI, WhisperKit, and iOS 17+**