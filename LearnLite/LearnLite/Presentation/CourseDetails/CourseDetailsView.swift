import SwiftUI

struct CourseDetailsView: View {
    @StateObject private var viewModel: CourseDetailsViewModel

    init(viewModel: @autoclosure @escaping () -> CourseDetailsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        List {
            overviewSection
            lessonsSection

            if let error = viewModel.errorMessage {
                Section {
                    ErrorRow(message: error) {
                        Task { await viewModel.load() }
                    }
                }
            }
        }
        .navigationTitle(viewModel.course.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top, spacing: 0) {
            DataSourceBanner(source: viewModel.source)
        }
        .sensoryFeedback(.success, trigger: viewModel.completionCount)
        .task {
            await viewModel.load()
        }
    }

    private var overviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.course.description)
                    .foregroundStyle(.secondary)

                Text("Instructor: \(viewModel.course.instructor)")
                    .font(.subheadline)

                Text("\(viewModel.course.lessons.count) lessons · \(viewModel.course.totalDurationMinutes) min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ProgressView(value: viewModel.fraction)
                    .tint(.green)
                    .animation(.easeInOut, value: viewModel.fraction)

                Text("\(viewModel.completedCount) of \(viewModel.course.lessons.count) lessons completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if viewModel.isFinished {
                    Label("Course completed — great work!", systemImage: "party.popper.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
            .padding(.vertical, 8)
            .accessibilityElement(children: .combine)
        }
    }

    private var lessonsSection: some View {
        Section("Lessons") {
            ForEach(viewModel.course.lessons) { lesson in
                LessonRow(
                    lesson: lesson,
                    isCompleted: viewModel.isLessonCompleted(lesson.id),
                    isUpNext: viewModel.nextLesson?.id == lesson.id
                ) {
                    viewModel.toggleLesson(lesson.id)
                }
            }
        }
    }
}

private struct LessonRow: View {
    let lesson: Lesson
    let isCompleted: Bool
    let isUpNext: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? Color.green : Color.secondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(lesson.title)
                        .foregroundStyle(.primary)

                    Text("\(lesson.durationMinutes) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isUpNext {
                    Text("Up next")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(lesson.title), \(lesson.durationMinutes) minutes")
        .accessibilityValue(isCompleted ? "Completed" : "Not completed")
        .accessibilityHint(isCompleted ? "Marks the lesson as not completed" : "Marks the lesson as completed")
        .accessibilityAddTraits(.isButton)
    }
}
