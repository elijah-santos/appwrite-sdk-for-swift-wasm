import Foundation

public struct HTTPClientResponse {
    public var statusCode: Int
    public var headers: [(name: String, value: String)]
    public var body: Data

    public func headers(matching name: String) -> [String] {
        return headers
            .filter { $0.name == name }
            .map(\.value)
    }
}