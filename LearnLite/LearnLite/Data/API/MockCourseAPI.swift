import Foundation

struct MockCourseAPI: CourseAPI {
    let networkState: NetworkState
    let latency: Duration

    init(networkState: NetworkState, latency: Duration = .milliseconds(300)) {
        self.networkState = networkState
        self.latency = latency
    }

    func fetchCourses() async throws -> [Course] {
        try await Task.sleep(for: latency)

        if networkState.isOffline {
            throw AppError.offline
        }

        return MockCourseData.courses
    }

    func fetchCourse(id: String) async throws -> Course {
        try await Task.sleep(for: latency)

        if networkState.isOffline {
            throw AppError.offline
        }

        guard let course = MockCourseData.courses.first(where: { $0.id == id }) else {
            throw AppError.notFound
        }

        return course
    }
}
