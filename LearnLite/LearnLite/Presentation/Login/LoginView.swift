import SwiftUI

struct LoginView: View {
    private enum Field {
        case email
        case password
    }

    @StateObject private var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?
    private let onLoginSuccess: () -> Void

    init(
        viewModel: @autoclosure @escaping () -> LoginViewModel,
        onLoginSuccess: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.onLoginSuccess = onLoginSuccess
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)

                        Text("LearnLite")
                            .font(.largeTitle.bold())

                        Text("Sign in to continue learning.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .accessibilityElement(children: .combine)
                }

                Section {
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: .email)
                        .onSubmit { focusedField = .password }

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .focused($focusedField, equals: .password)
                        .onSubmit(submit)
                } header: {
                    Text("Demo account")
                } footer: {
                    Text("Use demo@learnlite.com / password")
                }

                Section {
                    Button(action: submit) {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Log in")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func submit() {
        focusedField = nil

        Task {
            if await viewModel.submit() {
                onLoginSuccess()
            }
        }
    }
}
