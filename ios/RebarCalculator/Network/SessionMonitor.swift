import Foundation

/// 前台会话事件流，对应 Android SessionSseMonitor。
/// 网络失败会退避重连；收到 session-replaced 或 401/403 时立即退出登录。
@MainActor
final class SessionMonitor {
    var onSessionInvalid: ((String) -> Void)?

    private let store: SessionStore
    private let session: URLSession
    private var running = false
    private var task: Task<Void, Never>?

    init(store: SessionStore) {
        self.store = store
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 3600
        configuration.timeoutIntervalForResource = 7200
        session = URLSession(configuration: configuration)
    }

    func start() {
        guard !running, !store.token.isEmpty else { return }
        running = true
        task = Task { [weak self] in
            await self?.run()
        }
    }

    func stop() {
        running = false
        task?.cancel()
        task = nil
    }

    private func run() async {
        var retryCount = 0
        while running {
            let token = store.token
            if token.isEmpty { break }

            do {
                var request = URLRequest(url: Config.apiBaseURL.appendingPathComponent("auth/session/stream"))
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                request.timeoutInterval = 3600

                let (bytes, response) = try await session.bytes(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                if http.statusCode == 401 || http.statusCode == 403 {
                    let replaced = http.value(forHTTPHeaderField: "X-Session-Reason") == "replaced"
                    invalidate(replaced ? "您的账号已在其他地方登录" : "登录状态已失效，请重新登录")
                    return
                }
                guard (200..<300).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }

                retryCount = 0
                for try await line in bytes.lines {
                    if !running { return }
                    if line.hasPrefix("event:") {
                        let event = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
                        if event == "session-replaced" {
                            invalidate("您的账号已在其他地方登录")
                            return
                        }
                    }
                }
            } catch {
                if !running || Task.isCancelled { return }
            }

            if !running { return }
            let seconds = min(30, 2 << min(retryCount, 4))
            retryCount += 1
            try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
        }
    }

    private func invalidate(_ message: String) {
        guard running else { return }
        running = false
        onSessionInvalid?(message)
    }
}
