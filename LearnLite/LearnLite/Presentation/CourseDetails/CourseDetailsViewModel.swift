import Foundation

@MainActor
final class CourseDetailsViewModel: ObservableObject {
    @Published private(set) var course: Course
    @Published private(set) var progress: LearningProgress
    @Published private(set) var source: DataSource = .remote
    @Published private(set) var errorMessage: String?
    /// Increments each time a lesson is marked complete; drives haptic feedback.
    @Published private(set) var completionCount = 0

    private let getCourseDetails: GetCourseDetailsUseCase
    private let toggleCompletion: ToggleLessonCompletionUseCase
    private let progressRepository: any ProgressRepository

    init(
        course: Course,
        getCourseDetails: GetCourseDetailsUseCase,
        toggleCompletion: ToggleLessonCompletionUseCase,
        progressRepository: any ProgressRepository
    ) {
        self.course = course
        self.getCourseDetails = getCourseDetails
        self.toggleCompletion = toggleCompletion
        self.progressRepository = progressRepository
        self.progress = progressRepository.fetchProgress()
    }

    // MARK: - Derived state

    var completedCount: Int {
        progress.completedCount(for: course)
    }

    var fraction: Double {
        progress.progress(for: course)
    }

    var nextLesson: Lesson? {
        progress.nextLesson(in: course)
    }

    var isFinished: Bool {
        progress.isFinished(course)
    }

    func isLessonCompleted(_ lessonID: String) -> Bool {
        progress.isCompleted(lessonID)
    }

    // MARK: - Actions

    func load() async {
        do {
            let result = try await getCourseDetails.execute(id: course.id)
            course = result.value
            source = result.source
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = AppError.map(error).errorDescription
        }

        progress = progressRepository.fetchProgress()
    }

    func toggleLesson(_ lessonID: String) {
        let wasCompleted = progress.isCompleted(lessonID)
        progress = toggleCompletion.execute(lessonID: lessonID)

        if !wasCompleted {
            completionCount += 1
        }
    }
}
