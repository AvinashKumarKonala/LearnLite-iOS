import Foundation

struct ToggleLessonCompletionUseCase {
    let repository: any ProgressRepository

    /// Toggles the lesson, persists the result and returns the updated progress.
    @discardableResult
    func execute(lessonID: String) -> LearningProgress {
        var progress = repository.fetchProgress()
        progress.toggle(lessonID)
        repository.saveProgress(progress)
        return progress
    }
}
