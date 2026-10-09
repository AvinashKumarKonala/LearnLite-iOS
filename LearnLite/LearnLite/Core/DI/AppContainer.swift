import Foundation

/// Composition root. Builds the object graph once and hands out view models.
final class AppContainer {
    private let networkState: NetworkState
    private let courseRepository: any CourseRepository
    private let progressRepository: any ProgressRepository
    private let authenticationRepository: any AuthenticationRepository

    init(
        defaults: UserDefaults = .standard,
        tokenStore: any TokenStore = KeychainTokenStore()
    ) {
        // Keychain items survive app deletion, UserDefaults do not. Clear any stale
        // session on the first launch after a (re)install.
        let firstLaunchKey = "learnlite.has.launched"
        if !defaults.bool(forKey: firstLaunchKey) {
            tokenStore.deleteToken()
            defaults.set(true, forKey: firstLaunchKey)
        }

        let networkState = NetworkState()
        let api = MockCourseAPI(networkState: networkState)

        self.networkState = networkState
        self.courseRepository = DefaultCourseRepository(
            api: api,
            cache: CourseCache(defaults: defaults)
        )
        self.progressRepository = UserDefaultsProgressRepository(defaults: defaults)
        self.authenticationRepository = MockAuthenticationRepository(tokenStore: tokenStore)
    }

    // MARK: - View model factories

    @MainActor
    func makeSessionViewModel() -> SessionViewModel {
        SessionViewModel(
            restoreSession: RestoreSessionUseCase(repository: authenticationRepository),
            logout: LogoutUseCase(repository: authenticationRepository)
        )
    }

    @MainActor
    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(login: LoginUseCase(repository: authenticationRepository))
    }

    @MainActor
    func makeCourseListViewModel() -> CourseListViewModel {
        CourseListViewModel(
            getCourses: GetCoursesUseCase(repository: courseRepository),
            progressRepository: progressRepository,
            networkState: networkState
        )
    }

    @MainActor
    func makeCourseDetailsViewModel(course: Course) -> CourseDetailsViewModel {
        CourseDetailsViewModel(
            course: course,
            getCourseDetails: GetCourseDetailsUseCase(repository: courseRepository),
            toggleCompletion: ToggleLessonCompletionUseCase(repository: progressRepository),
            progressRepository: progressRepository
        )
    }
}
