import Foundation

protocol ProgressRepository {
    func fetchProgress() -> LearningProgress
    func saveProgress(_ progress: LearningProgress)
}
