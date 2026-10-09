import Foundation

/// Demo authentication. A real implementation would call the backend and store the
/// returned access/refresh tokens; here a random token stands in so session persistence
/// and Keychain storage are exercised end to end.
struct MockAuthenticationRepository: AuthenticationRepository {
    static let demoEmail = "demo@learnlite.com"
    static let demoPassword = "password"

    let tokenStore: any TokenStore
    let latency: Duration

    init(tokenStore: any TokenStore, latency: Duration = .milliseconds(350)) {
        self.tokenStore = tokenStore
        self.latency = latency
    }

    func login(email: String, password: String) async throws {
        try await Task.sleep(for: latency)

        guard email.lowercased() == Self.demoEmail,
              password == Self.demoPassword else {
            throw AppError.invalidCredentials
        }

        do {
            try tokenStore.save(token: UUID().uuidString)
        } catch {
            throw AppError.secureStorageFailed
        }
    }

    func hasActiveSession() -> Bool {
        tokenStore.token() != nil
    }

    func logout() {
        tokenStore.deleteToken()
    }
}
