import EventPrism
import SwiftUI

struct EventDetailView: View {
    var session: DemoSession
    var eventName: String

    @State private var customRows: [CustomParameterRow] = [CustomParameterRow()]

    private var title: String {
        session.events.first { $0.name == eventName }?.title ?? eventName
    }

    private var matchingRun: TrackRun? {
        guard let lastRun = session.lastRun, lastRun.input.name == eventName else {
            return nil
        }
        return lastRun
    }

    private var extras: [(key: String, value: String)] {
        customRows.map { (key: $0.key, value: $0.value) }
    }

    private var mergedProperties: [String: AnalyticsValue] {
        session.mergedSampleProperties(for: eventName, extras: extras)
    }

    var body: some View {
        List {
            Section {
                Text(
                    "Select dests to enable for this Track. They do not need to be registered on the dashboard first."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                destinationChips
            } header: {
                Text("Destinations")
            }

            Section("Custom parameters") {
                ForEach($customRows) { $row in
                    HStack(alignment: .center, spacing: 8) {
                        TextField("Key", text: $row.key)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        TextField("Value", text: $row.value)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button {
                            customRows.removeAll { $0.id == row.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove parameter")
                    }
                }
                Button("Add parameter") {
                    customRows.append(CustomParameterRow())
                }
            }

            Section("Properties") {
                if mergedProperties.isEmpty {
                    Text("No properties")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(mergedProperties.keys.sorted(), id: \.self) { key in
                        LabeledContent(key, value: AnalyticsValueDisplay.text(mergedProperties[key]!))
                    }
                }
            }

            Section {
                Button("Track event") {
                    Task {
                        await session.trackSelected(extras: extras)
                    }
                }
                .disabled(!session.canTrack)
            }

            TrackLogView(run: matchingRun)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            session.selectedEventName = eventName
        }
    }

    private var destinationChips: some View {
        HStack(spacing: 8) {
            ForEach(session.knownDestinationIDs, id: \.self) { id in
                let selected = session.destinations(for: eventName).contains(id)
                Button {
                    session.toggleEventDestination(id, for: eventName)
                } label: {
                    Text(id.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundStyle(selected ? Color.white : Color.secondary)
                        .background(
                            selected ? Color.accentColor : Color.secondary.opacity(0.18),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }
}

private struct CustomParameterRow: Identifiable {
    var id = UUID()
    var key = ""
    var value = ""
}
