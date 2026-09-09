import XCTest
@testable import carsxe

final class CarsXETests: XCTestCase {
    func testDownloadUrlIncludesKeySourceAndBatchId() throws {
        let client = CarsXE(apiKey: "test-key")
        let url = try client.getBulkRecallBatchDownloadUrl("brb_test")
        XCTAssertTrue(url.contains("https://api.carsxe.com/v1/recalls-batch/download"))
        XCTAssertTrue(url.contains("batchId=brb_test"))
        XCTAssertTrue(url.contains("key=test-key"))
        XCTAssertTrue(url.contains("source=swift"))
    }

    func testHelpersDoNotPerformIO() {
        let client = CarsXE(apiKey: "test-key")
        XCTAssertEqual(client.getBaseUrl(), "https://api.carsxe.com")
        XCTAssertEqual(client.getApiKey(), "test-key")
    }
}
