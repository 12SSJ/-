import SwiftUI
import WebKit

/// 使用 WKWebView contenteditable 的富文本编辑器，
/// HTML 结构与 Android 端一致，旧记事可以直接编辑。
final class RichTextController: ObservableObject {
    weak var webView: WKWebView?

    func currentHTML() async -> String {
        guard let webView = webView else { return "" }
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                webView.evaluateJavaScript("document.body.innerHTML") { result, _ in
                    continuation.resume(returning: (result as? String) ?? "")
                }
            }
        }
    }

    func undo() { exec("document.execCommand('undo')") }
    func redo() { exec("document.execCommand('redo')") }
    func bold() { exec("document.execCommand('bold')") }
    func italic() { exec("document.execCommand('italic')") }
    func underline() { exec("document.execCommand('underline')") }
    func strikethrough() { exec("document.execCommand('strikeThrough')") }
    func bullets() { exec("document.execCommand('insertUnorderedList')") }
    func numbers() { exec("document.execCommand('insertOrderedList')") }
    func heading() { exec("document.execCommand('formatBlock', false, 'h2')") }
    func quote() { exec("document.execCommand('formatBlock', false, 'blockquote')") }
    func indent() { exec("document.execCommand('indent')") }
    func outdent() { exec("document.execCommand('outdent')") }
    func center() { exec("document.execCommand('justifyCenter')") }
    func todo() { exec("document.execCommand('insertHTML', false, '<div>☑&nbsp;</div>')") }
    func clearFormat() { exec("document.execCommand('removeFormat')") }

    private func exec(_ command: String) {
        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript("document.body.focus(); \(command);")
        }
    }
}

struct RichTextEditor: UIViewRepresentable {
    @Binding var html: String
    let controller: RichTextController

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.userContentController.add(context.coordinator, name: "htmlChanged")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        webView.scrollView.keyboardDismissMode = .interactive
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        context.coordinator.webView = webView
        controller.webView = webView
        webView.loadHTMLString(Self.skeleton, baseURL: nil)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        controller.webView = webView

        guard context.coordinator.isReady else { return }
        if context.coordinator.lastKnownHTML != html {
            context.coordinator.lastKnownHTML = html
            webView.evaluateJavaScript("document.body.innerHTML = \(Self.jsString(html));")
        }
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var parent: RichTextEditor
        weak var webView: WKWebView?
        var isReady = false
        var lastKnownHTML = ""

        init(parent: RichTextEditor) {
            self.parent = parent
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "htmlChanged", let value = message.body as? String else { return }
            lastKnownHTML = value
            DispatchQueue.main.async {
                self.parent.html = value
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isReady = true
            lastKnownHTML = parent.html
            webView.evaluateJavaScript("document.body.innerHTML = \(RichTextEditor.jsString(parent.html));")
        }
    }

    private static func jsString(_ value: String) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let result = String(data: data, encoding: .utf8) else {
            return "\"\""
        }
        return result
    }

    private static let skeleton = """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
    <style>
    html, body { margin: 0; padding: 0; background: #ffffff; }
    body {
        font-family: -apple-system, "PingFang SC", sans-serif;
        font-size: 16px;
        line-height: 1.55;
        color: #172B4D;
        padding: 16px;
        box-sizing: border-box;
        min-height: 100vh;
        outline: none;
        word-wrap: break-word;
    }
    body:empty::before { content: "输入记事内容"; color: #9AA7B5; }
    blockquote { border-left: 3px solid #D8E2EE; margin: 8px 0; padding-left: 10px; color: #526B82; }
    ul, ol { padding-left: 24px; }
    h2 { font-size: 19px; margin: 12px 0 6px; }
    </style>
    </head>
    <body contenteditable="true"></body>
    <script>
    document.addEventListener('input', function () {
        window.webkit.messageHandlers.htmlChanged.postMessage(document.body.innerHTML);
    });
    </script>
    </html>
    """
}
