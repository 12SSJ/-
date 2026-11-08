import SwiftUI

/// 全局登录状态：持有 Keychain 会话、前台会话监控和登录失效消息。
@MainActor
final class AppState: ObservableObject {
    @Published private(set) var isAuthenticated: Bool
    @Published var authMessage: String?

    private let store: SessionStore
    private let monitor: SessionMonitor

    init() {
        let store = SessionStore()
        self.store = store
        self.isAuthenticated = store.hasValidToken
        self.monitor = SessionMonitor(store: store)

        monitor.onSessionInvalid = { [weak self] message in
            Task { @MainActor in
                self?.handleSessionInvalid(message)
            }
        }
        APIClient.shared.onUnauthorized = { [weak self] message in
            Task { @MainActor in
                self?.handleSessionInvalid(message)
            }
        }

        if isAuthenticated {
            monitor.start()
        }
    }

    func authenticated(with token: String) {
        store.save(token: token)
        isAuthenticated = true
        monitor.start()
    }

    func logout(message: String? = nil) {
        monitor.stop()
        store.clear()
        authMessage = message
        isAuthenticated = false
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            if isAuthenticated { monitor.start() }
        case .inactive, .background:
            monitor.stop()
        @unknown default:
            break
        }
    }

    private func handleSessionInvalid(_ message: String?) {
        guard isAuthenticated else { return }
        logout(message: message)
    }
}
