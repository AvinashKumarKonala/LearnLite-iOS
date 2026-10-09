import Foundation

/// Where a piece of data came from, so the UI can be honest about freshness.
enum DataSource: Equatable {
    case remote
    case cache(savedAt: Date?)
}

struct Loaded<Value> {
    let value: Value
    let source: DataSource
}

extension Loaded: Equatable where Value: Equatable {}
