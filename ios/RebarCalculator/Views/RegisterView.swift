import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var toast = ToastCenter()

    @State private var username = ""
    @State private var activationCode = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var showsPassword = false
    @State private var registering = false
    @State private var usernameError: String?
    @State private var passwordError: String?
    @State private var confirmationError: String?

    @FocusState private var focusedField: Field?

    private enum Field {
        case username
        case activationCode
        case password
        case confirmation
    }

    var body: some View {
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
        .navigationTitle("注册")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toast(toast.message)
    }

    private var card: some View {
        VStack(spacing: 0) {
            Text("钢筋锚固搭接计算器")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppTheme.blue600)
                .multilineTextAlignment(.center)

            Text("注册")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: 0x526B82))
                .padding(.top, 10)

            VStack(spacing: 10) {
                OutlinedField {
                    TextField("设置账号", text: $username)
                        .font(.system(size: 16))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.username)
                        .focused($focusedField, equals: .username)
                }
                if let usernameError = usernameError {
                    errorText(usernameError)
                }

                OutlinedField {
                    TextField("激活码", text: $activationCode)
                        .font(.system(size: 16))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .activationCode)
                }

                OutlinedField {
                    HStack(spacing: 8) {
                        Group {
                            if showsPassword {
                                TextField("设置密码", text: $password)
                            } else {
                                SecureField("设置密码", text: $password)
                            }
                        }
                        .font(.system(size: 16))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)

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

                OutlinedField {
                    SecureField("确认密码", text: $confirmation)
                        .font(.system(size: 16))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmation)
                        .submitLabel(.done)
                        .onSubmit { register() }
                }
                if let confirmationError = confirmationError {
                    errorText(confirmationError)
                }
            }
            .padding(.top, 20)

            Button(action: register) {
                HStack(spacing: 8) {
                    if registering {
                        ProgressView().tint(.white)
                    }
                    Text(registering ? "正在注册" : "注册")
                        .font(.system(size: 15, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(registering ? AppTheme.blue600.opacity(0.62) : AppTheme.blue600)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(registering)
            .padding(.top, 24)

            Button {
                focusedField = nil
                dismiss()
            } label: {
                Text("已有账号？去登录")
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

    @Environment(\.dismiss) private var dismiss

    private func errorText(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 12))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func register() {
        guard !registering else { return }
        let usernameValue = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let activationValue = activationCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordValue = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let confirmationValue = confirmation.trimmingCharacters(in: .whitespacesAndNewlines)

        usernameError = nil
        passwordError = nil
        confirmationError = nil

        if usernameValue.count < 3 {
            usernameError = "账号至少 3 位"
            return
        }
        if passwordValue.count < 6 {
            passwordError = "密码至少 6 位"
            return
        }
        if passwordValue != confirmationValue {
            confirmationError = "两次输入的密码不一致"
            return
        }

        focusedField = nil
        registering = true

        Task { @MainActor in
            defer { registering = false }
            do {
                let token = try await APIClient.shared.register(
                    username: usernameValue,
                    password: passwordValue,
                    activationCode: activationValue
                )
                appState.authenticated(with: token)
            } catch {
                toast.show(error.localizedDescription)
            }
        }
    }
}
