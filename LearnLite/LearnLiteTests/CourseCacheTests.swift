import XCTest
@testable import LearnLite

@MainActor
final class CourseCacheTests: XCTestCase {
    func testRoundTripPreservesCoursesAndTimestamp() {
        let savedAt = Date(timeIntervalSince1970: 1_000)
        let cache = CourseCache(defaults: makeIsolatedDefaults(), now: { savedAt })

        cache.save(MockCourseData.courses)

        let loaded = cache.load()
        XCTAssertEqual(loaded?.courses, MockCourseData.courses)
        XCTAssertEqual(loaded?.savedAt, savedAt)
    }

    func testLoadReturnsNilWhenEmpty() {
        let cache = CourseCache(defaults: makeIsolatedDefaults())

        XCTAssertNil(cache.load())
    }

    func testLoadReturnsNilForCorruptData() {
        let defaults = makeIsolatedDefaults()
        defaults.set(Data("not json".utf8), forKey: "learnlite.cached.courses")

        XCTAssertNil(CourseCache(defaults: defaults).load())
    }

    func testLoadDiscardsIncompatibleSchemaVersion() throws {
        let defaults = makeIsolatedDefaults()
        let stale = CachedCourses(
            schemaVersion: CourseCache.currentSchemaVersion + 1,
            savedAt: Date(),
            courses: MockCourseData.courses
        )
        defaults.set(try JSONEncoder().encode(stale), forKey: "learnlite.cached.courses")

        XCTAssertNil(CourseCache(defaults: defaults).load())
    }

    func testUpdateReplacesExistingCourseAndKeepsTimestamp() {
        let savedAt = Date(timeIntervalSince1970: 500)
        let cache = CourseCache(defaults: makeIsolatedDefaults(), now: { savedAt })
        cache.save(MockCourseData.courses)

        let original = MockCourseData.courses[0]
        let edited = Course(
            id: original.id,
            title: "Edited title",
            description: original.description,
            instructor: original.instructor,
            lessons: original.lessons
        )
        cache.update(edited)

        let loaded = cache.load()
        XCTAssertEqual(loaded?.courses.first?.title, "Edited title")
        XCTAssertEqual(loaded?.courses.count, MockCourseData.courses.count)
        XCTAssertEqual(loaded?.savedAt, savedAt)
    }

    func testUpdateDoesNotCreateAPartialCache() {
        let cache = CourseCache(defaults: makeIsolatedDefaults())

        cache.update(MockCourseData.courses[0])

        XCTAssertNil(cache.load())
    }

    func testClearRemovesCache() {
        let cache = CourseCache(defaults: makeIsolatedDefaults())
        cache.save(MockCourseData.courses)

        cache.clear()

        XCTAssertNil(cache.load())
    }

    func testProgressRepositoryPersistsAcrossInstances() {
        let defaults = makeIsolatedDefaults()
        let first = UserDefaultsProgressRepository(defaults: defaults)
        first.saveProgress(LearningProgress(completedLessonIDs: ["swift-1"]))

        let second = UserDefaultsProgressRepository(defaults: defaults)

        XCTAssertTrue(second.fetchProgress().isCompleted("swift-1"))
    }
}
