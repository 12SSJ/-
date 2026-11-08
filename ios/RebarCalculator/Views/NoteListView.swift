import SwiftUI

struct NotesRootView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            NoteListView(onClose: { dismiss() })
        }
    }
}

struct NoteListView: View {
    let onClose: () -> Void

    @StateObject private var toast = ToastCenter()
    @State private var notes: [NoteItem] = []
    @State private var isLoading = false
    @State private var showClearConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Text("你的内容会安全保存在当前账号下")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.subtleText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 10) {
                    if isLoading && notes.isEmpty {
                        ProgressView()
                            .padding(.top, 60)
                    } else if !isLoading && notes.isEmpty {
                        Text("还没有记事，点击右下角新建")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.subtleText)
                            .padding(.top, 60)
                    } else {
                        ForEach(notes) { note in
                            NavigationLink {
                                NoteEditorView(noteId: note.id)
                            } label: {
                                noteCard(note)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 90)
            }
            .background(AppTheme.surface)
        }
        .background(AppTheme.surface)
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) {
            NavigationLink {
                NoteEditorView(noteId: 0)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("新建记事")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 48)
                .background(AppTheme.blue600)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .alert("清空记事本", isPresented: $showClearConfirmation) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                Task { await clearAll() }
            }
        } message: {
            Text("确定清除全部记事吗？此操作无法恢复。")
        }
        .onAppear {
            Task { await loadNotes() }
        }
        .toast(toast.message)
    }

    private var topBar: some View {
        ZStack {
            Text("记事本")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.titleNavy)

            HStack {
                Button("完成") {
                    onClose()
                }
                .font(.system(size: 15))
                .foregroundColor(AppTheme.blue600)

                Spacer()

                Button("清空") {
                    showClearConfirmation = true
                }
                .font(.system(size: 15))
                .foregroundColor(AppTheme.danger)
                .disabled(notes.isEmpty || isLoading)
                .opacity(notes.isEmpty ? 0.45 : 1)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: 0xE4EBF2))
                .frame(height: 0.5)
        }
    }

    private func noteCard(_ note: NoteItem) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(titleValue(note))
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.titleNavy)
                .lineLimit(1)

            Text(previewValue(note))
                .font(.system(size: 14))
                .foregroundColor(AppTheme.subtleText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: 0xE7EDF5), lineWidth: 1)
        )
    }

    private func titleValue(_ note: NoteItem) -> String {
        let title = (note.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "未命名记事" : title
    }

    private func previewValue(_ note: NoteItem) -> String {
        (note.content ?? "").htmlPlainText
    }

    @MainActor
    private func loadNotes() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            notes = try await APIClient.shared.notes()
        } catch {
            toast.show(error.localizedDescription)
        }
    }

    @MainActor
    private func clearAll() async {
        guard !notes.isEmpty else { return }
        do {
            try await APIClient.shared.clearNotes()
            notes = []
        } catch {
            toast.show(error.localizedDescription)
        }
    }
}
