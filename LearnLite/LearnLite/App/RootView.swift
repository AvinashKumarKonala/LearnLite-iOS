import SwiftUI

struct RootView: View {
    private let container: AppContainer
    @StateObject private var session: SessionViewModel

    @MainActor
    init(container: AppContainer) {
        self.container = container
        _session = StateObject(wrappedValue: container.makeSessionViewModel())
    }

    var body: some View {
        Group {
            if session.isAuthenticated {
                CourseListView(
                    viewModel: container.makeCourseListViewModel(),
                    makeDetailsViewModel: { course in
                        container.makeCourseDetailsViewModel(course: course)
                    },
                    onLogout: { session.logout() }
                )
            } else {
                LoginView(
                    viewModel: container.makeLoginViewModel(),
                    onLoginSuccess: { session.didLogin() }
                )
            }
        }
        .animation(.default, value: session.isAuthenticated)
    }
}
