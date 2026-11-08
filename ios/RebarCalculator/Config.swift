import Foundation

/// iOS 端唯一的后台地址配置入口，与 Android 端保持一致。
enum Config {
    // 真机或正式环境请替换为实际的 HTTP/HTTPS 后台地址。
    // 当前后台允许 HTTP，Info.plist 已开启 App Transport Security 例外。
    static let apiBaseURL = URL(string: "http://47.108.182.235:8088/api/")!
}
