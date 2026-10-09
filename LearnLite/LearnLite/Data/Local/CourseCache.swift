import Foundation

/// Versioned envelope so an incompatible cache is discarded instead of crashing or mis-decoding.
struct CachedCourses: Codable, Equatable {
    let schemaVersion: Int
    let savedAt: Date
    let courses: [Course]
}

final class CourseCache {
    static let currentSchemaVersion = 1

    private let key = "learnlite.cached.courses"
    private let defaults: UserDefaults
    private let now: () -> Date

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = { Date() }) {
        self.defaults = defaults
        self.now = now
    }

    func save(_ courses: [Course]) {
        write(
            CachedCourses(
                schemaVersion: Self.currentSchemaVersion,
                savedAt: now(),
                courses: courses
            )
        )
    }

    func load() -> CachedCourses? {
        guard
            let data = defaults.data(forKey: key),
            let cached = try? JSONDecoder().decode(CachedCourses.self, from: data),
            cached.schemaVersion == Self.currentSchemaVersion
        else {
            return nil
        }

        return cached
    }

    /// Refreshes a single course inside an existing cache.
    /// Never creates a cache from one course, which would make the offline course list look incomplete.
    func update(_ course: Course) {
        guard
            let cached = load(),
            let index = cached.courses.firstIndex(where: { $0.id == course.id })
        else {
            return
        }

        var courses = cached.courses
        courses[index] = course

        write(
            CachedCourses(
                schemaVersion: cached.schemaVersion,
                savedAt: cached.savedAt,
                courses: courses
            )
        )
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }

    private func write(_ cached: CachedCourses) {
        guard let data = try? JSONEncoder().encode(cached) else { return }
        defaults.set(data, forKey: key)
    }
}
