import Foundation

struct GetCourseDetailsUseCase {
    let repository: any CourseRepository

    func execute(id: String) async throws -> Loaded<Course> {
        try await repository.fetchCourse(id: id)
    }
}
