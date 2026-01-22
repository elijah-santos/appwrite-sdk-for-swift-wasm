import Foundation
extension HTTPClientRequest {
    public mutating func addDomainCookies() {
        guard let cookies = UserDefaults.standard.stringArray(forKey: URL(string: url)!.host!) else {
            return
        }
        for cookie in cookies {
            addHeader("Cookie", value: cookie)
        }
    }
}