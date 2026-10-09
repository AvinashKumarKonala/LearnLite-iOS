import Foundation

@MainActor
final class SessionViewModel: ObservableObject {
    @Published private(set) var isAuthenticated: Bool

    private let logoutUseCase: LogoutUseCase

    init(restoreSession: RestoreSessionUseCase, logout: LogoutUseCase) {
        self.isAuthenticated = restoreSession.execute()
        self.logoutUseCase = logout
    }

    func didLogin() {
        isAuthenticated = true
    }

    func logout() {
        logoutUseCase.execute()
        isAuthenticated = false
    }
}
