import XCTest
@testable import LearnLite

// MARK: - Doubles

final class StubCourseAPI: CourseAPI {
    var coursesResult: Result<[Course], Error> = .success(MockCourseData.courses)
    var courseHandler: (String) throws -> Course = { id in
        guard let course = MockCourseData.courses.first(where: { $0.id == id }) else {
            throw AppError.notFound
        }
        return course
    }

    private(set) var fetchCoursesCallCount = 0
    private(set) var fetchCourseCallCount = 0

    func fetchCourses() async throws -> [Course] {
        fetchCoursesCallCount += 1
        return try coursesResult.get()
    }

    func fetchCourse(id: String) async throws -> Course {
        fetchCourseCallCount += 1
        return try courseHandler(id)
    }
}

final class InMemoryProgressRepository: ProgressRepository {
    private(set) var stored: LearningProgress
    private(set) var saveCallCount = 0

    init(initial: LearningProgress = LearningProgress()) {
        self.stored = initial
    }

    func fetchProgress() -> LearningProgress {
        stored
    }

    func saveProgress(_ progress: LearningProgress) {
        saveCallCount += 1
        stored = progress
    }
}

final class InMemoryTokenStore: TokenStore {
    private(set) var storedToken: String?
    var saveError: Error?

    init(token: String? = nil) {
        self.storedToken = token
    }

    func token() -> String? {
        storedToken
    }

    func save(token: String) throws {
        if let saveError { throw saveError }
        storedToken = token
    }

    func deleteToken() {
        storedToken = nil
    }
}

// MARK: - Helpers

@MainActor
extension XCTestCase {
    /// An isolated `UserDefaults` that is removed when the test finishes.
    func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "LearnLiteTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }
}

enum Fixtures {
    static let lessons = [
        Lesson(id: "1", title: "One", durationMinutes: 10),
        Lesson(id: "2", title: "Two", durationMinutes: 10),
        Lesson(id: "3", title: "Three", durationMinutes: 10),
        Lesson(id: "4", title: "Four", durationMinutes: 10)
    ]

    static let course = Course(
        id: "course",
        title: "Test",
        description: "A test course",
        instructor: "Tester",
        lessons: lessons
    )
}
