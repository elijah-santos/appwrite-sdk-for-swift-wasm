import Foundation

public struct HTTPClientRequest {
    public init(url: String) {
        self.url = url
    }

    public var url: String
    public var method: String = ""
    public var headers: [(name: String, value: String)] = []
    public var body: Data = Data()

    public mutating func addHeader(_ key: String, value: String) {
        self.headers.append((name: key, value: value))
    }

    public mutating func removeHeader(_ key: String) {
        self.headers.removeAll { $0.name == key }
    }

    public func headers(matching name: String) -> [String] {
        return headers
            .filter { $0.name == name }
            .map(\.value)
    }
}