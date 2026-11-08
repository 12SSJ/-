import Foundation
import Security

/// 仅持久化登录会话，使用 Keychain 对应 Android EncryptedSharedPreferences。
struct SessionStore {
    private let service = "com.rebar.calculator.session"
    private let account = "jwt"

    var token: String {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
            return ""
        }
        return value
    }

    var hasValidToken: Bool {
        let value = token
        let pieces = value.split(separator: ".")
        guard pieces.count == 3 else { return false }
        guard let payloadData = Data(base64URLEncoded: String(pieces[1])),
              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = json["exp"] as? Double else {
            return false
        }
        return exp * 1000 > Date().timeIntervalSince1970 * 1000
    }

    func save(token value: String) {
        clear()
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(value.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    func clear() {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

extension Data {
    init?(base64URLEncoded string: String) {
        var value = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        switch value.count % 4 {
        case 2: value += "=="
        case 3: value += "="
        default: break
        }
        self.init(base64Encoded: value)
    }
}
