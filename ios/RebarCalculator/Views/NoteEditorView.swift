import SwiftUI

struct NoteEditorView: View {
    let noteId: Int64

    @Environment(\.dismiss) private var dismiss
    @StateObject private var toast = ToastCenter()
    @StateObject private var richController = RichTextController()

    @State private var title = ""
    @State private var html = ""
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            TextField("标题", text: $title)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.titleNavy)
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.blue600, lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)

            toolbar

            RichTextEditor(html: $html, controller: richController)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: 0xE1E9F2), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)

            HStack {
                Spacer()
                Button("删除") {
                    showDeleteConfirmation = true
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.danger)
            }
            .padding(.horizontal, 18)
            .frame(height: 44)
        }
        .background(AppTheme.surface)
        .navigationTitle(noteId > 0 ? "编辑记事" : "新建记事")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    Text(isSaving ? "保存中" : "保存")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 32)
                        .background(isSaving ? AppTheme.blue600.opacity(0.62) : AppTheme.blue600)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isSaving)
            }
        }
        .alert("删除记事", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                Task { await deleteNote() }
            }
        } message: {
            Text("确定删除这条记事吗？")
        }
        .task {
            await loadIfNeeded()
        }
        .toast(toast.message)
    }

    private var toolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                tool("↶") { richController.undo() }
                tool("↷") { richController.redo() }
                divider
                tool("B", weight: .bold) { richController.bold() }
                tool("I", italic: true) { richController.italic() }
                tool("U", underline: true) { richController.underline() }
                tool("S", strike: true) { richController.strikethrough() }
                divider
                tool("• ≡") { richController.bullets() }
                tool("1. ≡") { richController.numbers() }
                tool("H₂", size: 16, weight: .bold) { richController.heading() }
                divider
                tool("❝", size: 20) { richController.quote() }
                tool("⇥") { richController.indent() }
                tool("⇤") { richController.outdent() }
                tool("≡") { richController.center() }
                divider
                tool("☑") { richController.todo() }
                tool("Tx", size: 16) { richController.clearFormat() }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 56)
        .background(Color.white)
        .padding(.top, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: 0xE7EDF5))
                .frame(height: 0.5)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(hex: 0xE3EAF3))
            .frame(width: 1, height: 28)
            .padding(.horizontal, 4)
    }

    private func tool(
        _ label: String,
        size: CGFloat = 18,
        weight: Font.Weight = .medium,
        italic: Bool = false,
        underline: Bool = false,
        strike: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            toolText(label, size: size, weight: weight, italic: italic, underline: underline, strike: strike)
                .foregroundColor(AppTheme.titleNavy)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
    }

    private func toolText(
        _ label: String,
        size: CGFloat,
        weight: Font.Weight,
        italic: Bool,
        underline: Bool,
        strike: Bool
    ) -> Text {
        var text = Text(label).font(.system(size: size, weight: weight))
        if italic { text = text.italic() }
        if underline { text = text.underline() }
        if strike { text = text.strikethrough() }
        return text
    }

    @MainActor
    private func loadIfNeeded() async {
        guard noteId > 0, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let notes = try await APIClient.shared.notes()
            guard let note = notes.first(where: { $0.id == noteId }) else {
                toast.show("记事不存在或无权访问")
                try? await Task.sleep(nanoseconds: 1_300_000_000)
                dismiss()
                return
            }
            title = note.title ?? ""
            html = note.content ?? ""
        } catch {
            toast.show(error.localizedDescription)
        }
    }

    @MainActor
    private func save() async {
        guard !isSaving else { return }
        let currentHTML = await richController.currentHTML()
        html = currentHTML

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let plainText = currentHTML.htmlPlainText
        if trimmedTitle.isEmpty && plainText.isEmpty {
            dismiss()
            return
        }

        isSaving = true
        defer { isSaving = false }
        do {
            if noteId > 0 {
                try await APIClient.shared.updateNote(id: noteId, title: trimmedTitle, content: currentHTML)
            } else {
                try await APIClient.shared.createNote(title: trimmedTitle, content: currentHTML)
            }
            dismiss()
        } catch {
            toast.show(error.localizedDescription)
        }
    }

    @MainActor
    private func deleteNote() async {
        guard noteId > 0 else {
            dismiss()
            return
        }
        do {
            try await APIClient.shared.deleteNote(id: noteId)
            dismiss()
        } catch {
            toast.show(error.localizedDescription)
        }
    }
}
