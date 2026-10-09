import Foundation

protocol CourseAPI {
    func fetchCourses() async throws -> [Course]
    func fetchCourse(id: String) async throws -> Course
}

protocol CourseRepository {
    func fetchCourses() async throws -> Loaded<[Course]>
    func fetchCourse(id: String) async throws -> Loaded<Course>
}
