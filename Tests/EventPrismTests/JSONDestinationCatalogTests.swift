import Foundation
import Testing
@testable import EventPrism

@Suite("JSONDestinationCatalog")
struct JSONDestinationCatalogTests {
    @Test("firebase home interpolates independently of braze")
    func firebaseHomeFromFixture() throws {
        let catalog = try JSONDestinationCatalog(url: fixture("firebase.json"), strict: true)
        let mapping = try #require(catalog.mapping(for: "screen_viewed", destination: "firebase"))
        let payload = EventTransformer.apply(
            properties: [
                "page_name": .string("home"),
                "page_title": .string("Welcome"),
            ],
            mapping: mapping,
            destination: "firebase"
        )
        #expect(payload.name == "screen_view")
        #expect(payload.parameters["screen_name"] == .string("home page: Welcome"))
    }

    @Test("braze file is independent")
    func brazeIndependent() throws {
        let catalog = try JSONDestinationCatalog(url: fixture("braze.json"), strict: true)
        let mapping = try #require(catalog.mapping(for: "screen_viewed", destination: "braze"))
        let payload = EventTransformer.apply(
            properties: [
                "page_name": .string("home"),
                "page_title": .string("Welcome"),
            ],
            mapping: mapping,
            destination: "braze"
        )
        #expect(payload.name == "Screen Viewed")
        #expect(payload.parameters["page"] == .string("Home: Welcome"))
    }

    @Test("events false skips even if mappings row exists")
    func eventsFalse() throws {
        let catalog = try JSONDestinationCatalog(url: fixture("firebase.json"), strict: true)
        #expect(catalog.mapping(for: "promo_seen", destination: "firebase") == nil)
        #expect(catalog.mapping(for: "debug_only", destination: "firebase") == nil)
    }

    @Test("wrong dest id is nil")
    func wrongDestination() throws {
        let catalog = try JSONDestinationCatalog(url: fixture("firebase.json"), strict: true)
        #expect(catalog.mapping(for: "screen_viewed", destination: "braze") == nil)
    }

    @Test("composite unions dests")
    func composite() throws {
        let firebase = try JSONDestinationCatalog(url: fixture("firebase.json"), strict: true)
        let braze = try JSONDestinationCatalog(url: fixture("braze.json"), strict: true)
        let catalog = CompositeEventCatalog(firebase, braze)
        #expect(catalog.mapping(for: "screen_viewed", destination: "firebase") != nil)
        #expect(catalog.mapping(for: "screen_viewed", destination: "braze") != nil)
        #expect(catalog.mapping(for: "promo_seen", destination: "firebase") == nil)
        #expect(catalog.mapping(for: "promo_seen", destination: "braze")?.text == "promo_impression")
    }

    @Test("invalid JSON drop-all unless strict")
    func invalidJSON() throws {
        let data = Data("{not-json".utf8)
        let dropped = try JSONDestinationCatalog(data: data, strict: false)
        #expect(dropped.mapping(for: "screen_viewed", destination: "firebase") == nil)

        #expect(throws: JSONDestinationCatalogError.invalidJSON) {
            try JSONDestinationCatalog(data: data, strict: true)
        }
    }

    @Test("invalid schema drop-all unless strict")
    func invalidSchema() throws {
        let data = Data(#"{}"#.utf8)
        let dropped = try JSONDestinationCatalog(data: data, strict: false)
        #expect(dropped.id.rawValue == "")

        #expect(throws: JSONDestinationCatalogError.invalidSchema("missing id")) {
            try JSONDestinationCatalog(data: data, strict: true)
        }
    }
}

private func fixture(_ name: String) -> URL {
    url(name, subdirectory: "Fixtures", bundle: Bundle.module)
}

private func url(_ name: String, subdirectory: String, bundle: Bundle) -> URL {
    let stem = URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent
    let ext = URL(fileURLWithPath: name).pathExtension
    guard let found = bundle.url(forResource: stem, withExtension: ext, subdirectory: subdirectory)
        ?? bundle.url(forResource: stem, withExtension: ext)
    else {
        Issue.record("missing fixture \(name)")
        return URL(fileURLWithPath: "/missing/\(name)")
    }
    return found
}
