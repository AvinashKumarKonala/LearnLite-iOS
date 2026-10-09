import Foundation

struct RestoreSessionUseCase {
    let repository: any AuthenticationRepository

    func execute() -> Bool {
        repository.hasActiveSession()
    }
}
