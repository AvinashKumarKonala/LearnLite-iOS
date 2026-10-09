import SwiftUI

/// Shown whenever the screen is displaying saved (cached) data instead of fresh data.
struct DataSourceBanner: View {
    let source: DataSource

    private static let formatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    var body: some View {
        if case .cache(let savedAt) = source {
            Label(message(savedAt: savedAt), systemImage: "wifi.slash")
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .padding(.horizontal)
                .background(Color.orange.opacity(0.15))
                .accessibilityElement(children: .combine)
        }
    }

    private func message(savedAt: Date?) -> String {
        guard let savedAt else { return "Showing saved data" }
        let relative = Self.formatter.localizedString(for: savedAt, relativeTo: Date())
        return "Showing saved data · updated \(relative)"
    }
}
