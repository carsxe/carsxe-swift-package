import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Lightweight CarsXE client.
/// - API: https://api.carsxe.com
/// - Public HTTP methods are `async throws` and return `[String: Any]` (JSON) unless noted.
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
        items.append(URLQueryItem(name: "key", value: getApiKey()))
        items.append(URLQueryItem(name: "source", value: sourceName))
        comps.queryItems = items

        guard let url = comps.url else { throw CarsXEError.invalidURL }
        return url
    }

    // MARK: - Networking

    /// Perform a request with native async URLSession on Darwin, or an async
    /// continuation wrapper on Linux (`FoundationNetworking`).
    private func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        #if canImport(FoundationNetworking)
        try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data, let response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                }
            }
            task.resume()
        }
        #else
        try await session.data(for: request)
        #endif
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await self.data(for: request)
        } catch let error as CarsXEError {
            throw error
        } catch {
            throw CarsXEError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw CarsXEError.networkError(NSError(domain: "CarsXE", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }

        guard (200...299).contains(http.statusCode) else {
            throw CarsXEError.httpError(statusCode: http.statusCode, data: data)
        }

        return data
    }

    private func fetch(url: URL) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return try parseJSONObject(from: try await perform(request))
    }

    private func post(url: URL, jsonBody: [String: Any], headers: [String: String] = [:]) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for (k, v) in headers {
            request.setValue(v, forHTTPHeaderField: k)
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
        return try parseJSONObject(from: try await perform(request))
    }

    private func fetchText(url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let data = try await perform(request)
        return String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
    }

    // MARK: - JSON Parsing

    private func parseJSONObject(from data: Data) throws -> [String: Any] {
        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: [])
            if let dict = obj as? [String: Any] {
                return dict
            } else if let arr = obj as? [Any] {
                return ["data": arr]
            } else {
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
    public func specs(_ params: [String: String]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "specs", params: params)
        return try await fetch(url: url)
    }

    /// Get market value
    /// Required: vin
    /// Optional: state (US state code), mileage (numeric string), condition (excellent|clean|average|rough)
    public func marketValue(_ params: [String: String]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "v2/marketvalue", params: params)
        return try await fetch(url: url)
    }

    /// Get vehicle history
    /// Required: vin
    public func history(_ params: [String: String]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "history", params: params)
        return try await fetch(url: url)
    }

    /// Get vehicle recalls
    /// Required: vin
    public func recalls(_ params: [String: String]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/recalls", params: params)
        return try await fetch(url: url)
    }

    /// Decode international VIN
    /// Required: vin
    public func internationalVinDecoder(_ params: [String: String]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/international-vin-decoder", params: params)
        return try await fetch(url: url)
    }

    /// Decode license plate
    /// Required: plate, country
    /// Optional: state, district
    public func platedecoder(_ params: [String: String]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "v2/platedecoder", params: params)
        return try await fetch(url: url)
    }

    /// Get vehicle images
    /// Required: make, model
    public func images(_ params: [String: String]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "images", params: params)
        return try await fetch(url: url)
    }

    /// Decode OBD codes
    /// Required: code
    public func obdcodesdecoder(_ params: [String: String]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "obdcodesdecoder", params: params)
        return try await fetch(url: url)
    }

    /// Recognize license plate from image (POST)
    /// Required: imageUrl (string)
    public func plateImageRecognition(imageUrl: String) async throws -> [String: Any] {
        guard var comps = URLComponents(string: "\(getBaseUrl())/platerecognition") else {
            throw CarsXEError.invalidURL
        }
        comps.queryItems = [
            URLQueryItem(name: "key", value: getApiKey()),
            URLQueryItem(name: "source", value: sourceName)
        ]
        guard let url = comps.url else { throw CarsXEError.invalidURL }
        let body: [String: Any] = ["image": imageUrl]
        return try await post(url: url, jsonBody: body, headers: ["Content-Type": "application/json"])
    }

    /// Extract VIN from image using OCR (POST)
    /// Required: imageUrl (string)
    public func vinOcr(imageUrl: String) async throws -> [String: Any] {
        guard var comps = URLComponents(string: "\(getBaseUrl())/v1/vinocr") else {
            throw CarsXEError.invalidURL
        }
        comps.queryItems = [
            URLQueryItem(name: "key", value: getApiKey()),
            URLQueryItem(name: "source", value: sourceName)
        ]
        guard let url = comps.url else { throw CarsXEError.invalidURL }
        let body: [String: Any] = ["image": imageUrl]
        return try await post(url: url, jsonBody: body, headers: ["Content-Type": "application/json"])
    }

    /// Search by year, make, model
    /// Required: year, make, model
    public func yearMakeModel(_ params: [String: String]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/ymm", params: params)
        return try await fetch(url: url)
    }

    /// Get lien and theft information
    /// Required: vin
    public func lienAndTheft(_ params: [String: String]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/lien-theft", params: params)
        return try await fetch(url: url)
    }

    /// Get safety recall data by year, make, and model
    /// Required: year, make, model
    public func recallsYmm(_ params: [String: String]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/recalls-ymm", params: params)
        return try await fetch(url: url)
    }

    /// Submit a bulk recalls batch (POST)
    /// Required: at least one of vins, csv, csvUrl
    /// Optional: webhookUrl
    public func submitBulkRecallBatch(_ body: [String: Any]) async throws -> [String: Any] {
        guard var comps = URLComponents(string: "\(getBaseUrl())/v1/recalls-batch/submit") else {
            throw CarsXEError.invalidURL
        }
        comps.queryItems = [
            URLQueryItem(name: "key", value: getApiKey()),
            URLQueryItem(name: "source", value: sourceName)
        ]
        guard let url = comps.url else { throw CarsXEError.invalidURL }
        return try await post(url: url, jsonBody: body, headers: ["Content-Type": "application/json"])
    }

    /// Get bulk recalls batch status
    /// Required: batchId
    public func getBulkRecallBatchStatus(_ batchId: String) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/recalls-batch/status", params: ["batchId": batchId])
        return try await fetch(url: url)
    }

    /// Get bulk recalls batch results
    /// Required: batchId
    public func getBulkRecallBatchResults(_ batchId: String) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/recalls-batch/results", params: ["batchId": batchId])
        return try await fetch(url: url)
    }

    /// Build the CSV download URL for a bulk recalls batch (includes `key` and `source` query items).
    /// Does not perform I/O.
    /// Required: batchId
    public func getBulkRecallBatchDownloadUrl(_ batchId: String) throws -> String {
        let url = try buildURL(endpoint: "v1/recalls-batch/download", params: ["batchId": batchId])
        return url.absoluteString
    }

    /// Download bulk recalls batch results as CSV text
    /// Required: batchId
    public func downloadBulkRecallBatch(_ batchId: String) async throws -> String {
        let url = try buildURL(endpoint: "v1/recalls-batch/download", params: ["batchId": batchId])
        return try await fetchText(url: url)
    }

    /// Get year/make/model/variant option lists for cascading dropdowns
    /// Optional: dimension, year, make, model, trim
    public func ymmOptions(_ params: [String: String] = [:]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/ymm-options", params: params)
        return try await fetch(url: url)
    }

    /// Get registered owner(s) by VIN
    /// Required: vin
    /// Optional: include
    public func ownershipVin(_ params: [String: String]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/ownership/vin", params: params)
        return try await fetch(url: url)
    }

    /// Get contact details by person name and address
    /// Required: first_name, last_name, address, zip
    /// Optional: include
    public func ownershipPerson(_ params: [String: String]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/ownership/person", params: params)
        return try await fetch(url: url)
    }

    /// Get residents by street address
    /// Required: address, zip
    /// Optional: include, variant
    public func ownershipAddress(_ params: [String: String]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/ownership/address", params: params)
        return try await fetch(url: url)
    }

    /// Search people by ZIP code
    /// Required: zip
    /// Optional: gender, min_age, max_age, income, page, limit, include, variant
    public func ownershipZip(_ params: [String: String]) async throws -> [String: Any] {
        let url = try buildURL(endpoint: "v1/ownership/zip", params: params)
        return try await fetch(url: url)
    }
}
