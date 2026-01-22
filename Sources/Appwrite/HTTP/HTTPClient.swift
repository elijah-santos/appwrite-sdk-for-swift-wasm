import Foundation

public protocol HTTPClient {
    func execute(_ request: HTTPClientRequest, timeout: Duration) async throws -> HTTPClientResponse
}