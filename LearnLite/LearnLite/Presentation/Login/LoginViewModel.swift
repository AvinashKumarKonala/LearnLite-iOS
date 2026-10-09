import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = MockAuthenticationRepository.demoEmail
    @Published var password = MockAuthenticationRepository.demoPassword
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let login: LoginUseCase

    init(login: LoginUseCase) {
        self.login = login
    }

    /// Returns `true` when the user was signed in.
    func submit() async -> Bool {
        guard !isLoading else { return false }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Enter your email and password."
            return false
        }

        guard Self.isValidEmail(trimmedEmail) else {
            errorMessage = "Enter a valid email address."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await login.execute(email: trimmedEmail, password: password)
            return true
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = AppError.map(error).errorDescription
            return false
        }
    }

    static func isValidEmail(_ email: String) -> Bool {
        guard !email.contains(" ") else { return false }

        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else { return false }

        let domain = parts[1]
        return domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
    }
}
