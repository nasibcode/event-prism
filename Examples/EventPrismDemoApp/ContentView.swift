import SwiftUI

struct ContentView: View {
    var session: DemoSession
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let loadError = session.loadError {
                    ContentUnavailableView(
                        "Catalogs failed to load",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else {
                    dashboard
                }
            }
            .navigationTitle("EventPrism Demo")
            .navigationDestination(for: String.self) { name in
                EventDetailView(session: session, eventName: name)
            }
        }
    }

    private var dashboard: some View {
        List {
            Section {
                Text(
                    "Browse events and open detail to choose destinations and Track. Destination chips here register or unregister adapters. Catalog JSON still owns mappings and events."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Destinations") {
                destinationChips
            }

            Section("Events") {
                ForEach(session.events) { event in
                    eventRow(event)
                }
            }
        }
    }

    private var destinationChips: some View {
        HStack(spacing: 8) {
            ForEach(session.knownDestinationIDs, id: \.self) { id in
                Button {
                    Task { await session.toggleDestination(id) }
                } label: {
                    Text(id.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundStyle(session.isRegistered(id) ? Color.white : Color.secondary)
                        .background(
                            session.isRegistered(id) ? Color.accentColor : Color.secondary.opacity(0.18),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .disabled(!session.isReady || session.isRunning)
                .accessibilityAddTraits(session.isRegistered(id) ? .isSelected : [])
            }
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }

    private func eventRow(_ event: DemoSession.CatalogEvent) -> some View {
        NavigationLink(value: event.name) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .foregroundStyle(.primary)
                Text("track(\"\(event.name)\")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
