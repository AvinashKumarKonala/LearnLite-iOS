import XCTest
@testable import LearnLite

@MainActor
final class AppErrorTests: XCTestCase {
    func testMapPassesThroughAppErrors() {
        XCTAssertEqual(AppError.map(AppError.notFound), .notFound)
    }

    func testMapTreatsConnectivityURLErrorsAsOffline() {
        let codes: [URLError.Code] = [
            .notConnectedToInternet,
            .networkConnectionLost,
            .dataNotAllowed
        ]

        for code in codes {
            XCTAssertEqual(AppError.map(URLError(code)), .offline)
        }
    }

    func testMapTreatsOtherErrorsAsUnknown() {
        struct Boom: Error {}

        XCTAssertEqual(AppError.map(Boom()), .unknown)
        XCTAssertEqual(AppError.map(URLError(.badURL)), .unknown)
    }

    func testEveryErrorHasAUserFacingMessage() {
        let all: [AppError] = [.invalidCredentials, .offline, .notFound, .secureStorageFailed, .unknown]

        for error in all {
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
    }
}
