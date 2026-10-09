import XCTest
@testable import LearnLite

@MainActor
final class CourseDetailsViewModelTests: XCTestCase {
    private struct Context {
        let viewModel: CourseDetailsViewModel
        let api: StubCourseAPI
        let progress: InMemoryProgressRepository
    }

    private func makeSUT(
        course: Course = MockCourseData.courses[0],
        progress: LearningProgress = LearningProgress()
    ) -> Context {
        let api = StubCourseAPI()
        let cache = CourseCache(defaults: makeIsolatedDefaults())
        let progressRepository = InMemoryProgressRepository(initial: progress)
        let repository = DefaultCourseRepository(api: api, cache: cache)
        let viewModel = CourseDetailsViewModel(
            course: course,
            getCourseDetails: GetCourseDetailsUseCase(repository: repository),
            toggleCompletion: ToggleLessonCompletionUseCase(repository: progressRepository),
            progressRepository: progressRepository
        )
        return Context(viewModel: viewModel, api: api, progress: progressRepository)
    }

    func testToggleCompletesLessonAndPersists() {
        let sut = makeSUT()
        let lessonID = MockCourseData.courses[0].lessons[0].id

        sut.viewModel.toggleLesson(lessonID)

        XCTAssertTrue(sut.viewModel.isLessonCompleted(lessonID))
        XCTAssertTrue(sut.progress.fetchProgress().isCompleted(lessonID))
        XCTAssertEqual(sut.viewModel.completedCount, 1)
        XCTAssertEqual(sut.viewModel.fraction, 0.25)
    }

    func testTogglingTwiceUncompletesLesson() {
        let sut = makeSUT()
        let lessonID = MockCourseData.courses[0].lessons[0].id

        sut.viewModel.toggleLesson(lessonID)
        sut.viewModel.toggleLesson(lessonID)

        XCTAssertFalse(sut.viewModel.isLessonCompleted(lessonID))
        XCTAssertEqual(sut.viewModel.completedCount, 0)
    }

    func testCompletionCountOnlyIncrementsWhenCompleting() {
        let sut = makeSUT()
        let lessonID = MockCourseData.courses[0].lessons[0].id

        sut.viewModel.toggleLesson(lessonID)
        XCTAssertEqual(sut.viewModel.completionCount, 1)

        sut.viewModel.toggleLesson(lessonID)
        XCTAssertEqual(sut.viewModel.completionCount, 1)
    }

    func testNextLessonAdvancesAsLessonsAreCompleted() {
        let sut = makeSUT()
        let lessons = MockCourseData.courses[0].lessons

        XCTAssertEqual(sut.viewModel.nextLesson?.id, lessons[0].id)

        sut.viewModel.toggleLesson(lessons[0].id)
        XCTAssertEqual(sut.viewModel.nextLesson?.id, lessons[1].id)
    }

    func testCourseIsFinishedWhenAllLessonsCompleted() {
        let course = MockCourseData.courses[0]
        let sut = makeSUT(course: course)

        XCTAssertFalse(sut.viewModel.isFinished)

        course.lessons.forEach { sut.viewModel.toggleLesson($0.id) }

        XCTAssertTrue(sut.viewModel.isFinished)
        XCTAssertNil(sut.viewModel.nextLesson)
    }

    func testInitialProgressIsLoadedFromRepository() {
        let course = MockCourseData.courses[0]
        let sut = makeSUT(
            course: course,
            progress: LearningProgress(completedLessonIDs: [course.lessons[0].id])
        )

        XCTAssertEqual(sut.viewModel.completedCount, 1)
    }

    func testLoadFetchesCourseFromRemote() async {
        let sut = makeSUT()

        await sut.viewModel.load()

        XCTAssertEqual(sut.viewModel.course, MockCourseData.courses[0])
        XCTAssertEqual(sut.viewModel.source, .remote)
        XCTAssertNil(sut.viewModel.errorMessage)
    }

    func testLoadFailureShowsErrorAndKeepsExistingCourse() async {
        let sut = makeSUT()
        sut.api.courseHandler = { _ in throw AppError.offline }

        await sut.viewModel.load()

        XCTAssertEqual(sut.viewModel.course, MockCourseData.courses[0])
        XCTAssertEqual(sut.viewModel.errorMessage, AppError.offline.errorDescription)
    }

    func testLoadSuccessClearsPreviousError() async {
        let sut = makeSUT()
        sut.api.courseHandler = { _ in throw AppError.unknown }
        await sut.viewModel.load()
        XCTAssertNotNil(sut.viewModel.errorMessage)

        sut.api.courseHandler = { id in MockCourseData.courses.first { $0.id == id }! }
        await sut.viewModel.load()

        XCTAssertNil(sut.viewModel.errorMessage)
    }

    func testToggleLessonUseCaseReturnsAndPersistsProgress() {
        let repository = InMemoryProgressRepository()
        let useCase = ToggleLessonCompletionUseCase(repository: repository)

        let updated = useCase.execute(lessonID: "swift-1")

        XCTAssertTrue(updated.isCompleted("swift-1"))
        XCTAssertEqual(repository.fetchProgress(), updated)
        XCTAssertEqual(repository.saveCallCount, 1)
    }
}
