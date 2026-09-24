enum EventTransformer {
    static func apply(
        properties: [String: AnalyticsValue],
        mapping: DestinationMapping,
        destination: DestinationID
    ) -> DestinationPayload {
        var parameters: [String: AnalyticsValue] = [:]
        parameters.reserveCapacity(properties.count)

        for (canonicalKey, original) in properties {
            let mapped = mapValue(original, key: canonicalKey, mapping: mapping, original: properties)
            let vendorKey = mapping.keys[canonicalKey] ?? canonicalKey
            parameters[vendorKey] = mapped
        }

        return DestinationPayload(
            destination: destination,
            name: mapping.text,
            parameters: parameters
        )
    }

    private static func mapValue(
        _ original: AnalyticsValue,
        key: String,
        mapping: DestinationMapping,
        original originalProperties: [String: AnalyticsValue]
    ) -> AnalyticsValue {
        let resolved: AnalyticsValue
        if let valueMap = mapping.values[key] {
            let lookup = original.stringified
            if let hit = valueMap.cases[lookup] {
                resolved = hit
            } else if let fallback = valueMap.defaultValue {
                resolved = fallback
            } else {
                resolved = original
            }
        } else {
            resolved = original
        }

        guard case .string(let template) = resolved else {
            return resolved
        }
        return .string(interpolate(template, original: originalProperties))
    }

    /// One pass: `${canonical_key}` from the original bag; missing key → empty string.
    static func interpolate(_ template: String, original: [String: AnalyticsValue]) -> String {
        var result = ""
        result.reserveCapacity(template.count)
        var index = template.startIndex

        while index < template.endIndex {
            if template[index] == "$" {
                let next = template.index(after: index)
                if next < template.endIndex, template[next] == "{" {
                    let keyStart = template.index(after: next)
                    if let close = template[keyStart...].firstIndex(of: "}") {
                        let key = String(template[keyStart..<close])
                        result += original[key]?.stringified ?? ""
                        index = template.index(after: close)
                        continue
                    }
                }
            }
            result.append(template[index])
            index = template.index(after: index)
        }

        return result
    }
}
