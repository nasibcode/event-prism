import Foundation
import Testing
@testable import EventPrism

@Suite("EventTransformer")
struct EventTransformerTests {
    @Test("home interpolates page_title; key rename")
    func interpolatesHomePageTitle() {
        let mapping = DestinationMapping(
            text: "screen_view",
            keys: ["page_name": "screen_name"],
            values: [
                "page_name": PropertyValueMap(
                    cases: ["home": .string("home page: ${page_title}")],
                    defaultValue: .string("other page")
                )
            ]
        )
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
        #expect(payload.parameters["page_title"] == .string("Welcome"))
        #expect(payload.parameters["page_name"] == nil)
    }

    @Test("missing case uses default")
    func usesDefault() {
        let mapping = DestinationMapping(
            text: "screen_view",
            keys: ["page_name": "screen_name"],
            values: [
                "page_name": PropertyValueMap(
                    cases: ["home": .string("home page: ${page_title}")],
                    defaultValue: .string("other page")
                )
            ]
        )
        let payload = EventTransformer.apply(
            properties: ["page_name": .string("settings")],
            mapping: mapping,
            destination: "firebase"
        )
        #expect(payload.parameters["screen_name"] == .string("other page"))
    }

    @Test("no values row keeps original; unmapped keys keep names")
    func passThrough() {
        let mapping = DestinationMapping(text: "begin_checkout")
        let payload = EventTransformer.apply(
            properties: [
                "currency": .string("USD"),
                "value": .double(9.99),
            ],
            mapping: mapping,
            destination: "firebase"
        )
        #expect(payload.name == "begin_checkout")
        #expect(payload.parameters["currency"] == .string("USD"))
        #expect(payload.parameters["value"] == .double(9.99))
    }

    @Test("missing interpolation key becomes empty")
    func missingInterpolationKey() {
        let mapping = DestinationMapping(
            text: "e",
            values: [
                "title": PropertyValueMap(cases: ["x": .string("hello ${missing} world")])
            ]
        )
        let payload = EventTransformer.apply(
            properties: ["title": .string("x")],
            mapping: mapping,
            destination: "print"
        )
        #expect(payload.parameters["title"] == .string("hello  world"))
    }

    @Test("non-string mapped values are not interpolated")
    func nonStringNotInterpolated() {
        let mapping = DestinationMapping(
            text: "e",
            values: [
                "count": PropertyValueMap(cases: ["1": .int(1)])
            ]
        )
        let payload = EventTransformer.apply(
            properties: ["count": .string("1")],
            mapping: mapping,
            destination: "print"
        )
        #expect(payload.parameters["count"] == .int(1))
    }

    @Test("no matching case and no default keeps original then interpolates if string")
    func originalWhenNoDefault() {
        let mapping = DestinationMapping(
            text: "e",
            values: [
                "name": PropertyValueMap(cases: ["only": .string("mapped")])
            ]
        )
        let payload = EventTransformer.apply(
            properties: ["name": .string("plain ${name}")],
            mapping: mapping,
            destination: "print"
        )
        #expect(payload.parameters["name"] == .string("plain plain ${name}"))
    }
}
