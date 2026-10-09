import XCTest
@testable import LearnLite

@MainActor
final class CourseListViewModelTests: XCTestCase {
    private struct Context {
        let viewModel: CourseListViewModel
        let api: StubCourseAPI
        let cache: CourseCache
        let progress: InMemoryProgressRepository
        let networkState: NetworkState
    }

    private func makeSUT(
        progress: LearningProgress = LearningProgress(),
        networkState: NetworkState = NetworkState()
    ) -> Context {
        let api = StubCourseAPI()
        let cache = CourseCache(defaults: makeIsolatedDefaults(), now: { Date(timeIntervalSince1970: 100) })
        let progressRepository = InMemoryProgressRepository(initial: progress)
        let repository = DefaultCourseRepository(api: api, cache: cache)
        let viewModel = CourseListViewModel(
            getCourses: GetCoursesUseCase(repository: repository),
            progressRepository: progressRepository,
            networkState: networkState
        )
        return Context(
            viewModel: viewModel,
            api: api,
            cache: cache,
            progress: progressRepository,
            networkState: networkState
        )
    }

    func testInitialStateIsLoading() {
        let sut = makeSUT()

        XCTAssertTrue(sut.viewModel.isInitialLoading)
        XCTAssertTrue(sut.viewModel.courses.isEmpty)
    }

    func testLoadPublishesCoursesFromRemote() async {
        let sut = makeSUT()

        await sut.viewModel.load()

        XCTAssertEqual(sut.viewModel.courses, MockCourseData.courses)
        XCTAssertEqual(sut.viewModel.source, .remote)
        XCTAssertNil(sut.viewModel.errorMessage)
        XCTAssertFalse(sut.viewModel.isLoading)
        XCTAssertFalse(sut.viewModel.isInitialLoading)
    }

    func testLoadIfNeededOnlyLoadsOnce() async {
        let sut = makeSUT()

        await sut.viewModel.loadIfNeeded()
        await sut.viewModel.loadIfNeeded()

        XCTAssertEqual(sut.api.fetchCoursesCallCount, 1)
    }

    func testLoadUsesCacheWhenRemoteFails() async {
        let sut = makeSUT()
        sut.cache.save(MockCourseData.courses)
        sut.api.coursesResult = .failure(AppError.offline)

        await sut.viewModel.load()

        XCTAssertEqual(sut.viewModel.courses, MockCourseData.courses)
        XCTAssertEqual(sut.viewModel.source, .cache(savedAt: Date(timeIntervalSince1970: 100)))
        XCTAssertNil(sut.viewModel.errorMessage)
    }

    func testLoadShowsErrorWhenNothingIsCached() async {
        let sut = makeSUT()
        sut.api.coursesResult = .failure(AppError.offline)

        await sut.viewModel.load()

        XCTAssertTrue(sut.viewModel.courses.isEmpty)
        XCTAssertEqual(sut.viewModel.errorMessage, AppError.offline.errorDescription)
        XCTAssertFalse(sut.viewModel.isInitialLoading)
        XCTAssertFalse(sut.viewModel.isLoading)
    }

    func testRetryAfterFailureRecovers() async {
        let sut = makeSUT()
        sut.api.coursesResult = .failure(AppError.unknown)
        await sut.viewModel.load()
        XCTAssertNotNil(sut.viewModel.errorMessage)

        sut.api.coursesResult = .success(MockCourseData.courses)
        await sut.viewModel.load()

        XCTAssertNil(sut.viewModel.errorMessage)
        XCTAssertEqual(sut.viewModel.courses, MockCourseData.courses)
    }

    func testRefreshFailureKeepsExistingCourses() async {
        let sut = makeSUT()
        await sut.viewModel.load()

        sut.api.coursesResult = .failure(AppError.unknown)
        sut.cache.clear()
        await sut.viewModel.load()

        XCTAssertEqual(sut.viewModel.courses, MockCourseData.courses)
        XCTAssertEqual(sut.viewModel.errorMessage, AppError.unknown.errorDescription)
    }

    func testOfflineDemoToggleUpdatesNetworkState() {
        let sut = makeSUT()

        sut.viewModel.isOfflineDemo = true
        XCTAssertTrue(sut.networkState.isOffline)

        sut.viewModel.isOfflineDemo = false
        XCTAssertFalse(sut.networkState.isOffline)
    }

    func testOfflineDemoReflectsExistingNetworkState() {
        let sut = makeSUT(networkState: NetworkState(isOffline: true))

        XCTAssertTrue(sut.viewModel.isOfflineDemo)
    }

    func testProgressAndOverallStatsReflectStoredProgress() async {
        let sut = makeSUT(progress: LearningProgress(completedLessonIDs: ["swift-1", "swift-2", "ui-1"]))

        await sut.viewModel.load()

        XCTAssertEqual(sut.viewModel.totalLessons, 12)
        XCTAssertEqual(sut.viewModel.completedLessons, 3)
        XCTAssertEqual(sut.viewModel.overallPercent, 25)
        XCTAssertEqual(sut.viewModel.percent(for: MockCourseData.courses[0]), 50)
        XCTAssertEqual(sut.viewModel.percent(for: MockCourseData.courses[1]), 25)
        XCTAssertEqual(sut.viewModel.percent(for: MockCourseData.courses[2]), 0)
    }

    func testRefreshProgressPicksUpChangesMadeElsewhere() async {
        let sut = makeSUT()
        await sut.viewModel.load()
        XCTAssertEqual(sut.viewModel.completedLessons, 0)

        sut.progress.saveProgress(LearningProgress(completedLessonIDs: ["swift-1"]))
        sut.viewModel.refreshProgress()

        XCTAssertEqual(sut.viewModel.completedLessons, 1)
    }

    func testOverallPercentIsZeroBeforeLoading() {
        let sut = makeSUT()

        XCTAssertEqual(sut.viewModel.overallPercent, 0)
    }
}
