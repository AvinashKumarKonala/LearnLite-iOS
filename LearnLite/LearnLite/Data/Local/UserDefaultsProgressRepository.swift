import Foundation

final class UserDefaultsProgressRepository: ProgressRepository {
    private let key = "learnlite.learning.progress"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetchProgress() -> LearningProgress {
        guard
            let data = defaults.data(forKey: key),
            let progress = try? JSONDecoder().decode(LearningProgress.self, from: data)
        else {
            return LearningProgress()
        }

        return progress
    }

    func saveProgress(_ progress: LearningProgress) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: key)
    }
}
