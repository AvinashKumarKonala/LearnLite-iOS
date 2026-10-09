import Foundation

struct LoginUseCase {
    let repository: any AuthenticationRepository

    func execute(email: String, password: String) async throws {
        try await repository.login(email: email, password: password)
    }
}
