import Foundation

enum APIError: LocalizedError {
    case message(String)
    case network

    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        case .network: return "无法连接后台，请检查服务器地址"
        }
    }
}

/// 与 Android Retrofit ApiService 对应的统一网络入口。
final class APIClient {
    static let shared = APIClient()

    /// 任意受保护接口返回 401/403 时回调，由 AppState 统一退出登录。
    var onUnauthorized: ((String?) -> Void)?

    private let baseURL: URL
    private let store: SessionStore
    private let session: URLSession

    private init() {
        baseURL = Config.apiBaseURL
        store = SessionStore()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 45
        configuration.timeoutIntervalForResource = 60
        session = URLSession(configuration: configuration)
    }

    func login(username: String, password: String) async throws -> String {
        let body = try JSONEncoder().encode(["username": username, "password": password])
        let payload: TokenPayload = try await request(
            path: "auth/login", method: "POST", body: body, anonymous: true
        )
        guard !payload.token.isEmpty else { throw APIError.message("账号或密码错误") }
        return payload.token
    }

    func register(username: String, password: String, activationCode: String) async throws -> String {
        let body = try JSONEncoder().encode([
            "username": username,
            "password": password,
            "activationCode": activationCode
        ])
        let payload: TokenPayload = try await request(
            path: "auth/register", method: "POST", body: body, anonymous: true
        )
        guard !payload.token.isEmpty else { throw APIError.message("注册码无效或注册失败") }
        return payload.token
    }

    func notes() async throws -> [NoteItem] {
        try await request(path: "notes")
    }

    func createNote(title: String, content: String) async throws {
        let body = try JSONEncoder().encode(["title": title, "content": content])
        let _: NoteItem = try await request(path: "notes", method: "POST", body: body)
    }

    func updateNote(id: Int64, title: String, content: String) async throws {
        let body = try JSONEncoder().encode(["title": title, "content": content])
        try await requestIgnoringData(path: "notes/\(id)", method: "PUT", body: body)
    }

    func deleteNote(id: Int64) async throws {
        try await requestIgnoringData(path: "notes/\(id)", method: "DELETE")
    }

    func clearNotes() async throws {
        try await requestIgnoringData(path: "notes", method: "DELETE")
    }

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        anonymous: Bool = false
    ) async throws -> T {
        let (http, data) = try await perform(path: path, method: method, body: body, anonymous: anonymous)
        if let envelope = try? JSONDecoder().decode(Envelope<T>.self, from: data) {
            guard envelope.code == 0 else {
                throw APIError.message(envelope.message ?? "请求失败")
            }
            guard let payload = envelope.data else {
                throw APIError.message("数据解析失败")
            }
            return payload
        }
        if !(200..<300).contains(http.statusCode) {
            throw APIError.message("服务器错误（\(http.statusCode)）")
        }
        throw APIError.message("数据解析失败")
    }

    private func requestIgnoringData(
        path: String,
        method: String,
        body: Data? = nil
    ) async throws {
        let (http, data) = try await perform(path: path, method: method, body: body, anonymous: false)
        if let envelope = try? JSONDecoder().decode(Envelope<EmptyData>.self, from: data) {
            guard envelope.code == 0 else {
                throw APIError.message(envelope.message ?? "请求失败")
            }
            return
        }
        if !(200..<300).contains(http.statusCode) {
            throw APIError.message("服务器错误（\(http.statusCode)）")
        }
        throw APIError.message("数据解析失败")
    }

    private func perform(
        path: String,
        method: String,
        body: Data?,
        anonymous: Bool
    ) async throws -> (HTTPURLResponse, Data) {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.message("服务器地址无效")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if !anonymous {
            let token = store.token
            if !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.network
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.message("服务器响应异常")
        }

        if (http.statusCode == 401 || http.statusCode == 403), !anonymous {
            let replaced = http.value(forHTTPHeaderField: "X-Session-Reason") == "replaced"
            store.clear()
            let message = replaced ? "您的账号已在其他地方登录" : "登录状态已失效，请重新登录"
            DispatchQueue.main.async { self.onUnauthorized?(message) }
            throw APIError.message(message)
        }
        return (http, data)
    }
}
