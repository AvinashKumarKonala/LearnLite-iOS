import Foundation

enum AppError: LocalizedError, Equatable {
    case invalidCredentials
    case offline
    case notFound
    case secureStorageFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password."
        case .offline:
            return "You're offline and there's no saved data yet. Reconnect and try again."
        case .notFound:
            return "That course couldn't be found."
        case .secureStorageFailed:
            return "Couldn't save your session securely. Please try again."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }

    /// Normalises any thrown error into a user-presentable `AppError`.
    static func map(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .dataNotAllowed,
                 .internationalRoamingOff:
                return .offline
            default:
                return .unknown
            }
        }

        return .unknown
    }
}
