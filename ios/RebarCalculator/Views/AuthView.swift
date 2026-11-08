import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var toast = ToastCenter()

    @State private var username = ""
    @State private var password = ""
    @State private var showsPassword = false
    @State private var loggingIn = false
    @State private var usernameError: String?
    @State private var passwordError: String?

    @FocusState private var focusedField: Field?

    private enum Field {
        case username
        case password
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        card
                            .frame(maxWidth: 560)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: proxy.size.height)
                }
                .background(AppTheme.surface)
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .toast(toast.message)
        .onAppear {
            if let message = appState.authMessage {
                toast.show(message)
                appState.authMessage = nil
            }
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            Text("钢筋锚固搭接计算器")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppTheme.blue600)
                .multilineTextAlignment(.center)

            Text("登录")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: 0x526B82))
                .padding(.top, 10)

            VStack(spacing: 10) {
                OutlinedField {
                    TextField("账号", text: $username)
                        .font(.system(size: 16))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.username)
                        .focused($focusedField, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }
                if let usernameError = usernameError {
                    errorText(usernameError)
                }

                OutlinedField {
                    HStack(spacing: 8) {
                        Group {
                            if showsPassword {
                                TextField("密码", text: $password)
                            } else {
                                SecureField("密码", text: $password)
                            }
                        }
                        .font(.system(size: 16))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                        .onSubmit { login() }

                        Button {
                            showsPassword.toggle()
                        } label: {
                            Image(systemName: showsPassword ? "eye.slash" : "eye")
                                .foregroundColor(AppTheme.blue600)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if let passwordError = passwordError {
                    errorText(passwordError)
                }
            }
            .padding(.top, 20)

            Button(action: login) {
                HStack(spacing: 8) {
                    if loggingIn {
                        ProgressView().tint(.white)
                    }
                    Text(loggingIn ? "正在登录" : "登录")
                        .font(.system(size: 15, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(loggingIn ? AppTheme.blue600.opacity(0.62) : AppTheme.blue600)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(loggingIn)
            .padding(.top, 24)

            NavigationLink {
                RegisterView()
            } label: {
                Text("没有账号？去注册")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.blue600)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
    }

    private func errorText(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 12))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func login() {
        guard !loggingIn else { return }
        let usernameValue = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordValue = password.trimmingCharacters(in: .whitespacesAndNewlines)
        usernameError = nil
        passwordError = nil
        if usernameValue.isEmpty {
            usernameError = "请输入账号"
            return
        }
        if passwordValue.isEmpty {
            passwordError = "请输入密码"
            return
        }
        focusedField = nil
        loggingIn = true

        Task { @MainActor in
            defer { loggingIn = false }
            do {
                let token = try await APIClient.shared.login(username: usernameValue, password: passwordValue)
                appState.authenticated(with: token)
            } catch {
                toast.show(error.localizedDescription)
            }
        }
    }
}
