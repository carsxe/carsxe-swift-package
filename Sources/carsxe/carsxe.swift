import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Lightweight CarsXE client (Swift version of the Java template).
/// - API: https://api.carsxe.com
/// - Public methods are synchronous and throw on error, returning `[String: Any]`.
public final class CarsXE {
    private let apiKey: String
    private let sourceName = "swift"
    private let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: - Public helpers

    public func getBaseUrl() -> String { "https://api.carsxe.com" }
    public func getApiKey() -> String { apiKey }

    // MARK: - Errors

    public enum CarsXEError: Error, CustomStringConvertible {
        case invalidURL
        case networkError(Error)
        case httpError(statusCode: Int, data: Data?)
        case jsonDecodingError(Error)
        case missingRequiredParameter(String)

        public var description: String {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .networkError(let e): return "Network error: \(e)"
            case .httpError(let code, _): return "HTTP error: status code \(code)"
            case .jsonDecodingError(let e): return "JSON decoding error: \(e)"
            case .missingRequiredParameter(let param): return "Missing required parameter: \(param)"
            }
        }
    }

    // MARK: - URL Building

    private func buildURL(endpoint: String, params: [String: String]) throws -> URL {
        guard var comps = URLComponents(string: "\(getBaseUrl())/\(endpoint)") else {
            throw CarsXEError.invalidURL
        }

        var items: [URLQueryItem] = []
        for (k, v) in params {
            items.append(URLQueryItem(name: k, value: v))
        }
        // always include key and source
        items.append(URLQueryItem(name: "key", value: getApiKey()))
        items.append(URLQueryItem(name: "source", value: sourceName))
        comps.queryItems = items

        guard let url = comps.url else { throw CarsXEError.invalidURL }
        return url
    }

    // MARK: - Networking (synchronous wrappers)

    /// Synchronously perform a GET request and return JSON as [String: Any].
    private func fetch(url: URL) throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response, error) = synchronousDataTask(with: request)

        if let err = error {
            throw CarsXEError.networkError(err)
        }

        guard let http = response as? HTTPURLResponse else {
            throw CarsXEError.networkError(NSError(domain: "CarsXE", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }

        guard (200...299).contains(http.statusCode) else {
            throw CarsXEError.httpError(statusCode: http.statusCode, data: data)
        }

        guard let data = data else {
            return [:]
        }

        return try parseJSONObject(from: data)
    }

    /// Synchronously perform a POST with JSON body and return JSON as [String: Any].
    private func post(url: URL, jsonBody: [String: Any], headers: [String: String] = [:]) throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for (k, v) in headers {
            request.setValue(v, forHTTPHeaderField: k)
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])

        let (data, response, error) = synchronousDataTask(with: request)

        if let err = error {
            throw CarsXEError.networkError(err)
        }

        guard let http = response as? HTTPURLResponse else {
            throw CarsXEError.networkError(NSError(domain: "CarsXE", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }

        guard (200...299).contains(http.statusCode) else {
            throw CarsXEError.httpError(statusCode: http.statusCode, data: data)
        }

        guard let data = data else {
            return [:]
        }

        return try parseJSONObject(from: data)
    }

    /// Helper to synchronously run a URLSession dataTask.
    /// Uses reference-type holders to avoid mutating captured local variables in the closure
    /// (fixes Swift 6 "mutation of captured var in concurrently-executing code" diagnostics).
    /// Returns (Data?, URLResponse?, Error?)
    private func synchronousDataTask(with request: URLRequest) -> (Data?, URLResponse?, Error?) {
        // Reference-type holders — mutation of properties is allowed even in Swift 6 concurrency mode.
        final class Box<T> { var value: T?; init(_ v: T? = nil) { value = v } }

        let sem = DispatchSemaphore(value: 0)
        let responseDataBox = Box<Data>()            // Box<Data>.value is Data? (single optional)
        let responseBox = Box<URLResponse>()        // Box<URLResponse>.value is URLResponse?
        let errorBox = Box<Error>()                 // Box<Error>.value is Error?

        let task = session.dataTask(with: request) { data, response, error in
            responseDataBox.value = data
            responseBox.value = response
            errorBox.value = error
            sem.signal()
        }
        task.resume()

        // Wait (caller must avoid using on main thread for UI apps)
        _ = sem.wait(timeout: .distantFuture)

        return (responseDataBox.value, responseBox.value, errorBox.value)
    }

    // MARK: - JSON Parsing

    private func parseJSONObject(from data: Data) throws -> [String: Any] {
        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: [])
            if let dict = obj as? [String: Any] {
                return dict
            } else if let arr = obj as? [Any] {
                // Wrap arrays in an object with "data" key for consistent access
                return ["data": arr]
            } else {
                // Wrap scalars in an object with "value" key
                return ["value": obj]
            }
        } catch {
            throw CarsXEError.jsonDecodingError(error)
        }
    }

    // MARK: - Public API Methods

    /// Get vehicle specifications
    /// Required: vin
    /// Optional: deepdata, disableIntVINDecoding
    public func specs(_ params: [String: String]) throws -> [String: Any] {
        let url = try buildURL(endpoint: "specs", params: params)
        return try fetch(url: url)
    }

    /// Get market value
    /// Required: vin
    /// Optional: state
    public func marketValue(_ params: [String: String]) throws -> [String: Any] {
        let url = try buildURL(endpoint: "v2/marketvalue", params: params)
        return try fetch(url: url)
    }

    /// Get vehicle history
    /// Required: vin
    public func history(_ params: [String: String]) throws -> [String: Any] {
        let url = try buildURL(endpoint: "history", params: params)
        return try fetch(url: url)
    }

    /// Get vehicle recalls
    /// Required: vin
    public func recalls(_ params: [String: String]) throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/recalls", params: params)
        return try fetch(url: url)
    }

    /// Decode international VIN
    /// Required: vin
    public func internationalVinDecoder(_ params: [String: String]) throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/international-vin-decoder", params: params)
        return try fetch(url: url)
    }

    /// Decode license plate
    /// Required: plate, country
    /// Optional: state, district
    public func platedecoder(_ params: [String: String]) throws -> [String: Any] {
        let url = try buildURL(endpoint: "v2/platedecoder", params: params)
        return try fetch(url: url)
    }

    /// Get vehicle images
    /// Required: make, model
    public func images(_ params: [String: String]) throws -> [String: Any] {
        let url = try buildURL(endpoint: "images", params: params)
        return try fetch(url: url)
    }

    /// Decode OBD codes
    /// Required: code
    public func obdcodesdecoder(_ params: [String: String]) throws -> [String: Any] {
        let url = try buildURL(endpoint: "obdcodesdecoder", params: params)
        return try fetch(url: url)
    }

    /// Recognize license plate from image (POST)
    /// Required: imageUrl (string)
    public func plateImageRecognition(imageUrl: String) throws -> [String: Any] {
        guard var comps = URLComponents(string: "\(getBaseUrl())/platerecognition") else {
            throw CarsXEError.invalidURL
        }
        comps.queryItems = [
            URLQueryItem(name: "key", value: getApiKey()),
            URLQueryItem(name: "source", value: sourceName)
        ]
        guard let url = comps.url else { throw CarsXEError.invalidURL }
        let body: [String: Any] = ["image": imageUrl]
        return try post(url: url, jsonBody: body, headers: ["Content-Type": "application/json"])
    }

    /// Extract VIN from image using OCR (POST)
    /// Required: imageUrl (string)
    public func vinOcr(imageUrl: String) throws -> [String: Any] {
        guard var comps = URLComponents(string: "\(getBaseUrl())/v1/vinocr") else {
            throw CarsXEError.invalidURL
        }
        comps.queryItems = [
            URLQueryItem(name: "key", value: getApiKey()),
            URLQueryItem(name: "source", value: sourceName)
        ]
        guard let url = comps.url else { throw CarsXEError.invalidURL }
        let body: [String: Any] = ["image": imageUrl]
        return try post(url: url, jsonBody: body, headers: ["Content-Type": "application/json"])
    }

    /// Search by year, make, model
    /// Required: year, make, model
    public func yearMakeModel(_ params: [String: String]) throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/ymm", params: params)
        return try fetch(url: url)
    }

    /// Get lien and theft information
    /// Required: vin
    public func lienAndTheft(_ params: [String: String]) throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/lien-theft", params: params)
        return try fetch(url: url)
    }
}