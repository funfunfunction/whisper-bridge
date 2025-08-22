# VoiceScribe iOS App - Project Guide

This file provides project-specific guidance for the VoiceScribe iOS voice recording and transcription app development.

## Project Overview
Building a Swift iOS voice recording app with on-device transcription using WhisperKit, following the phase-1 guide. The app will feature:
- Audio recording with AVFoundation
- On-device transcription using WhisperKit
- iOS Shortcuts integration for Action Button support
- SwiftUI interface with sharing capabilities
- Background recording capability

## Development Workflow

### VPS → Mac → Xcode Process
- **Development Environment**: VPS/Ubuntu for file creation and git management
- **Build Environment**: Mac with Xcode 15+ for compilation and device testing  
- **Deployment**: iPhone with iOS 17+ and Apple Developer Account ($99/year) required

### Workflow Steps
1. **VPS Phase**: Create all Swift source files, project structure, documentation
2. **Sync Phase**: Commit changes to git repository using SSH authentication
3. **Mac Phase**: Clone/pull repository on Mac, open in Xcode for building/testing
4. **Iteration**: Test on device, report issues back via git commits/issues

### Xcode Project Setup (Mac-side)
When cloning to Mac, follow these steps:

1. **Create New Xcode Project**:
   - iOS → App → SwiftUI interface
   - Product Name: `VoiceScribe` 
   - Organization Identifier: `com.yourname.VoiceScribe`
   - Language: Swift

2. **Add Package Dependencies**:
   - File → Add Package Dependencies
   - URL: `https://github.com/argmaxinc/WhisperKit`
   - Version: Up to Next Major (1.0.0 < 2.0.0)

3. **Configure Signing & Capabilities**:
   - Background Modes (check "Audio, AirPlay, and Picture in Picture")
   - App Groups (configure later)

4. **Import Swift Files**:
   - Replace default ContentView.swift with our version
   - Add all Swift files from Sources/ directory
   - Update Info.plist with privacy permissions

## Repository Structure
```
whisper-bridge/
├── Sources/                    # Swift source files
│   ├── VoiceScribeApp.swift   # Main app entry point
│   ├── ContentView.swift      # Main UI with recording controls
│   ├── UIComponents.swift     # Reusable UI components
│   ├── AudioRecorderManager.swift    # Audio recording logic
│   ├── TranscriptionManager.swift    # WhisperKit integration
│   ├── RecordVoiceIntent.swift       # Shortcuts integration
│   └── VoiceScribeControls.swift     # Control Center widgets
├── Resources/                  # Assets, Info.plist
│   └── Info.plist             # Privacy permissions & app config
├── Tests/                     # Unit tests (future)
├── .gitignore                 # iOS-specific ignores
├── Package.swift              # Swift Package Manager (optional)
├── README.md                  # Setup instructions
├── SETUP.md                   # Detailed Xcode configuration guide
└── CLAUDE.md                  # This file
```

## Git Best Practices for iOS Development

### Commit Guidelines
- **feat**: New features (e.g., "feat: add WhisperKit transcription")
- **fix**: Bug fixes (e.g., "fix: resolve audio recording permission issue")  
- **ui**: UI changes (e.g., "ui: update recording button animation")
- **config**: Project configuration (e.g., "config: add background audio capability")
- **docs**: Documentation updates (e.g., "docs: update Xcode setup guide")

### Branch Strategy
- **main**: Production-ready code for App Store submission
- **develop**: Integration branch for VPS development
- **feature/**: Individual features (e.g., feature/shortcuts-integration)
- **fix/**: Bug fixes (e.g., fix/transcription-accuracy)

### Merge Process
1. Develop features on VPS in feature branches
2. Test integration in develop branch
3. Mac testing validates functionality in Xcode
4. Merge to main only after successful device testing

## Key Components

### Audio Recording (AudioRecorderManager)
- AVFoundation integration
- Optimized settings for speech (16kHz, mono, AAC)
- Background recording support
- Automatic cleanup of old recordings

### Transcription (TranscriptionManager)
- WhisperKit integration with CoreML optimization
- Model management (tiny/base/small/medium/large)
- Progress tracking and error handling
- On-device processing for privacy

### UI Components (SwiftUI)
- StatusCard: Recording/transcription state indicator
- RecordButton: Main recording control with animations
- TranscriptionView: Text display with sharing
- ShareSheet: Native iOS sharing interface

### Shortcuts Integration
- App Intents for Shortcuts app integration
- Action Button support (iPhone 15 Pro+)
- Control Center widgets (iOS 18)
- Voice activation phrases

## Testing Protocol

### VPS Development Testing
- [ ] Swift syntax validation
- [ ] Import/dependency verification
- [ ] Code structure review

### Mac/Xcode Testing
- [ ] Project builds without errors
- [ ] App launches successfully
- [ ] Microphone permissions requested
- [ ] Audio recording functionality
- [ ] WhisperKit model downloads
- [ ] Transcription accuracy
- [ ] Shortcuts integration
- [ ] Action Button functionality
- [ ] Background recording
- [ ] Share functionality

### Device Testing Requirements
- iPhone with iOS 17+ for basic functionality
- iPhone 15 Pro+ for Action Button testing
- Apple Developer Account for device deployment
- Various audio conditions (quiet, noisy, different languages)

## Common Issues & Solutions

### WhisperKit Model Download
- Requires internet connection on first launch
- Falls back to smaller models if download fails
- Models stored in Documents/WhisperKitModels/

### Background Recording
- Requires Background Modes capability
- May be interrupted by phone calls
- Limited by iOS system policies

### Shortcuts Integration  
- Requires App Intents framework (iOS 16+)
- Must be registered in app initialization
- May need app rebuild for Control Center widgets

## Performance Considerations

### Model Selection
- **tiny**: 39MB, fastest, lowest accuracy
- **base**: 74MB, balanced (recommended for Phase 1)
- **small**: 244MB, better accuracy, slower
- **medium/large**: 769MB+, best accuracy, much slower

### Optimization Tips
- Pre-warm model on app launch
- Limit recording length for better UX
- Use progress indicators for long transcriptions
- Clean up old recordings automatically

## Next Phase Features (Future)
- History view for past recordings
- Settings screen for model selection
- iCloud backup integration
- Export options (text files, PDF)
- Multiple language support
- Offline Siri integration