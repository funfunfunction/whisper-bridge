import SwiftUI
import UIKit

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Notice"
    @State private var isTestingAPI = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage("returnURL") private var returnURLString: String = ""
    var onKeyChange: (() -> Void)?

    var body: some View {
        Form {
            Section(header: Text("ElevenLabs API")) {
                SecureField("ElevenLabs API Key", text: $apiKey)
                    .onAppear { apiKey = KeychainManager.shared.getAPIKey() ?? "" }
                    .autocorrectionDisabled(true)
                    .textContentType(.password)

                HStack {
                    Button("Save API Key") { saveAPIKey() }
                        .disabled(apiKey.isEmpty)
                    Spacer()
                    Button("Test Connection") { testAPIConnection() }
                        .disabled(apiKey.isEmpty || isTestingAPI)
                }

                if isTestingAPI { HStack { Spacer(); ProgressView(); Spacer() }.padding(.vertical, 4) }
            }

            Section(header: Text("Shortcuts")) {
                TextField("Return URL (optional, e.g. shortcuts://)", text: $returnURLString)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                Text("When set, the app will open this URL after a successful transcription. Use 'shortcuts://' to return to Shortcuts.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Add \"Quick Record\" Shortcut (no timer)") {
                    let base = "murmurmobile://record"
                    var link = base
                    if !returnURLString.trimmingCharacters(in: .whitespaces).isEmpty,
                       let encoded = returnURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                        link += "?return=\(encoded)"
                    }
                    UIPasteboard.general.string = link
                    if let u = URL(string: "shortcuts://create-shortcut?name=Murmur%20Quick%20Record") {
                        openURL(u)
                    } else if let u = URL(string: "shortcuts://") {
                        openURL(u)
                    }
                    alertTitle = "Shortcuts"
                    alertMessage = "Copied Quick Record URL to clipboard. In Shortcuts, add an 'Open URL' action and paste it."
                    showingAlert = true
                }

                Button("Copy Quick Record URL") {
                    let base = "murmurmobile://record"
                    var link = base
                    if !returnURLString.trimmingCharacters(in: .whitespaces).isEmpty,
                       let encoded = returnURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                        link += "?return=\(encoded)"
                    }
                    UIPasteboard.general.string = link
                    alertTitle = "Shortcuts"
                    alertMessage = "Quick Record URL copied to clipboard."
                    showingAlert = true
                }
            }

            Section(header: Text("About")) {
                Link("Get an API Key", destination: URL(string: "https://elevenlabs.io/speech-synthesis")!)
                Text("Your API key is stored securely in the iOS Keychain and is only used to communicate with the ElevenLabs API for transcription.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func saveAPIKey() {
        let success = KeychainManager.shared.saveAPIKey(apiKey)
        if success {
            alertTitle = "API Key"
            alertMessage = "API key saved!"
            showingAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onKeyChange?(); dismiss()
            }
        } else {
            alertTitle = "API Key"
            alertMessage = "Failed to save API key."; showingAlert = true
        }
    }

    private func testAPIConnection() {
        isTestingAPI = true
        _ = KeychainManager.shared.saveAPIKey(apiKey)
        TranscriptionService.shared.testApiConnection { success, message in
            DispatchQueue.main.async {
                isTestingAPI = false
                alertMessage = success ? "Connection successful!" : "Connection failed: \(message)"
                showingAlert = true
                if success { onKeyChange?() }
            }
        }
    }
}
