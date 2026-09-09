import Foundation

/// Errors for the CarsXE client
public enum CarsXEError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case httpError(statusCode: Int, data: Data?)
    case jsonDecodingError(Error)
    case missingRequiredParameter(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        case .httpError(let code, _):
            return "HTTP error: \(code)"
        case .jsonDecodingError(let err):
            return "JSON decoding error: \(err.localizedDescription)"
        case .missingRequiredParameter(let name):
            return "Missing required parameter: \(name)"
        }
    }
}

/// Parameter definitions for each endpoint
public struct EndpointParams {
    public let required: [String]
    public let optional: [String]
    
    public init(required: [String], optional: [String] = []) {
        self.required = required
        self.optional = optional
    }
}

/// All endpoint parameter definitions
public struct APIEndpoints {
    public static let specs = EndpointParams(
        required: ["vin"],
        optional: ["deepdata", "disableIntVINDecoding"]
    )
    
    public static let marketValue = EndpointParams(
        required: ["vin"],
        optional: ["state"]
    )
    
    public static let history = EndpointParams(
        required: ["vin"]
    )
    
    public static let recalls = EndpointParams(
        required: ["vin"]
    )
    
    public static let internationalVinDecoder = EndpointParams(
        required: ["vin"]
    )
    
    public static let plateDecoder = EndpointParams(
        required: ["plate", "country"],
        optional: ["state", "district"]
    )
    
    public static let images = EndpointParams(
        required: ["make", "model"],
        optional: ["year", "trim", "color", "transparent", "angle", "photoType", "size", "license"]
    )
    
    public static let obdcodesDecoder = EndpointParams(
        required: ["code"]
    )
    
    public static let plateImageRecognition = EndpointParams(
        required: ["upload_url"]
    )
    
    public static let vinOcr = EndpointParams(
        required: ["upload_url"]
    )
    
    public static let yearMakeModel = EndpointParams(
        required: ["year", "make", "model"],
        optional: ["trim"]
    )

    public static let lienAndTheft = EndpointParams(
        required: ["vin"]
    )

    public static let recallsYmm = EndpointParams(
        required: ["year", "make", "model"]
    )

    /// At least one of vins, csv, or csvUrl is required.
    public static let submitBulkRecallBatch = EndpointParams(
        required: [],
        optional: ["vins", "csv", "csvUrl", "webhookUrl"]
    )

    public static let getBulkRecallBatchStatus = EndpointParams(
        required: ["batchId"]
    )

    public static let getBulkRecallBatchResults = EndpointParams(
        required: ["batchId"]
    )

    public static let downloadBulkRecallBatch = EndpointParams(
        required: ["batchId"]
    )

    public static let ymmOptions = EndpointParams(
        required: [],
        optional: ["dimension", "year", "make", "model", "trim"]
    )

    public static let ownershipVin = EndpointParams(
        required: ["vin"],
        optional: ["include"]
    )

    public static let ownershipPerson = EndpointParams(
        required: ["first_name", "last_name", "address", "zip"],
        optional: ["include"]
    )

    public static let ownershipAddress = EndpointParams(
        required: ["address", "zip"],
        optional: ["include", "variant"]
    )

    public static let ownershipZip = EndpointParams(
        required: ["zip"],
        optional: ["gender", "min_age", "max_age", "income", "page", "limit", "include", "variant"]
    )
}