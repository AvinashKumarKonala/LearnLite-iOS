import SwiftUI

struct ErrorRow: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)

            Button("Try Again", action: retry)
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}
