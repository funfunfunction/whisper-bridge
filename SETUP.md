# VoiceScribe - Detailed Xcode Setup Guide

This guide provides step-by-step instructions for setting up the VoiceScribe iOS app in Xcode, from project creation to device deployment.

## Prerequisites

### Required Software
- **macOS**: Ventura (13.0) or later
- **Xcode**: 15.0 or later
- **iOS Deployment Target**: 17.0 or later
- **Git**: For cloning the repository

### Required Hardware
- **Mac**: Intel or Apple Silicon (M1/M2/M3)
- **iPhone**: iOS 17+ for testing
- **Storage**: ~5GB free space (Xcode + models)

### Required Accounts
- **Apple ID**: For Xcode and device deployment
- **Apple Developer Account**: $99/year (for device deployment and App Store)

## Step 1: Repository Setup

### 1.1 Clone Repository

```bash
cd ~/Developer  # or your preferred directory
git clone git@github.com:yourusername/whisper-bridge.git
cd whisper-bridge
```

### 1.2 Verify Contents

Ensure you have these directories and files:

```
whisper-bridge/
├── Sources/
│   ├── VoiceScribeApp.swift
│   ├── ContentView.swift
│   ├── UIComponents.swift
│   ├── AudioRecorderManager.swift
│   ├── TranscriptionManager.swift
│   ├── RecordVoiceIntent.swift
│   └── VoiceScribeControls.swift
├── Resources/
│   └── Info.plist
├── README.md
├── SETUP.md (this file)
└── CLAUDE.md
```

## Step 2: Create New Xcode Project

### 2.1 Launch Xcode

1. Open **Xcode** from Applications or Launchpad
2. If prompted, install additional components
3. Close any welcome screens

### 2.2 Create Project

1. Choose **"Create a new Xcode project"**
2. Select **iOS** tab at the top
3. Choose **"App"** template
4. Click **"Next"**

### 2.3 Configure Project Details

Fill out the project configuration:

- **Product Name**: `VoiceScribe`
- **Team**: Select your Apple Developer Team (if available)
- **Organization Identifier**: `com.yourname.VoiceScribe`
  - Replace `yourname` with your actual identifier
  - Use reverse domain notation (e.g., `com.johnsmith.VoiceScribe`)
- **Bundle Identifier**: Will auto-fill (e.g., `com.yourname.VoiceScribe`)
- **Language**: `Swift`
- **Interface**: `SwiftUI`
- **Use Core Data**: ❌ **Unchecked**
- **Include Tests**: ✅ **Checked** (recommended)

### 2.4 Choose Project Location

1. Navigate to your `whisper-bridge` directory
2. Click **"Create"**
3. Xcode will create a new subfolder with your project

## Step 3: Project Configuration

### 3.1 General Settings

1. Select project file (blue icon) in navigator
2. Under **TARGETS**, select **"VoiceScribe"**
3. In **General** tab:
   - **Display Name**: VoiceScribe
   - **Bundle Identifier**: Verify it's correct
   - **Version**: 1.0
   - **Build**: 1
   - **Deployment Target**: iOS 17.0

### 3.2 Signing & Capabilities

1. Go to **"Signing & Capabilities"** tab
2. **Signing**:
   - ✅ Check **"Automatically manage signing"**
   - **Team**: Select your Apple Developer account
   - If no team, you'll need to add Apple ID in Xcode Preferences

3. **Add Capabilities** (click the **+ Capability** button):

   **Background Modes**:
   - Click **"+ Capability"**
   - Search for and add **"Background Modes"**
   - Check ☑️ **"Audio, AirPlay, and Picture in Picture"**

   **App Groups** (Optional for now):
   - Click **"+ Capability"**
   - Search for and add **"App Groups"**
   - Leave empty for now (can configure later)

### 3.3 Build Settings (Optional Optimizations)

1. Select **"Build Settings"** tab
2. Search for these settings and modify if needed:

   **Swift Compilation**:
   - **Optimization Level** (Release): `-O` (Optimize for Speed)
   - **Compilation Mode**: Whole Module

   **Apple Clang - Code Generation**:
   - **Generate Debug Symbols**: Yes (both Debug and Release)

## Step 4: Add Package Dependencies

### 4.1 Add WhisperKit

1. In Xcode: **File** → **Add Package Dependencies...**
2. In the search field, enter:
   ```
   https://github.com/argmaxinc/WhisperKit
   ```
3. **Dependency Rule**: Select **"Up to Next Major Version"**
   - Should show `1.0.0 < 2.0.0`
4. Click **"Add Package"**
5. Wait for package resolution (may take a few minutes)
6. In **"Choose Package Products"**:
   - Ensure **WhisperKit** is selected
   - Target should be **VoiceScribe**
7. Click **"Add Package"**

### 4.2 Verify Package Installation

1. In the project navigator, you should see **"Package Dependencies"**
2. Expand to see **WhisperKit**
3. If there are issues, try: **File** → **Packages** → **Reset Package Caches**

## Step 5: Import Source Files

### 5.1 Replace Default Files

**VoiceScribeApp.swift:**
1. In navigator, select the existing `VoiceScribeApp.swift`
2. Delete its contents
3. Copy content from `Sources/VoiceScribeApp.swift`
4. Paste into Xcode

**ContentView.swift:**
1. Select existing `ContentView.swift`
2. Replace all content with `Sources/ContentView.swift`

### 5.2 Add New Files

For each new Swift file, follow this process:

1. Right-click on **VoiceScribe** folder in navigator
2. Choose **"New File..."**
3. Select **iOS** → **"Swift File"**
4. Click **"Next"**
5. Name the file (e.g., `UIComponents.swift`)
6. Ensure **VoiceScribe** target is checked
7. Click **"Create"**
8. Copy content from corresponding `Sources/` file

**Add these files:**
- `UIComponents.swift`
- `AudioRecorderManager.swift`
- `TranscriptionManager.swift`
- `RecordVoiceIntent.swift`
- `VoiceScribeControls.swift`

### 5.3 File Organization (Optional)

Create groups for better organization:

1. Right-click **VoiceScribe** folder
2. Choose **"New Group"**
3. Create these groups:
   - **UI** (ContentView, UIComponents)
   - **Managers** (AudioRecorderManager, TranscriptionManager)
   - **Intents** (RecordVoiceIntent, VoiceScribeControls)
4. Drag files into appropriate groups

## Step 6: Configure Info.plist

### 6.1 Locate Info.plist

1. In navigator, find **Info.plist** (may be in **VoiceScribe** folder)
2. Right-click → **"Open As"** → **"Source Code"**

### 6.2 Add Privacy Permissions

Add these keys before the closing `</dict>` tag:

```xml
<!-- Privacy Permissions -->
<key>NSMicrophoneUsageDescription</key>
<string>VoiceScribe needs microphone access to record your voice for transcription.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>VoiceScribe uses speech recognition to transcribe your recordings.</string>

<!-- Background Modes -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>

<!-- App Intents Support -->
<key>NSUserActivityTypes</key>
<array>
    <string>RecordVoiceIntent</string>
    <string>QuickRecordIntent</string>
</array>
```

### 6.3 Verify Minimum iOS Version

Ensure this key exists and is set correctly:

```xml
<key>MinimumOSVersion</key>
<string>17.0</string>
```

## Step 7: Build and Test

### 7.1 Initial Build

1. Select **VoiceScribe** scheme at the top
2. Choose a simulator (e.g., **iPhone 15 Pro**)
3. Press **⌘+B** to build
4. Fix any compilation errors if they appear

### 7.2 Common Build Issues

**Missing Imports:**
- Ensure all files have proper import statements
- Add `import WhisperKit` where needed

**App Intent Issues:**
- Add `import AppIntents` to intent files
- Verify iOS deployment target is 17.0+

**Missing Dependencies:**
- Clean build folder: **Product** → **Clean Build Folder**
- Reset packages: **File** → **Packages** → **Reset Package Caches**

### 7.3 Run in Simulator

1. Press **⌘+R** to run
2. App should launch in simulator
3. **Note**: Microphone won't work in simulator

### 7.4 Test Basic UI

In simulator, verify:
- ✅ App launches without crashing
- ✅ Main UI appears with record button
- ✅ Status shows "Ready to Record"
- ✅ Share/Clear buttons are disabled (no text)

## Step 8: Device Testing

### 8.1 Connect Physical Device

1. Connect iPhone via USB cable
2. Trust computer on device if prompted
3. In Xcode, device should appear in scheme selector

### 8.2 Code Signing for Device

1. Select your device in scheme selector
2. If signing issues appear:
   - Go to **Signing & Capabilities**
   - Verify team is selected
   - Try **"Automatically manage signing"**

### 8.3 Deploy to Device

1. Select your device
2. Press **⌘+R** to build and run
3. **First time**: 
   - On device: **Settings** → **General** → **VPN & Device Management**
   - Trust your developer certificate
4. App should install and launch

### 8.4 Test Device Features

On physical device, test:
- ✅ App launches successfully
- ✅ Microphone permission requested
- ✅ Recording starts/stops
- ✅ WhisperKit model downloads (requires internet)
- ✅ Basic transcription works

## Step 9: Shortcuts Integration

### 9.1 Build with Intents

1. Build and run on device
2. After installation, intents should be available

### 9.2 Test Shortcuts

1. Open **Shortcuts** app on device
2. Tap **"+"** to create new shortcut
3. Search for **"VoiceScribe"**
4. Should see **"Quick Record"** and **"Record Voice Note"**
5. Add shortcut and test

### 9.3 Configure Action Button (iPhone 15 Pro+)

1. **Settings** → **Action Button**
2. Swipe to **"Shortcut"**
3. Tap **"Choose a Shortcut"**
4. Select VoiceScribe shortcut
5. Test by pressing and holding Action Button

## Step 10: Control Center Widgets (iOS 18)

### 10.1 Verify iOS Version

Control Center widgets require iOS 18:
- Check **Settings** → **General** → **About** → **iOS Version**

### 10.2 Add to Control Center

1. **Settings** → **Control Center**
2. Under **"More Controls"**, look for **"Voice Record"**
3. Tap **"+"** to add
4. Drag to reorder position

### 10.3 Test Control Center

1. Swipe down from top-right corner
2. Should see VoiceScribe control
3. Tap to test functionality

## Step 11: Advanced Configuration

### 11.1 App Groups (For Shared Data)

If you need shared data between app and extensions:

1. **Signing & Capabilities** → **App Groups**
2. Click **"+"** next to App Groups
3. Enter identifier: `group.com.yourname.VoiceScribe`
4. Enable the group

### 11.2 Custom URL Schemes (Optional)

Add to Info.plist for deep linking:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourname.VoiceScribe</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>voicescribe</string>
        </array>
    </dict>
</array>
```

### 11.3 Performance Optimizations

**Build Settings:**
- **Swift Compiler - Code Generation**:
  - **Optimization Level** (Release): `-O`
- **Apple Clang - Code Generation**:
  - **Generate Debug Symbols**: No (for Release only)

**Model Configuration:**
In `TranscriptionManager.swift`, adjust model size for device capabilities:
- iPhone 15 Pro: Can handle "small" or "medium"
- Older devices: Stick with "tiny" or "base"

## Troubleshooting

### Common Issues and Solutions

**1. "No Such Module 'WhisperKit'"**
- Solution: Clean build folder, reset package caches
- File → Packages → Reset Package Caches
- Product → Clean Build Folder

**2. Code Signing Errors**
- Ensure Apple ID is added: Xcode → Preferences → Accounts
- Try manual signing with specific provisioning profile
- Verify Bundle Identifier doesn't conflict with existing apps

**3. App Crashes on Launch**
- Check Console app for crash logs
- Ensure iOS deployment target matches device version
- Verify all @MainActor annotations are correct

**4. Microphone Permission Not Requested**
- Verify NSMicrophoneUsageDescription in Info.plist
- Reset iOS Simulator: Device → Erase All Content and Settings

**5. WhisperKit Model Download Fails**
- Ensure device has internet connection
- Try smaller model (change in TranscriptionManager)
- Check available storage space

**6. Shortcuts Don't Appear**
- Rebuild app completely
- Force quit Shortcuts app
- Check NSUserActivityTypes in Info.plist

**7. Action Button Not Working**
- Verify shortcut was created successfully
- Check iOS version (requires iOS 16+)
- Try creating shortcut manually in Shortcuts app

### Getting Help

**Apple Developer Resources:**
- [iOS App Development](https://developer.apple.com/ios/)
- [App Intents Documentation](https://developer.apple.com/documentation/appintents)
- [WhisperKit Documentation](https://github.com/argmaxinc/WhisperKit)

**Community Support:**
- Stack Overflow: Tag with `ios`, `swift`, `swiftui`
- Reddit: r/iOSProgramming
- Apple Developer Forums

## Next Steps

Once you have the basic app working:

1. **Testing**: Run through the full test checklist in README.md
2. **Customization**: Adjust UI colors, model sizes, recording settings
3. **Features**: Add history view, settings screen, export options
4. **Distribution**: Prepare for TestFlight and App Store submission

## App Store Submission Preparation

When ready for distribution:

### 1. Archive Build
1. Select **"Any iOS Device"** in scheme
2. **Product** → **Archive**
3. Wait for build completion

### 2. App Store Connect
1. Create app in App Store Connect
2. Upload archive via Xcode Organizer
3. Add app screenshots, descriptions, keywords
4. Submit for review

### 3. TestFlight Testing
1. Add internal testers
2. Test on multiple devices
3. Collect feedback and iterate

---

**Congratulations!** You should now have a fully functional VoiceScribe app running on your device with Action Button support and Shortcuts integration. 

For ongoing development, remember to commit changes to git and sync between your VPS development environment and Mac testing environment as described in the `CLAUDE.md` workflow guide.