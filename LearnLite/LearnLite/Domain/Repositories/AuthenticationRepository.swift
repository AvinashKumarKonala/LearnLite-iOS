import Foundation

protocol AuthenticationRepository {
    func login(email: String, password: String) async throws
    func hasActiveSession() -> Bool
    func logout()
}
