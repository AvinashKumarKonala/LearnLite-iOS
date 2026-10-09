import Foundation

enum MockCourseData {
    static let courses: [Course] = [
        Course(
            id: "ios-swift",
            title: "Swift Fundamentals",
            description: "Build a strong foundation in modern Swift, including types, protocols, error handling and concurrency.",
            instructor: "Apple Learning Team",
            lessons: [
                Lesson(id: "swift-1", title: "Swift Basics", durationMinutes: 12),
                Lesson(id: "swift-2", title: "Optionals & Collections", durationMinutes: 15),
                Lesson(id: "swift-3", title: "Protocols & Generics", durationMinutes: 18),
                Lesson(id: "swift-4", title: "Concurrency with async/await", durationMinutes: 20)
            ]
        ),
        Course(
            id: "swiftui",
            title: "SwiftUI Essentials",
            description: "Learn declarative UI, state management, navigation and reusable views with SwiftUI.",
            instructor: "iOS Academy",
            lessons: [
                Lesson(id: "ui-1", title: "Views & Modifiers", durationMinutes: 10),
                Lesson(id: "ui-2", title: "State & Data Flow", durationMinutes: 16),
                Lesson(id: "ui-3", title: "NavigationStack", durationMinutes: 14),
                Lesson(id: "ui-4", title: "Lists & Async Loading", durationMinutes: 17)
            ]
        ),
        Course(
            id: "architecture",
            title: "iOS Architecture",
            description: "Understand MVVM, repositories, dependency injection and testable application design.",
            instructor: "Mobile Engineering",
            lessons: [
                Lesson(id: "arch-1", title: "MVVM", durationMinutes: 13),
                Lesson(id: "arch-2", title: "Repository Pattern", durationMinutes: 15),
                Lesson(id: "arch-3", title: "Dependency Injection", durationMinutes: 12),
                Lesson(id: "arch-4", title: "Testing Architecture", durationMinutes: 18)
            ]
        )
    ]
}
