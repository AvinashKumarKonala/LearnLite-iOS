import XCTest
@testable import LearnLite

@MainActor
final class AuthenticationTests: XCTestCase {
    private func makeRepository(tokenStore: InMemoryTokenStore) -> MockAuthenticationRepository {
        MockAuthenticationRepository(tokenStore: tokenStore, latency: .zero)
    }

    func testLoginWithDemoCredentialsStoresToken() async throws {
        let store = InMemoryTokenStore()
        let repository = makeRepository(tokenStore: store)

        try await repository.login(email: "demo@learnlite.com", password: "password")

        XCTAssertNotNil(store.token())
        XCTAssertTrue(repository.hasActiveSession())
    }

    func testLoginIsCaseInsensitiveForEmail() async throws {
        let store = InMemoryTokenStore()
        let repository = makeRepository(tokenStore: store)

        try await repository.login(email: "Demo@LearnLite.com", password: "password")

        XCTAssertNotNil(store.token())
    }

    func testLoginWithWrongPasswordFailsAndStoresNothing() async {
        let store = InMemoryTokenStore()
        let repository = makeRepository(tokenStore: store)

        do {
            try await repository.login(email: "demo@learnlite.com", password: "wrong")
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? AppError, .invalidCredentials)
        }

        XCTAssertNil(store.token())
        XCTAssertFalse(repository.hasActiveSession())
    }

    func testLoginReportsSecureStorageFailure() async {
        let store = InMemoryTokenStore()
        store.saveError = KeychainError.unhandled(-1)
        let repository = makeRepository(tokenStore: store)

        do {
            try await repository.login(email: "demo@learnlite.com", password: "password")
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? AppError, .secureStorageFailed)
        }
    }

    func testLogoutClearsSession() {
        let store = InMemoryTokenStore(token: "token")
        let repository = makeRepository(tokenStore: store)

        XCTAssertTrue(repository.hasActiveSession())

        repository.logout()

        XCTAssertFalse(repository.hasActiveSession())
        XCTAssertNil(store.token())
    }

    func testKeychainTokenStoreRoundTrip() throws {
        let store = KeychainTokenStore(service: "com.avinash.LearnLiteTests.\(UUID().uuidString)")
        addTeardownBlock { store.deleteToken() }

        do {
            try store.save(token: "first")
        } catch {
            throw XCTSkip("Keychain is not available in this test environment: \(error)")
        }

        XCTAssertEqual(store.token(), "first")

        try store.save(token: "second")
        XCTAssertEqual(store.token(), "second")

        store.deleteToken()
        XCTAssertNil(store.token())
    }

    // MARK: - Session view model

    func testSessionStartsAuthenticatedWhenTokenExists() {
        let repository = makeRepository(tokenStore: InMemoryTokenStore(token: "token"))
        let session = SessionViewModel(
            restoreSession: RestoreSessionUseCase(repository: repository),
            logout: LogoutUseCase(repository: repository)
        )

        XCTAssertTrue(session.isAuthenticated)
    }

    func testSessionStartsLoggedOutWithoutToken() {
        let repository = makeRepository(tokenStore: InMemoryTokenStore())
        let session = SessionViewModel(
            restoreSession: RestoreSessionUseCase(repository: repository),
            logout: LogoutUseCase(repository: repository)
        )

        XCTAssertFalse(session.isAuthenticated)
    }

    func testSessionLogoutClearsTokenAndState() {
        let store = InMemoryTokenStore(token: "token")
        let repository = makeRepository(tokenStore: store)
        let session = SessionViewModel(
            restoreSession: RestoreSessionUseCase(repository: repository),
            logout: LogoutUseCase(repository: repository)
        )

        session.logout()

        XCTAssertFalse(session.isAuthenticated)
        XCTAssertNil(store.token())
    }

    func testSessionDidLoginMarksAuthenticated() {
        let repository = makeRepository(tokenStore: InMemoryTokenStore())
        let session = SessionViewModel(
            restoreSession: RestoreSessionUseCase(repository: repository),
            logout: LogoutUseCase(repository: repository)
        )

        session.didLogin()

        XCTAssertTrue(session.isAuthenticated)
    }
}
