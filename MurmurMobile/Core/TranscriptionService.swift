import Foundation
import Network
import os.log

final class TranscriptionService {
    static let shared = TranscriptionService()

    private let logger = OSLog(subsystem: "dev.fff.murmurmobile", category: "TranscriptionService")

    private var apiKey: String { KeychainManager.shared.getAPIKey() ?? "" }
    var hasValidAPIKey: Bool { !(KeychainManager.shared.getAPIKey() ?? "").isEmpty }

    private let monitor = NWPathMonitor()
    private var isNetworkAvailable = true
    private var isNetworkCheckComplete = false
    private let connectivitySemaphore = DispatchSemaphore(value: 0)

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isNetworkAvailable = path.status == .satisfied
            self?.isNetworkCheckComplete = true
            self?.connectivitySemaphore.signal()
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
        checkConnectivity()
    }

    deinit { monitor.cancel() }

    func checkNetworkStatus(completion: @escaping (Bool) -> Void) {
        if isNetworkCheckComplete { completion(isNetworkAvailable); return }
        DispatchQueue.global(qos: .userInitiated).async {
            if let url = URL(string: "https://www.apple.com") {
                var request = URLRequest(url: url)
                request.httpMethod = "HEAD"
                request.timeoutInterval = 3
                let sem = DispatchSemaphore(value: 0)
                var ok = false
                let task = URLSession.shared.dataTask(with: request) { _, resp, _ in
                    if let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) { ok = true }
                    sem.signal()
                }
                task.resume()
                _ = sem.wait(timeout: .now() + 3)
                DispatchQueue.main.async {
                    self.isNetworkAvailable = ok
                    self.isNetworkCheckComplete = true
                    completion(ok)
                }
            } else {
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    private func checkConnectivity() {
        DispatchQueue.global(qos: .utility).async {
            if let url = URL(string: "https://www.apple.com") {
                var request = URLRequest(url: url)
                request.httpMethod = "HEAD"
                request.timeoutInterval = 5
                let sem = DispatchSemaphore(value: 0)
                var ok = false
                URLSession.shared.dataTask(with: request) { _, resp, _ in
                    if let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) { ok = true }
                    sem.signal()
                }.resume()
                _ = sem.wait(timeout: .now() + 5)
                DispatchQueue.main.async {
                    self.isNetworkAvailable = ok
                    self.isNetworkCheckComplete = true
                }
            }
        }
    }

    func transcribeAudio(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard hasValidAPIKey else {
            completion(.failure(NSError(domain: "ElevenLabsAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "API key not configured. Add it in Settings."])));
            return
        }

        if !isNetworkCheckComplete {
            DispatchQueue.global(qos: .userInitiated).async {
                self.checkConnectivity()
                _ = self.connectivitySemaphore.wait(timeout: .now() + 2)
                DispatchQueue.main.async { self.transcribeAudio(fileURL: fileURL, completion: completion) }
            }
            return
        }

        guard isNetworkAvailable else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No network connection."])));
            return
        }

        guard let url = URL(string: "https://api.elevenlabs.io/v1/speech-to-text") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])));
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("MurmurMobile/1.0", forHTTPHeaderField: "User-Agent")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        do {
            let audioData = try Data(contentsOf: fileURL)
            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"model_id\"\r\n\r\n".data(using: .utf8)!)
            body.append("scribe_v1".data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            request.httpBody = body

            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 60
            configuration.timeoutIntervalForResource = 120
            let session = URLSession(configuration: configuration)

            let task = session.dataTask(with: request) { data, response, error in
                if let error = error { DispatchQueue.main.async { completion(.failure(error)) }; return }
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    }
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let text = json?["text"] as? String {
                        DispatchQueue.main.async { completion(.success(text)) }
                    } else if let detail = json?["detail"] as? [String: Any], let message = detail["message"] as? String {
                        DispatchQueue.main.async { completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: message])))}
                    } else if let detail = json?["detail"] as? String {
                        DispatchQueue.main.async { completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: detail])))}
                    } else {
                        DispatchQueue.main.async { completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract transcription"])))}
                    }
                } catch {
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            }
            task.resume()

        } catch {
            DispatchQueue.main.async { completion(.failure(error)) }
        }
    }

    func testApiConnection(completion: @escaping (Bool, String) -> Void) {
        checkNetworkStatus { connected in
            guard connected else { completion(false, "No internet connection."); return }
            self.testElevenLabsConnection(completion: completion)
        }
    }

    func testElevenLabsConnection(completion: @escaping (Bool, String) -> Void) {
        guard !apiKey.isEmpty else { completion(false, "API key is empty"); return }
        guard let url = URL(string: "https://api.elevenlabs.io/v1/user") else { completion(false, "Invalid URL"); return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error { completion(false, error.localizedDescription); return }
            if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) { completion(true, "Connected successfully") }
            else { completion(false, "Server error: \((response as? HTTPURLResponse)?.statusCode ?? -1)") }
        }.resume()
    }
}
