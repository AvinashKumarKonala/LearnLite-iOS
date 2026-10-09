import SwiftUI

struct CourseListView: View {
    @StateObject private var viewModel: CourseListViewModel
    private let makeDetailsViewModel: (Course) -> CourseDetailsViewModel
    private let onLogout: () -> Void

    init(
        viewModel: @autoclosure @escaping () -> CourseListViewModel,
        makeDetailsViewModel: @escaping (Course) -> CourseDetailsViewModel,
        onLogout: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.makeDetailsViewModel = makeDetailsViewModel
        self.onLogout = onLogout
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Courses")
                .navigationDestination(for: Course.self) { course in
                    CourseDetailsView(viewModel: makeDetailsViewModel(course))
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Log out", action: onLogout)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Toggle(isOn: $viewModel.isOfflineDemo) {
                            Label(
                                "Offline demo mode",
                                systemImage: viewModel.isOfflineDemo ? "wifi.slash" : "wifi"
                            )
                        }
                        .toggleStyle(.button)
                        .labelStyle(.iconOnly)
                    }
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    DataSourceBanner(source: viewModel.source)
                }
                .task {
                    await viewModel.loadIfNeeded()
                }
                .onAppear {
                    viewModel.refreshProgress()
                }
                .onChange(of: viewModel.isOfflineDemo) { _, _ in
                    Task { await viewModel.load() }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isInitialLoading {
            ProgressView("Loading courses…")
        } else if viewModel.courses.isEmpty {
            ContentUnavailableView {
                Label("No Courses", systemImage: "books.vertical")
            } description: {
                Text(viewModel.errorMessage ?? "No courses are available yet.")
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            courseList
        }
    }

    private var courseList: some View {
        List {
            if let message = viewModel.errorMessage {
                Section {
                    ErrorRow(message: message) {
                        Task { await viewModel.load() }
                    }
                }
            }

            Section {
                OverallProgressView(
                    percent: viewModel.overallPercent,
                    completedLessons: viewModel.completedLessons,
                    totalLessons: viewModel.totalLessons
                )
            }

            Section("Your courses") {
                ForEach(viewModel.courses) { course in
                    NavigationLink(value: course) {
                        CourseRow(
                            course: course,
                            percent: viewModel.percent(for: course),
                            actionTitle: actionTitle(for: course)
                        )
                    }
                }
            }
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private func actionTitle(for course: Course) -> String {
        if viewModel.progress.isFinished(course) { return "Review" }
        if viewModel.progress.completedCount(for: course) == 0 { return "Start" }
        return "Continue"
    }
}

private struct OverallProgressView: View {
    let percent: Int
    let completedLessons: Int
    let totalLessons: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Overall progress")
                    .font(.headline)
                Spacer()
                Text("\(percent)%")
                    .font(.title2.bold())
                    .monospacedDigit()
            }

            ProgressView(value: Double(percent), total: 100)

            Text("\(completedLessons) of \(totalLessons) lessons completed")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Overall progress")
        .accessibilityValue("\(percent) percent. \(completedLessons) of \(totalLessons) lessons completed.")
    }
}

private struct CourseRow: View {
    let course: Course
    let percent: Int
    let actionTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(course.title)
                .font(.headline)

            Text(course.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Label(course.instructor, systemImage: "person")
                Spacer()
                Text("\(course.lessons.count) lessons · \(course.totalDurationMinutes) min")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ProgressView(value: Double(percent), total: 100)

                Text("\(percent)%")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()

                Text(actionTitle)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(course.title), by \(course.instructor)")
        .accessibilityValue("\(percent) percent complete, \(course.lessons.count) lessons")
        .accessibilityHint("Opens the course. Action: \(actionTitle)")
    }
}
