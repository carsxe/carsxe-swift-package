import Foundation
import FoundationNetworking

/// Lightweight CarsXE client where every endpoint accepts params as [String: String].
/// Returns [String: Any] objects representing JSON responses directly.
public final class CarsXE {
    private let apiKey: String
    private let session: URLSession
    private let sourceName = "swift"

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func getApiKey() -> String { apiKey }
    public func getApiBaseUrl() -> String { "https://api.carsxe.com" }

    // MARK: - Parameter Validation

    /// Validates parameters against endpoint requirements
    /// Throws CarsXEError.missingRequiredParameter if any required param is missing or empty
    private func validateParams(_ params: [String: String], for endpoint: EndpointParams) throws {
        for requiredParam in endpoint.required {
            let value = params[requiredParam]?.trimmingCharacters(in: .whitespacesAndNewlines)
            if value?.isEmpty != false {
                throw CarsXEError.missingRequiredParameter(requiredParam)
            }
        }
    }

    /// Special validation for plate decoder with country-specific logic
    private func validatePlateDecoderParams(_ params: [String: String]) throws {
        // First validate basic required params
        try validateParams(params, for: APIEndpoints.plateDecoder)
        
        let country = (params["country"] ?? "US").trimmingCharacters(in: .whitespacesAndNewlines)
        let countryLower = country.lowercased()
        
        // Special case for Pakistan: require both state and district
        if countryLower == "pk" || countryLower == "pakistan" {
            let state = params["state"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            let district = params["district"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if state?.isEmpty != false {
                throw CarsXEError.missingRequiredParameter("state (required for Pakistan)")
            }
            if district?.isEmpty != false {
                throw CarsXEError.missingRequiredParameter("district (required for Pakistan)")
            }
        } else {
            // For other countries, only state is required
            let state = params["state"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            if state?.isEmpty != false {
                throw CarsXEError.missingRequiredParameter("state")
            }
        }
    }

    /// Special validation for image upload endpoints
    private func validateImageUploadParams(_ params: [String: String]) throws {
        // Check for upload_url, image, or imageUrl keys
        let uploadUrl = params["upload_url"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let image = params["image"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageUrl = params["imageUrl"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if uploadUrl?.isEmpty != false && image?.isEmpty != false && imageUrl?.isEmpty != false {
            throw CarsXEError.missingRequiredParameter("upload_url (or image/imageUrl)")
        }
    }

    // MARK: - URL Building and Network Helpers

    private func buildURL(endpoint: String, params: [String: String]) throws -> URL {
        guard var comps = URLComponents(string: "\(getApiBaseUrl())/\(endpoint)") else {
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

    /// Parse JSON response data into [String: Any] object
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

    private func performGET(url: URL) async throws -> [String: Any] {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                throw CarsXEError.networkError(NSError(domain: "CarsXE", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            }
            guard (200...299).contains(http.statusCode) else {
                throw CarsXEError.httpError(statusCode: http.statusCode, data: data)
            }
            return try parseJSONObject(from: data)
        } catch let err as CarsXEError {
            throw err
        } catch {
            throw CarsXEError.networkError(error)
        }
    }

    private func performPOST(url: URL, jsonBody: [String: Any]) async throws -> [String: Any] {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                throw CarsXEError.networkError(NSError(domain: "CarsXE", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            }
            guard (200...299).contains(http.statusCode) else {
                throw CarsXEError.httpError(statusCode: http.statusCode, data: data)
            }
            return try parseJSONObject(from: data)
        } catch let err as CarsXEError {
            throw err
        } catch {
            throw CarsXEError.networkError(error)
        }
    }

    // MARK: - Public API Methods (now return [String: Any])

    /// Get vehicle specifications
    /// Required: vin
    /// Optional: deepdata, disableIntVINDecoding
    public func specs(_ params: [String: String]) async throws -> [String: Any] {
        try validateParams(params, for: APIEndpoints.specs)
        let url = try buildURL(endpoint: "specs", params: params)
        return try await performGET(url: url)
    }

    /// Get market value
    /// Required: vin
    /// Optional: state
    public func marketValue(_ params: [String: String]) async throws -> [String: Any] {
        try validateParams(params, for: APIEndpoints.marketValue)
        let url = try buildURL(endpoint: "v2/marketvalue", params: params)
        return try await performGET(url: url)
    }

    /// Get vehicle history
    /// Required: vin
    public func history(_ params: [String: String]) async throws -> [String: Any] {
        try validateParams(params, for: APIEndpoints.history)
        let url = try buildURL(endpoint: "history", params: params)
        return try await performGET(url: url)
    }

    /// Get vehicle recalls
    /// Required: vin
    public func recalls(_ params: [String: String]) async throws -> [String: Any] {
        try validateParams(params, for: APIEndpoints.recalls)
        let url = try buildURL(endpoint: "v1/recalls", params: params)
        return try await performGET(url: url)
    }

    /// Decode international VIN
    /// Required: vin
    public func internationalVinDecoder(_ params: [String: String]) async throws -> [String: Any] {
        try validateParams(params, for: APIEndpoints.internationalVinDecoder)
        let url = try buildURL(endpoint: "v1/international-vin-decoder", params: params)
        return try await performGET(url: url)
    }

    /// Decode license plate
    /// Required: plate, country
    /// Optional: state, district
    /// Special logic: For Pakistan (PK), both state and district are required
    public func platedecoder(_ params: [String: String]) async throws -> [String: Any] {
        var effective = params
        
        // Set default country if missing or empty
        let country = (effective["country"]?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "US"
        effective["country"] = country
        
        try validatePlateDecoderParams(effective)
        
        let url = try buildURL(endpoint: "v2/platedecoder", params: effective)
        return try await performGET(url: url)
    }

    /// Get vehicle images
    /// Required: make, model
    /// Optional: year, trim, color, transparent, angle, photoType, size, license
    public func images(_ params: [String: String]) async throws -> [String: Any] {
        try validateParams(params, for: APIEndpoints.images)
        let url = try buildURL(endpoint: "images", params: params)
        return try await performGET(url: url)
    }

    /// Decode OBD codes
    /// Required: code
    public func obdCodesDecoder(_ params: [String: String]) async throws -> [String: Any] {
        try validateParams(params, for: APIEndpoints.obdcodesDecoder)
        let url = try buildURL(endpoint: "obdcodesdecoder", params: params)
        return try await performGET(url: url)
    }

    /// Recognize license plate from image
    /// Required: upload_url (or image/imageUrl)
    public func plateImageRecognition(_ params: [String: String]) async throws -> [String: Any] {
        try validateImageUploadParams(params)
        
        let upload = params["upload_url"] ?? params["image"] ?? params["imageUrl"] ?? ""
        
        guard var comps = URLComponents(string: "\(getApiBaseUrl())/platerecognition") else { 
            throw CarsXEError.invalidURL 
        }
        comps.queryItems = [
            URLQueryItem(name: "key", value: getApiKey()),
            URLQueryItem(name: "source", value: sourceName)
        ]
        guard let url = comps.url else { throw CarsXEError.invalidURL }
        let body: [String: Any] = ["image": upload]
        return try await performPOST(url: url, jsonBody: body)
    }

    /// Extract VIN from image using OCR
    /// Required: upload_url (or image/imageUrl)
    public func vinOcr(_ params: [String: String]) async throws -> [String: Any] {
        try validateImageUploadParams(params)
        
        let upload = params["upload_url"] ?? params["image"] ?? params["imageUrl"] ?? ""
        
        guard var comps = URLComponents(string: "\(getApiBaseUrl())/v1/vinocr") else { 
            throw CarsXEError.invalidURL 
        }
        comps.queryItems = [
            URLQueryItem(name: "key", value: getApiKey()),
            URLQueryItem(name: "source", value: sourceName)
        ]
        guard let url = comps.url else { throw CarsXEError.invalidURL }
        let body: [String: Any] = ["image": upload]
        return try await performPOST(url: url, jsonBody: body)
    }

    /// Search by year, make, model
    /// Required: year, make, model
    /// Optional: trim
    public func yearMakeModel(_ params: [String: String]) async throws -> [String: Any] {
        try validateParams(params, for: APIEndpoints.yearMakeModel)
        let url = try buildURL(endpoint: "v1/ymm", params: params)
        return try await performGET(url: url)
    }
}