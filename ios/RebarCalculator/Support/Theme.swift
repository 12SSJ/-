import SwiftUI
import UIKit

/// 与 Android Material 配色保持一致的全局色板。
enum AppTheme {
    static let blue600 = Color(hex: 0x1565C0)
    static let blue800 = Color(hex: 0x0D47A1)
    static let surface = Color(hex: 0xF7F9FC)
    static let onSurface = Color(hex: 0x1B1C1E)
    static let headerBackground = Color(hex: 0xE4F1FF)
    static let titleNavy = Color(hex: 0x172B4D)
    static let subtleText = Color(hex: 0x718096)
    static let danger = Color(hex: 0xD94C4C)
    static let tableBorder = Color(hex: 0x313131)
    static let resultHeader = Color(hex: 0x2E7FBC)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// 顶部短消息，替代 Android 的自定义 Snackbar。
final class ToastCenter: ObservableObject {
    @Published var message: String?
    private var dismissTask: Task<Void, Never>?

    func show(_ text: String) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.show(text)
            }
            return
        }
        dismissTask?.cancel()
        message = text
        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            guard !Task.isCancelled else { return }
            self?.message = nil
        }
    }
}

private struct ToastOverlay: ViewModifier {
    let message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message = message {
                    Text(message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.78))
                        .clipShape(Capsule())
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: message)
    }
}

extension View {
    func toast(_ message: String?) -> some View {
        modifier(ToastOverlay(message: message))
    }
}

/// 统一的 Material 描边输入框外观。
struct OutlinedField<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppTheme.blue600, lineWidth: 1)
            )
    }
}

extension String {
    /// 将后台保存的 HTML 记事转换为纯文本预览。
    var htmlPlainText: String {
        guard let data = data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
