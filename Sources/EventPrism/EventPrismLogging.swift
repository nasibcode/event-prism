/// Debug logging. Messages include destination id and event name only — never property values.
public struct EventPrismLogging: Sendable {
    public typealias Handler = @Sendable (_ destination: DestinationID?, _ eventName: String?, _ message: String) -> Void

    public static let `default` = EventPrismLogging { _, _, _ in }

    private let handler: Handler

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    public func log(destination: DestinationID? = nil, eventName: String? = nil, message: String) {
        handler(destination, eventName, message)
    }
}
