import XCTest
@testable import LearnLite

@MainActor
final class LoginViewModelTests: XCTestCase {
    private func makeSUT(tokenStore: InMemoryTokenStore = InMemoryTokenStore()) -> LoginViewModel {
        let repository = MockAuthenticationRepository(tokenStore: tokenStore, latency: .zero)
        return LoginViewModel(login: LoginUseCase(repository: repository))
    }

    func testEmptyFieldsShowValidationMessage() async {
        let sut = makeSUT()
        sut.email = ""

        let success = await sut.submit()

        XCTAssertFalse(success)
        XCTAssertEqual(sut.errorMessage, "Enter your email and password.")
    }

    func testInvalidEmailShowsValidationMessage() async {
        let sut = makeSUT()
        sut.email = "not-an-email"

        let success = await sut.submit()

        XCTAssertFalse(success)
        XCTAssertEqual(sut.errorMessage, "Enter a valid email address.")
    }

    func testWrongPasswordShowsInvalidCredentials() async {
        let sut = makeSUT()
        sut.password = "wrong"

        let success = await sut.submit()

        XCTAssertFalse(success)
        XCTAssertEqual(sut.errorMessage, AppError.invalidCredentials.errorDescription)
        XCTAssertFalse(sut.isLoading)
    }

    func testDemoCredentialsSucceedAndClearError() async {
        let store = InMemoryTokenStore()
        let sut = makeSUT(tokenStore: store)

        let success = await sut.submit()

        XCTAssertTrue(success)
        XCTAssertNil(sut.errorMessage)
        XCTAssertNotNil(store.token())
        XCTAssertFalse(sut.isLoading)
    }

    func testSuccessfulSubmitAfterFailureClearsPreviousError() async {
        let sut = makeSUT()
        sut.password = "wrong"
        _ = await sut.submit()
        XCTAssertNotNil(sut.errorMessage)

        sut.password = MockAuthenticationRepository.demoPassword
        let success = await sut.submit()

        XCTAssertTrue(success)
        XCTAssertNil(sut.errorMessage)
    }

    func testEmailValidation() {
        XCTAssertTrue(LoginViewModel.isValidEmail("a@b.co"))
        XCTAssertTrue(LoginViewModel.isValidEmail("first.last@example.com"))
        XCTAssertFalse(LoginViewModel.isValidEmail("a@b"))
        XCTAssertFalse(LoginViewModel.isValidEmail("@b.com"))
        XCTAssertFalse(LoginViewModel.isValidEmail("a@@b.com"))
        XCTAssertFalse(LoginViewModel.isValidEmail("a@.com"))
        XCTAssertFalse(LoginViewModel.isValidEmail("a@b."))
        XCTAssertFalse(LoginViewModel.isValidEmail("a b@c.com"))
    }
}
