import SwiftUI

struct TrackLogView: View {
    var run: TrackRun?

    var body: some View {
        if let run {
            Section("Log") {
                ForEach(run.destinations) { trace in
                    DestinationJSONTagView(trace: trace)
                }
            }
        } else {
            Section("Log") {
                Text("Select dests above, then Track event.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DestinationJSONTagView: View {
    var trace: DestinationTrace

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(trace.id.rawValue)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .foregroundStyle(trace.wasEnabled ? Color.white : Color.secondary)
                .background(
                    trace.wasEnabled ? Color.accentColor : Color.secondary.opacity(0.18),
                    in: Capsule()
                )

            Text(trace.jsonDisplay)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
    }
}
