import Foundation

/// Remote-first repository with a cache fallback.
final class DefaultCourseRepository: CourseRepository {
    private let api: any CourseAPI
    private let cache: CourseCache

    init(api: any CourseAPI, cache: CourseCache) {
        self.api = api
        self.cache = cache
    }

    func fetchCourses() async throws -> Loaded<[Course]> {
        do {
            let courses = try await api.fetchCourses()
            cache.save(courses)
            return Loaded(value: courses, source: .remote)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if let cached = cache.load() {
                return Loaded(value: cached.courses, source: .cache(savedAt: cached.savedAt))
            }
            throw AppError.map(error)
        }
    }

    func fetchCourse(id: String) async throws -> Loaded<Course> {
        do {
            let course = try await api.fetchCourse(id: id)
            cache.update(course)
            return Loaded(value: course, source: .remote)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if
                let cached = cache.load(),
                let course = cached.courses.first(where: { $0.id == id })
            {
                return Loaded(value: course, source: .cache(savedAt: cached.savedAt))
            }
            throw AppError.map(error)
        }
    }
}
