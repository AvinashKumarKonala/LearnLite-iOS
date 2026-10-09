import Foundation

@MainActor
final class CourseListViewModel: ObservableObject {
    @Published private(set) var courses: [Course] = []
    @Published private(set) var progress = LearningProgress()
    @Published private(set) var source: DataSource = .remote
    @Published private(set) var isLoading = false
    @Published private(set) var hasLoaded = false
    @Published private(set) var errorMessage: String?

    /// Demo switch that makes the mock API behave as if the device were offline.
    @Published var isOfflineDemo: Bool {
        didSet { networkState.isOffline = isOfflineDemo }
    }

    private let getCourses: GetCoursesUseCase
    private let progressRepository: any ProgressRepository
    private let networkState: NetworkState
    private var loadGeneration = 0

    init(
        getCourses: GetCoursesUseCase,
        progressRepository: any ProgressRepository,
        networkState: NetworkState
    ) {
        self.getCourses = getCourses
        self.progressRepository = progressRepository
        self.networkState = networkState
        self.isOfflineDemo = networkState.isOffline
        self.progress = progressRepository.fetchProgress()
    }

    // MARK: - Derived state

    var isInitialLoading: Bool {
        courses.isEmpty && errorMessage == nil && (isLoading || !hasLoaded)
    }

    var totalLessons: Int {
        courses.reduce(0) { $0 + $1.lessons.count }
    }

    var completedLessons: Int {
        progress.completedCount(in: courses)
    }

    var overallPercent: Int {
        guard totalLessons > 0 else { return 0 }
        return Int((Double(completedLessons) / Double(totalLessons) * 100).rounded())
    }

    // MARK: - Actions

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        loadGeneration += 1
        let generation = loadGeneration

        isLoading = true
        errorMessage = nil

        do {
            let result = try await getCourses.execute()
            guard generation == loadGeneration else { return }
            courses = result.value
            source = result.source
            hasLoaded = true
        } catch is CancellationError {
            // The view went away or a newer load started; nothing to report.
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = AppError.map(error).errorDescription
        }

        guard generation == loadGeneration else { return }
        progress = progressRepository.fetchProgress()
        isLoading = false
    }

    /// Cheap, local-only refresh used when returning from a course screen.
    func refreshProgress() {
        progress = progressRepository.fetchProgress()
    }

    func percent(for course: Course) -> Int {
        progress.percentComplete(for: course)
    }
}
