import Foundation

struct LearningProgress: Codable, Equatable {
    private(set) var completedLessonIDs: Set<String>

    init(completedLessonIDs: Set<String> = []) {
        self.completedLessonIDs = completedLessonIDs
    }

    func isCompleted(_ lessonID: String) -> Bool {
        completedLessonIDs.contains(lessonID)
    }

    mutating func toggle(_ lessonID: String) {
        if completedLessonIDs.contains(lessonID) {
            completedLessonIDs.remove(lessonID)
        } else {
            completedLessonIDs.insert(lessonID)
        }
    }

    func completedCount(for course: Course) -> Int {
        course.lessons.filter { isCompleted($0.id) }.count
    }

    func completedCount(in courses: [Course]) -> Int {
        courses.reduce(0) { $0 + completedCount(for: $1) }
    }

    /// Fraction between 0 and 1.
    func progress(for course: Course) -> Double {
        guard !course.lessons.isEmpty else { return 0 }
        return Double(completedCount(for: course)) / Double(course.lessons.count)
    }

    /// Whole-number percentage between 0 and 100.
    func percentComplete(for course: Course) -> Int {
        Int((progress(for: course) * 100).rounded())
    }

    func isFinished(_ course: Course) -> Bool {
        !course.lessons.isEmpty && completedCount(for: course) == course.lessons.count
    }

    func nextLesson(in course: Course) -> Lesson? {
        course.lessons.first { !isCompleted($0.id) }
    }
}
