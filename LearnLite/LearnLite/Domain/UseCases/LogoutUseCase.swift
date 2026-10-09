import Foundation

struct LogoutUseCase {
    let repository: any AuthenticationRepository

    func execute() {
        repository.logout()
    }
}
