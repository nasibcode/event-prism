import Foundation
import Testing
@testable import EventPrism

@Suite("EventPrism")
struct EventPrismClientTests {
    @Test("dual dest screen_viewed")
    func dualDest() async throws {
        let prism = try makePrism()
        let firebase = RecordingDestination(id: "firebase")
        let braze = RecordingDestination(id: "braze")
        prism.register(firebase)
        prism.register(braze)
        await prism.waitUntilIdle()

        prism.track("screen_viewed", properties: [
            "page_name": .string("home"),
            "page_title": .string("Welcome"),
        ])

        let firebaseLogs = await firebase.waitUntilCount(1)
        let brazeLogs = await braze.waitUntilCount(1)
        #expect(firebaseLogs[0].name == "screen_view")
        #expect(firebaseLogs[0].parameters["screen_name"] == .string("home page: Welcome"))
        #expect(brazeLogs[0].name == "Screen Viewed")
        #expect(brazeLogs[0].parameters["page"] == .string("Home: Welcome"))
    }

    @Test("settings uses each dest default")
    func defaults() async throws {
        let prism = try makePrism()
        let firebase = RecordingDestination(id: "firebase")
        let braze = RecordingDestination(id: "braze")
        prism.register(firebase)
        prism.register(braze)
        await prism.waitUntilIdle()

        prism.track("screen_viewed", properties: ["page_name": .string("settings")])
        _ = await firebase.waitUntilCount(1)
        _ = await braze.waitUntilCount(1)
        #expect(firebase.payloads[0].parameters["screen_name"] == .string("other page"))
        #expect(braze.payloads[0].parameters["page"] == .string("Unknown screen"))
    }

    @Test("item_tapped extra keys pass through")
    func passThroughExtras() async throws {
        let prism = try makePrism()
        let firebase = RecordingDestination(id: "firebase")
        prism.register(firebase)
        await prism.waitUntilIdle()

        prism.track("item_tapped", properties: [
            "item_id": .string("sku-1"),
            "extra": .string("keep"),
        ])
        let logs = await firebase.waitUntilCount(1)
        #expect(logs[0].name == "select_item")
        #expect(logs[0].parameters["item_id"] == .string("sku-1"))
        #expect(logs[0].parameters["extra"] == .string("keep"))
    }

    @Test("unregistered dest is skipped")
    func skipUnregistered() async throws {
        let prism = try makePrism()
        let firebase = RecordingDestination(id: "firebase")
        prism.register(firebase)
        await prism.waitUntilIdle()

        prism.track("screen_viewed", properties: ["page_name": .string("home")])
        _ = await firebase.waitUntilCount(1)
        #expect(firebase.payloads.count == 1)
    }

    @Test("debug_only not delivered to firebase")
    func eventsSkip() async throws {
        let prism = try makePrism()
        let firebase = RecordingDestination(id: "firebase")
        let braze = RecordingDestination(id: "braze")
        prism.register(firebase)
        prism.register(braze)
        await prism.waitUntilIdle()

        prism.track("debug_only")
        await prism.waitUntilIdle()
        #expect(firebase.payloads.isEmpty)
        #expect(braze.payloads.isEmpty)
    }

    @Test("promo_seen braze only")
    func firebaseFalseBrazeTrue() async throws {
        let prism = try makePrism()
        let firebase = RecordingDestination(id: "firebase")
        let braze = RecordingDestination(id: "braze")
        prism.register(firebase)
        prism.register(braze)
        await prism.waitUntilIdle()

        prism.track("promo_seen", properties: ["id": .string("p1")])
        _ = await braze.waitUntilCount(1)
        await prism.waitUntilIdle()
        #expect(firebase.payloads.isEmpty)
        #expect(braze.payloads[0].name == "promo_impression")
    }

    @Test("unknown name zero logs")
    func unknownName() async throws {
        let prism = try makePrism()
        let firebase = RecordingDestination(id: "firebase")
        prism.register(firebase)
        await prism.waitUntilIdle()
        prism.track("not_a_real_event")
        await prism.waitUntilIdle()
        #expect(firebase.payloads.isEmpty)
    }

    @Test("unregister stops that dest")
    func unregister() async throws {
        let prism = try makePrism()
        let firebase = RecordingDestination(id: "firebase")
        let braze = RecordingDestination(id: "braze")
        prism.register(firebase)
        prism.register(braze)
        await prism.waitUntilIdle()
        prism.unregister("braze")
        await prism.waitUntilIdle()

        prism.track("screen_viewed", properties: ["page_name": .string("home")])
        _ = await firebase.waitUntilCount(1)
        await prism.waitUntilIdle()
        #expect(firebase.payloads.count == 1)
        #expect(braze.payloads.isEmpty)
    }

    @Test("concurrent track is serialized with no lost events")
    func concurrentTrack() async throws {
        let prism = try makePrism()
        let firebase = RecordingDestination(id: "firebase")
        prism.register(firebase)
        await prism.waitUntilIdle()

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<20 {
                group.addTask {
                    prism.track("item_tapped", properties: ["n": .int(index)])
                }
            }
        }
        let logs = await firebase.waitUntilCount(20)
        #expect(logs.count == 20)
        let numbers = Set(logs.compactMap { payload -> Int? in
            if case .int(let value) = payload.parameters["n"] { return value }
            return nil
        })
        #expect(numbers == Set(0..<20))
    }
}

private func makePrism() throws -> EventPrism {
    let firebase = try JSONDestinationCatalog(url: fixtureURL("firebase.json"), strict: true)
    let braze = try JSONDestinationCatalog(url: fixtureURL("braze.json"), strict: true)
    return EventPrism(catalog: CompositeEventCatalog(firebase, braze))
}

private func fixtureURL(_ name: String) -> URL {
    let stem = URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent
    let ext = URL(fileURLWithPath: name).pathExtension
    guard let found = Bundle.module.url(forResource: stem, withExtension: ext, subdirectory: "Fixtures")
        ?? Bundle.module.url(forResource: stem, withExtension: ext)
    else {
        Issue.record("missing fixture \(name)")
        return URL(fileURLWithPath: "/missing/\(name)")
    }
    return found
}
