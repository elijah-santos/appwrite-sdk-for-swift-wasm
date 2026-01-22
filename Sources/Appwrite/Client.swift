import Foundation
@_exported import AppwriteModels
@_exported import JSONCodable

let DASHDASH = "--".data(using: .ascii)!
let CRLF = "\r\n".data(using: .ascii)!

open class Client {

    // MARK: Properties
    public static var chunkSize = 5 * 1024 * 1024 // 5MB

    open var endPoint = "https://cloud.appwrite.io/v1"

    open var endPointRealtime: String? = nil

    open var headers: [String: String] = [
        "content-type": "application/json",
        "x-sdk-name": "Apple",
        "x-sdk-platform": "client",
        "x-sdk-language": "apple",
        "x-sdk-version": "13.5.0",
        "x-appwrite-response-format": "1.8.0"
    ]

    internal var config: [String: String] = [:]

    internal var selfSigned: Bool = false

    internal var http: any HTTPClient


    private static let boundaryChars = "abcdefghijklmnopqrstuvwxyz1234567890"

    private static let boundary = randomBoundary().data(using: .ascii)!

    // MARK: Methods

    public init(http: some HTTPClient) {
        self.http = http;
    }

    ///
    /// Set Project
    ///
    /// Your project ID
    ///
    /// @param String value
    ///
    /// @return Client
    ///
    open func setProject(_ value: String) -> Client {
        config["project"] = value
        _ = addHeader(key: "X-Appwrite-Project", value: value)
        return self
    }

    ///
    /// Set JWT
    ///
    /// Your secret JSON Web Token
    ///
    /// @param String value
    ///
    /// @return Client
    ///
    open func setJWT(_ value: String) -> Client {
        config["jwt"] = value
        _ = addHeader(key: "X-Appwrite-JWT", value: value)
        return self
    }

    ///
    /// Set Locale
    ///
    /// @param String value
    ///
    /// @return Client
    ///
    open func setLocale(_ value: String) -> Client {
        config["locale"] = value
        _ = addHeader(key: "X-Appwrite-Locale", value: value)
        return self
    }

    ///
    /// Set Session
    ///
    /// The user session to authenticate with
    ///
    /// @param String value
    ///
    /// @return Client
    ///
    open func setSession(_ value: String) -> Client {
        config["session"] = value
        _ = addHeader(key: "X-Appwrite-Session", value: value)
        return self
    }

    ///
    /// Set DevKey
    ///
    /// Your secret dev API key
    ///
    /// @param String value
    ///
    /// @return Client
    ///
    open func setDevKey(_ value: String) -> Client {
        config["devkey"] = value
        _ = addHeader(key: "X-Appwrite-Dev-Key", value: value)
        return self
    }

    ///
    /// Set endpoint
    ///
    /// @param String endPoint
    ///
    /// @return Client
    ///
    open func setEndpoint(_ endPoint: String) -> Client {
        if !endPoint.hasPrefix("http://") && !endPoint.hasPrefix("https://") {
            fatalError("Invalid endpoint URL: \(endPoint)")
        }

        self.endPoint = endPoint
        self.endPointRealtime = endPoint
            .replacingOccurrences(of: "http://", with: "ws://")
            .replacingOccurrences(of: "https://", with: "wss://")

        return self
    }

    ///
    /// Set realtime endpoint.
    ///
    /// @param String endPoint
    ///
    /// @return Client
    ///
    open func setEndpointRealtime(_ endPoint: String) -> Client {
        if !endPoint.hasPrefix("ws://") && !endPoint.hasPrefix("wss://") {
            fatalError("Invalid realtime endpoint URL: \(endPoint)")
        }

        self.endPointRealtime = endPoint
        return self
    }

    ///
    /// Add header
    ///
    /// @param String key
    /// @param String value
    ///
    /// @return Client
    ///
    open func addHeader(key: String, value: String) -> Client {
        self.headers[key] = value
        return self
    }

   ///
   /// Builds a query string from parameters
   ///
   /// @param Dictionary<String, Any?> params
   /// @param String prefix
   ///
   /// @return String
   ///
   open func parametersToQueryString(params: [String: Any?]) -> String {
       var output: String = ""

       func appendWhenNotLast(_ index: Int, ofTotal count: Int, outerIndex: Int? = nil, outerCount: Int? = nil) {
           if (index != count - 1 || (outerIndex != nil
               && outerCount != nil
               && index == count - 1
               && outerIndex! != outerCount! - 1)) {
               output += "&"
           }
       }

       for (parameterIndex, element) in params.enumerated() {
           switch element.value {
           case nil:
               break
           case is Array<Any?>:
               let list = element.value as! Array<Any?>
               for (nestedIndex, item) in list.enumerated() {
                   output += "\(element.key)[]=\(item!)"
                   appendWhenNotLast(nestedIndex, ofTotal: list.count, outerIndex: parameterIndex, outerCount: params.count)
               }
               appendWhenNotLast(parameterIndex, ofTotal: params.count)
           default:
               output += "\(element.key)=\(element.value!)"
               appendWhenNotLast(parameterIndex, ofTotal: params.count)
           }
       }

       return output.addingPercentEncoding(
           withAllowedCharacters: .urlHostAllowed
       )?.replacingOccurrences(of: "+", with: "%2B") ?? "" // since urlHostAllowed doesn't include +
   }

    ///
    /// Sends a "ping" request to Appwrite to verify connectivity.
    ///
    /// @return String
    /// @throws Exception
    ///
   open func ping() async throws -> String {
       let apiPath: String = "/ping"

       let apiHeaders: [String: String] = [
           "content-type": "application/json"
       ]

       return try await call(
           method: "GET",
           path: apiPath,
           headers: apiHeaders
       )
    }

    ///
    /// Make an API call
    ///
    /// @param String method
    /// @param String path
    /// @param Dictionary<String, Any?> params
    /// @param Dictionary<String, String> headers
    /// @return Response
    /// @throws Exception
    ///
    open func call<T>(
        method: String,
        path: String = "",
        headers: [String: String] = [:],
        params: [String: Any?] = [:],
        sink: ((Data) -> Void)? = nil,
        converter: ((Any) -> T)? = nil
    ) async throws -> T {
        let validParams = params.filter { $0.value != nil }

        let queryParameters = method == "GET" && !validParams.isEmpty
            ? "?" + parametersToQueryString(params: validParams)
            : ""

        var request = HTTPClientRequest(url: endPoint + path + queryParameters)
        request.method = method


        for (key, value) in self.headers.merging(headers, uniquingKeysWith: { $1 }) {
            request.addHeader(key, value: value)
        }

        request.addDomainCookies()

        if "GET" == method {
            return try await execute(request, converter: converter)
        }

        try buildBody(for: &request, with: validParams)

        return try await execute(request, withSink: sink, converter: converter)
    }

    private func buildBody(
        for request: inout HTTPClientRequest,
        with params: [String: Any?]
    ) throws {
        if request.headers(matching: "content-type")[0] == "multipart/form-data" {
            buildMultipart(&request, with: params, chunked: !request.headers(matching: "content-range").isEmpty)
        } else {
            try buildJSON(&request, with: params)
        }
    }

    private func execute<T>(
        _ request: HTTPClientRequest,
        withSink bufferSink: ((Data) -> Void)? = nil,
        converter: ((Any) -> T)? = nil
    ) async throws -> T {
        let response = try await http.execute(
            request,
            timeout: .seconds(30)
        )

        if let warning = response.headers(matching: "x-appwrite-warning").first {
            warning.split(separator: ";").forEach { warning in
                fputs("Warning: \(warning)\n", stderr)
            }
        }

        let data = response.body

        switch response.statusCode {
        case 0..<400:
            if response.headers(matching: "Set-Cookie").count > 0 {
                let domain = URL(string: request.url)!.host!
                let new = response.headers(matching: "Set-Cookie")

                UserDefaults.standard.set(new, forKey: domain)
            }
            switch T.self {
            case is Bool.Type:
                return true as! T
            case is String.Type:
                return (String(data: data, encoding: .utf8) ?? "") as! T
            case is Data.Type:
                return data as! T
            default:
                if data.count == 0 {
                    return true as! T
                }
                let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

                return converter?(dict!) ?? dict! as! T
            }
        default:
            var message = ""
            var type = ""
            var responseString = ""

            do {
                let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

                message = dict?["message"] as? String ?? response.statusCode.description
                type = dict?["type"] as? String ?? ""
                responseString = String(data: data, encoding: .utf8) ?? ""
            } catch {
                message =  String(data: data, encoding: .utf8)!
                responseString = message
            }

            throw AppwriteError(
                message: message,
                code: response.statusCode,
                type: type,
                response: responseString
            )
        }
    }

    func chunkedUpload<T>(
        path: String,
        headers: inout [String: String],
        params: inout [String: Any?],
        paramName: String,
        idParamName: String? = nil,
        converter: ((Any) -> T)? = nil,
        onProgress: ((UploadProgress) -> Void)? = nil
    ) async throws -> T {
        let input = params[paramName] as! InputFile

        switch(input.sourceType) {
        case "path":
            input.data = try! Data(contentsOf: URL(fileURLWithPath: input.path))
        case "data":
            // do nothing
            break
        default:
            fatalError("Unrecognized case for InputFile type \(input.sourceType)")
        }

        let size = (input.data as! Data).count

        if size < Client.chunkSize {
            params[paramName] = input
            return try await call(
                method: "POST",
                path: path,
                headers: headers,
                params: params,
                converter: converter
            )
        }

        var offset = 0
        var result = [String:Any]()

        if idParamName != nil {
            // Make a request to check if a file already exists
            do {
                let map = try await call(
                    method: "GET",
                    path: path + "/" + (params[idParamName!] as! String),
                    headers: headers,
                    params: [:],
                    converter: { return $0 as! [String: Any] }
                )
                let chunksUploaded = map["chunksUploaded"] as! Int
                offset = chunksUploaded * Client.chunkSize
            } catch {
                // File does not exist yet, swallow exception
            }
        }

        while offset < size {
            let slice = (input.data as! Data)[offset..<min(offset + Client.chunkSize, size - offset)]

            params[paramName] = InputFile.fromData(slice, filename: input.filename, mimeType: input.mimeType)
            headers["content-range"] = "bytes \(offset)-\(min((offset + Client.chunkSize) - 1, size - 1))/\(size)"

            result = try await call(
                method: "POST",
                path: path,
                headers: headers,
                params: params,
                converter: { return $0 as! [String: Any] }
            )

            offset += Client.chunkSize
            headers["x-appwrite-id"] = result["$id"] as? String
            onProgress?(UploadProgress(
                id: result["$id"] as? String ?? "",
                progress: Double(min(offset, size))/Double(size) * 100.0,
                sizeUploaded: min(offset, size),
                chunksTotal: result["chunksTotal"] as? Int ?? -1,
                chunksUploaded: result["chunksUploaded"] as? Int ?? -1
            ))
        }

        return converter!(result)
    }

    private static func randomBoundary() -> String {
        var string = ""
        for _ in 0..<16 {
            string.append(Client.boundaryChars.randomElement()!)
        }
        return string
    }

    private func buildJSON(
        _ request: inout HTTPClientRequest,
        with params: [String: Any?] = [:]
    ) throws {
        var encodedParams = [String:Any]()

        for (key, param) in params {
            if param is String
                || param is Int
                || param is Float
                || param is Double
                || param is Bool
                || param is [String]
                || param is [Int]
                || param is [Float]
                || param is [Double]
                || param is [Bool]
                || param is [String: Any]
                || param is [Int: Any]
                || param is [Float: Any]
                || param is [Double: Any]
                || param is [Bool: Any] {
                encodedParams[key] = param
            } else if let encodable = param as? Encodable {
                encodedParams[key] = try encodable.toJson()
            } else if let param = param {
                encodedParams[key] = String(describing: param)
            }
        }

        let json = try JSONSerialization.data(withJSONObject: encodedParams, options: [])

        request.body = json
    }

    private func buildMultipart(
        _ request: inout HTTPClientRequest,
        with params: [String: Any?] = [:],
        chunked: Bool = false
    ) {
        func addPart(name: String, value: Any) {
            bodyBuffer += DASHDASH
            bodyBuffer += Client.boundary
            bodyBuffer += CRLF
            bodyBuffer += "Content-Disposition: form-data; name=\"\(name)\"".data(using: .utf8)!

            if let file = value as? InputFile {
                bodyBuffer += "; filename=\"\(file.filename)\"".data(using: .utf8)!
                bodyBuffer += CRLF
                bodyBuffer += "Content-Length: \(bodyBuffer.count)".data(using: .utf8)!
                bodyBuffer += CRLF + CRLF

                let buffer = file.data! as! Data

                bodyBuffer += buffer
                bodyBuffer += CRLF
                return
            }

            let string = String(describing: value)
            bodyBuffer += CRLF
            bodyBuffer += "Content-Length: \(string.count)".data(using: .utf8)!
            bodyBuffer += CRLF + CRLF
            bodyBuffer += string.data(using: .utf8)!
            bodyBuffer += CRLF
        }

        var bodyBuffer = Data()

        for (key, value) in params {
            switch key {
            case "file":
                addPart(name: key, value: value!)
            default:
                if let list = value as? [Any] {
                    for listValue in list {
                        addPart(name: "\(key)[]", value: listValue)
                    }
                    continue
                }
                addPart(name: key, value: value!)
            }
        }

        bodyBuffer += DASHDASH
        bodyBuffer += Client.boundary
        bodyBuffer += DASHDASH
        bodyBuffer += CRLF

        request.removeHeader("content-type")
        if !chunked {
            request.addHeader("Content-Length", value: bodyBuffer.count.description)
        }
        request.addHeader("Content-Type", value: "multipart/form-data;boundary=\"\(Client.boundary)\"")
        request.body = bodyBuffer
    }
}