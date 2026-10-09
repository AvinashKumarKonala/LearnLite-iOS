import XCTest
@testable import LearnLite

@MainActor
final class DefaultCourseRepositoryTests: XCTestCase {
    private func makeSUT(
        api: StubCourseAPI = StubCourseAPI(),
        savedAt: Date = Date(timeIntervalSince1970: 2_000)
    ) -> (repository: DefaultCourseRepository, cache: CourseCache, api: StubCourseAPI) {
        let cache = CourseCache(defaults: makeIsolatedDefaults(), now: { savedAt })
        return (DefaultCourseRepository(api: api, cache: cache), cache, api)
    }

    // MARK: - fetchCourses

    func testFetchCoursesReturnsRemoteDataAndCachesIt() async throws {
        let sut = makeSUT()

        let result = try await sut.repository.fetchCourses()

        XCTAssertEqual(result.value, MockCourseData.courses)
        XCTAssertEqual(result.source, .remote)
        XCTAssertEqual(sut.cache.load()?.courses, MockCourseData.courses)
    }

    func testFetchCoursesFallsBackToCacheWhenOffline() async throws {
        let savedAt = Date(timeIntervalSince1970: 3_000)
        let networkState = NetworkState(isOffline: true)
        let cache = CourseCache(defaults: makeIsolatedDefaults(), now: { savedAt })
        cache.save(MockCourseData.courses)
        let api = MockCourseAPI(networkState: networkState, latency: .zero)
        let repository = DefaultCourseRepository(api: api, cache: cache)

        let result = try await repository.fetchCourses()

        XCTAssertEqual(result.value, MockCourseData.courses)
        XCTAssertEqual(result.source, .cache(savedAt: savedAt))
    }

    func testFetchCoursesFallsBackToCacheOnAnyFailure() async throws {
        let api = StubCourseAPI()
        let sut = makeSUT(api: api)
        sut.cache.save(MockCourseData.courses)
        api.coursesResult = .failure(AppError.unknown)

        let result = try await sut.repository.fetchCourses()

        XCTAssertEqual(result.value, MockCourseData.courses)
        XCTAssertEqual(result.source, .cache(savedAt: Date(timeIntervalSince1970: 2_000)))
    }

    func testFetchCoursesThrowsOfflineWhenOfflineAndNothingCached() async {
        let api = StubCourseAPI()
        api.coursesResult = .failure(AppError.offline)
        let sut = makeSUT(api: api)

        do {
            _ = try await sut.repository.fetchCourses()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? AppError, .offline)
        }
    }

    func testFetchCoursesMapsURLErrorsToOffline() async {
        let api = StubCourseAPI()
        api.coursesResult = .failure(URLError(.notConnectedToInternet))
        let sut = makeSUT(api: api)

        do {
            _ = try await sut.repository.fetchCourses()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? AppError, .offline)
        }
    }

    func testFetchCoursesMapsUnknownErrors() async {
        struct Boom: Error {}
        let api = StubCourseAPI()
        api.coursesResult = .failure(Boom())
        let sut = makeSUT(api: api)

        do {
            _ = try await sut.repository.fetchCourses()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? AppError, .unknown)
        }
    }

    func testFetchCoursesPropagatesCancellationInsteadOfServingCache() async {
        let api = StubCourseAPI()
        let sut = makeSUT(api: api)
        sut.cache.save(MockCourseData.courses)
        api.coursesResult = .failure(CancellationError())

        do {
            _ = try await sut.repository.fetchCourses()
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }

    // MARK: - fetchCourse

    func testFetchCourseReturnsRemoteAndRefreshesExistingCacheEntry() async throws {
        let api = StubCourseAPI()
        let sut = makeSUT(api: api)
        sut.cache.save(MockCourseData.courses)
        let original = MockCourseData.courses[0]
        let refreshed = Course(
            id: original.id,
            title: "Fresh title",
            description: original.description,
            instructor: original.instructor,
            lessons: original.lessons
        )
        api.courseHandler = { _ in refreshed }

        let result = try await sut.repository.fetchCourse(id: original.id)

        XCTAssertEqual(result.value, refreshed)
        XCTAssertEqual(result.source, .remote)
        XCTAssertEqual(sut.cache.load()?.courses.first?.title, "Fresh title")
    }

    func testFetchCourseDoesNotCreatePartialCourseListCache() async throws {
        let sut = makeSUT()

        _ = try await sut.repository.fetchCourse(id: MockCourseData.courses[0].id)

        XCTAssertNil(sut.cache.load())
    }

    func testFetchCourseFallsBackToCachedCourseWhenOffline() async throws {
        let api = StubCourseAPI()
        let sut = makeSUT(api: api)
        sut.cache.save(MockCourseData.courses)
        api.courseHandler = { _ in throw AppError.offline }
        let expected = MockCourseData.courses[1]

        let result = try await sut.repository.fetchCourse(id: expected.id)

        XCTAssertEqual(result.value, expected)
        XCTAssertEqual(result.source, .cache(savedAt: Date(timeIntervalSince1970: 2_000)))
    }

    func testFetchCourseThrowsWhenOfflineAndNotCached() async {
        let api = StubCourseAPI()
        api.courseHandler = { _ in throw AppError.offline }
        let sut = makeSUT(api: api)

        do {
            _ = try await sut.repository.fetchCourse(id: "ios-swift")
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? AppError, .offline)
        }
    }

    func testFetchUnknownCourseThrowsNotFound() async {
        let sut = makeSUT()

        do {
            _ = try await sut.repository.fetchCourse(id: "does-not-exist")
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? AppError, .notFound)
        }
    }
}
