import Foundation

struct Course: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
    let instructor: String
    let lessons: [Lesson]

    var totalDurationMinutes: Int {
        lessons.reduce(0) { $0 + $1.durationMinutes }
    }
}

struct Lesson: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let durationMinutes: Int
}
