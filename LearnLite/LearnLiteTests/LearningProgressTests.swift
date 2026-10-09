import XCTest
@testable import LearnLite

@MainActor
final class LearningProgressTests: XCTestCase {
    func testToggleMarksAndUnmarksLesson() {
        var progress = LearningProgress()

        XCTAssertFalse(progress.isCompleted("lesson-1"))

        progress.toggle("lesson-1")
        XCTAssertTrue(progress.isCompleted("lesson-1"))

        progress.toggle("lesson-1")
        XCTAssertFalse(progress.isCompleted("lesson-1"))
    }

    func testProgressFractionAndCount() {
        let progress = LearningProgress(completedLessonIDs: ["1", "2"])

        XCTAssertEqual(progress.completedCount(for: Fixtures.course), 2)
        XCTAssertEqual(progress.progress(for: Fixtures.course), 0.5)
        XCTAssertEqual(progress.percentComplete(for: Fixtures.course), 50)
    }

    func testPercentIsRounded() {
        let course = Course(
            id: "c",
            title: "T",
            description: "",
            instructor: "",
            lessons: [
                Lesson(id: "a", title: "A", durationMinutes: 1),
                Lesson(id: "b", title: "B", durationMinutes: 1),
                Lesson(id: "c", title: "C", durationMinutes: 1)
            ]
        )
        let progress = LearningProgress(completedLessonIDs: ["a"])

        XCTAssertEqual(progress.percentComplete(for: course), 33)
    }

    func testProgressIgnoresLessonsFromOtherCourses() {
        let progress = LearningProgress(completedLessonIDs: ["other-lesson"])

        XCTAssertEqual(progress.completedCount(for: Fixtures.course), 0)
        XCTAssertEqual(progress.progress(for: Fixtures.course), 0)
    }

    func testEmptyCourseHasZeroProgressAndIsNotFinished() {
        let empty = Course(id: "e", title: "E", description: "", instructor: "", lessons: [])
        let progress = LearningProgress()

        XCTAssertEqual(progress.progress(for: empty), 0)
        XCTAssertFalse(progress.isFinished(empty))
    }

    func testIsFinishedWhenEveryLessonIsCompleted() {
        let progress = LearningProgress(completedLessonIDs: ["1", "2", "3", "4"])

        XCTAssertTrue(progress.isFinished(Fixtures.course))
        XCTAssertNil(progress.nextLesson(in: Fixtures.course))
    }

    func testNextLessonIsFirstIncompleteLesson() {
        let progress = LearningProgress(completedLessonIDs: ["1", "3"])

        XCTAssertEqual(progress.nextLesson(in: Fixtures.course)?.id, "2")
    }

    func testCompletedCountAcrossCourses() {
        let progress = LearningProgress(completedLessonIDs: ["swift-1", "ui-1", "ui-2"])

        XCTAssertEqual(progress.completedCount(in: MockCourseData.courses), 3)
    }

    func testProgressCodableRoundTrip() throws {
        let progress = LearningProgress(completedLessonIDs: ["1", "2"])

        let data = try JSONEncoder().encode(progress)
        let decoded = try JSONDecoder().decode(LearningProgress.self, from: data)

        XCTAssertEqual(decoded, progress)
    }

    func testCourseTotalDuration() {
        XCTAssertEqual(Fixtures.course.totalDurationMinutes, 40)
    }
}
