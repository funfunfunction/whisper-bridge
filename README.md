# MurmurMobile (iOS)

An iOS SwiftUI utility that records your voice, transcribes it via ElevenLabs Speech‑to‑Text, and copies the result to the clipboard. It supports a custom URL scheme so you can trigger recording from the Shortcuts app (and, by extension, Siri).

## Quick Start

- Open `MurmurMobile.xcodeproj` in Xcode.
- Set your Development Team under Signing & Capabilities.
- Build and run on an iPhone/iPad (iOS 16+ recommended).
- In the app, tap the gear icon and paste your ElevenLabs API key.
- Tap the mic button to record, tap again to stop. The transcription is copied to the clipboard automatically.

## Features

- Record → Transcribe → Auto‑copy to clipboard
- Shortcut/URL trigger: `murmurmobile://record?duration=5`
- Optional auto‑stop after `duration` seconds
- Keychain storage for API key (secure and persistent)

## Requirements

- iOS 16 or later
- Xcode 15+
- Internet access
- ElevenLabs API key

## Building & Signing

- Open `MurmurMobile.xcodeproj`.
- Select the “MurmurMobile” target → Signing & Capabilities → set a Development Team.
- Select a device (real device recommended for microphone quality).
- Run.

## Configuration

- API Key: In‑app Settings (gear icon) → paste your ElevenLabs API key; it’s saved to the iOS Keychain and used for requests.
- Clipboard: On successful transcription, text is written to `UIPasteboard.general`.

## URL Scheme & Shortcuts

- Custom scheme: `murmurmobile`.
- Start recording via URL:
  - `murmurmobile://record` → opens the app and starts recording immediately.
  - `murmurmobile://record?duration=5` → starts recording and auto‑stops after 5 seconds, then transcribes and copies to clipboard.
- Create a Shortcut:
  - Action: “Open URLs” → `murmurmobile://record?duration=5`.
  - Optional: Add a “Wait” action for a few seconds, then use additional actions (e.g., paste to a note) depending on your workflow.
- Siri: Name your Shortcut (e.g., “Voice to Text”) and say “Hey Siri, Voice to Text”.

## Permissions

- Microphone: Required to record speech (`NSMicrophoneUsageDescription` is included in Info.plist).
- Clipboard: Writing to the pasteboard does not require permission; iOS may show a small banner indicating a paste occurred.

## How It Works

- Recording: Uses `AVAudioSession` and `AVAudioRecorder` to capture audio to `.m4a` (AAC, 44.1 kHz, mono).
- Networking: Uses `URLSession` with multipart form upload to ElevenLabs Speech‑to‑Text (`/v1/speech-to-text`).
- Connectivity: `NWPathMonitor` and a lightweight connectivity check help avoid avoidable failures when offline.
- Security: API key is stored in iOS Keychain (`kSecClassGenericPassword`, accessible when unlocked).

## Limitations

- Foreground requirement: iOS requires the app to be in foreground to record audio. The URL scheme brings the app forward when triggered from Shortcuts.
- Background/Silent usage: Not supported; the app shows UI during recording.
- Transcription latency: End‑to‑end time depends on network and ElevenLabs response.

## Troubleshooting

- No transcription returned:
  - Verify network connectivity.
  - Confirm your ElevenLabs API key is set and valid (try “Test Connection” in Settings).
- Microphone error:
  - Ensure microphone permission was granted in Settings → Privacy → Microphone.
- Clipboard not updated:
  - Confirm the transcription completed successfully; check for an error banner.
- URL scheme not triggering:
  - Confirm the scheme is correctly typed (`murmurmobile://record`).
  - Ensure the app has been installed at least once so iOS registers the scheme.

## Privacy

- Audio you record is uploaded to ElevenLabs for transcription. Do not record sensitive content unless you are comfortable with ElevenLabs’ policies.
- The API key is stored in the iOS Keychain and is not synced or shared by this app.

## Project Structure

- `MurmurMobile/App` — SwiftUI app entry and main view
- `MurmurMobile/Core` — Recording, Keychain, and transcription services
- `MurmurMobile/Settings` — Settings UI for API key management
- `MurmurMobile/Assets.xcassets` — App icons and assets

## Roadmap Ideas

- App Shortcut (App Intents) to trigger recording without URLs
- Transcription language options and model selection
- History view of past transcriptions (opt‑in)
- Haptic and visual feedback during recording

## License

MIT License
