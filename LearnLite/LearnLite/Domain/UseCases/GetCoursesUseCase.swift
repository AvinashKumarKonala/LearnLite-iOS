import Foundation

struct GetCoursesUseCase {
    let repository: any CourseRepository

    func execute() async throws -> Loaded<[Course]> {
        try await repository.fetchCourses()
    }
}
