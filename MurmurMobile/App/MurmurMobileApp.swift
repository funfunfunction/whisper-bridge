import SwiftUI
import AVFoundation

@MainActor
final class AppState: ObservableObject {
    struct URLAction: Equatable {
        var autoStopSeconds: Int?
    }

    @Published var pendingAction: URLAction? = nil
    @Published var returnURL: URL? = nil

    func handle(openURL url: URL) {
        guard url.scheme?.lowercased() == "murmurmobile" else { return }
        guard url.host?.lowercased() == "record" || url.pathComponents.contains("record") else {
            return
        }

        var action = URLAction(autoStopSeconds: nil)
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let duration = components.queryItems?.first(where: { $0.name == "duration" })?.value,
               let seconds = Int(duration), seconds > 0 {
                action.autoStopSeconds = seconds
            }

            if let ret = components.queryItems?.first(where: { $0.name == "return" || $0.name.lowercased() == "x-success" })?.value,
               let retURL = URL(string: ret) {
                returnURL = retURL
            } else {
                returnURL = nil
            }
        }
        pendingAction = action
    }
}

@main
struct MurmurMobileApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    appState.handle(openURL: url)
                }
        }
    }
}
