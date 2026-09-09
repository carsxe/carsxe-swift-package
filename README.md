# 🚗 CarsXE API (Swift Package)

[![Swift Version](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg)](https://github.com/carsxe/carsxe-swift-package)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**CarsXE** is a powerful and developer-friendly API that gives you instant access to a wide range of vehicle data. From VIN decoding and market value estimation to vehicle history, images, OBD code explanations, and plate recognition, CarsXE provides everything you need to build automotive applications at scale.

🌐 **Website:** [https://api.carsxe.com](https://api.carsxe.com)  
📄 **Docs:** [https://api.carsxe.com/docs](https://api.carsxe.com/docs)  
📦 **All Products:** [https://api.carsxe.com/all-products](https://api.carsxe.com/all-products)

To get started with the CarsXE API (Swift package), follow these steps:

1. **Sign up for a CarsXE account:**
   - [Register here](https://api.carsxe.com/register)
   - Add a [payment method](https://api.carsxe.com/dashboard/billing#payment-methods) to activate your subscription and get your API key.

2. **Add the CarsXE Swift Package to Your Project:**

   Add this package to your `Package.swift` dependencies:

   ```swift
   dependencies: [
       .package(url: "https://github.com/carsxe/carsxe-swift-package.git", branch: "main")
   ]
   ```

   When adding the package to your target, include the `carsxe` product in the target dependencies:

   ```swift
   targets: [
       .executableTarget(
           name: "swiftTest",
           dependencies: [
               .product(name: "carsxe", package: "carsxe-swift-package")
           ]
       )
   ]
   ```

   Or add it through Xcode: **File → Add Package Dependencies...** and enter: `https://github.com/carsxe/carsxe-swift-package.git`

3. **Import the CarsXE package into your code:**

   ```swift
   import carsxe
   ```

4. **Initialize the API with your API key:**

   ```swift
   let API_KEY = "YOUR_API_KEY"
   let carsxe = CarsXE(apiKey: API_KEY)
   ```

5. **Use the endpoint methods to access data.**

---

## Usage

The Swift package exposes `async throws` methods that return dynamic JSON as `[String: Any]`. Call them from an async context with `try await`, and use do/catch to handle errors.

Example:

```swift
let API_KEY = "YOUR_API_KEY"
let carsxe = CarsXE(apiKey: API_KEY)
let vin = "WBAFR7C57CC811956"

do {
    let vehicle = try await carsxe.specs(["vin": vin])
    if let input = vehicle["input"] as? [String: Any],
       let vinValue = input["vin"] as? String {
        print("VIN: \(vinValue)")
    } else {
        print("Vehicle response: \(vehicle)")
    }
} catch {
    print("Error: \(error)")
}
```

Example (POST endpoints that accept an image URL):

```swift
do {
    let plateResult = try await carsxe.plateImageRecognition(imageUrl: "https://api.carsxe.com/img/apis/plate_recognition.JPG")
    print(plateResult)
} catch {
    print("Plate image error: \(error)")
}
```

Call these methods from an `async` function, SwiftUI `.task`, or similar async context.

---

## 📚 Endpoints

The CarsXE Swift package provides the following public methods (`async throws`, returning `[String: Any]` unless noted):

### specs — Decode VIN & get full vehicle specifications

Required:

- `vin`  
  Optional:
- `deepdata`
- `disableIntVINDecoding`

Example:

```swift
let vehicle = try await carsxe.specs(["vin": "WBAFR7C57CC811956"])
```

---

### internationalVinDecoder — Decode VIN with worldwide support

Required:

- `vin`  
  Example:

```swift
let intvin = try await carsxe.internationalVinDecoder(["vin": "WF0MXXGBWM8R43240"])
```

---

### platedecoder — Decode license plate info (plate, country)

Required:

- `plate`
- `country` (for many countries; may default to "US" when missing)  
  Optional:
- `state` (required for some countries, e.g. US, AU, CA)
- `district` (required for Pakistan)

Example:

```swift
let decodedPlate = try await carsxe.platedecoder(["plate": "7XER187", "state": "CA", "country": "US"])
```

---

### marketValue — Estimate vehicle market value based on VIN

Required:

- `vin`  
  Optional:
- `state`
- `mileage`
- `condition`
  Example:

```swift
let marketvalue = try await carsxe.marketValue([
    "vin": "WBAFR7C57CC811956",
    "state": "CA",
    "mileage": "50000",
    "condition": "average"
])
```

---

### history — Retrieve vehicle history

Required:

- `vin`  
  Example:

```swift
let history = try await carsxe.history(["vin": "WBAFR7C57CC811956"])
```

---

### images — Fetch images by make, model, year, trim

Required:

- `make`
- `model`  
  Optional:
- `year`, `trim`, `color`, `transparent`, `angle`, `photoType`, `size`, `license`  
  Example:

```swift
let images = try await carsxe.images(["make": "BMW", "model": "X5", "year": "2019"])
```

---

### recalls — Get safety recall data for a VIN

Required:

- `vin`  
  Example:

```swift
let recalls = try await carsxe.recalls(["vin": "1C4JJXR64PW696340"])
```

---

### plateImageRecognition — Read & decode plates from images (POST)

Required:

- `imageUrl` (string)  
  Example:

```swift
let plateImg = try await carsxe.plateImageRecognition(imageUrl: "https://api.carsxe.com/img/apis/plate_recognition.JPG")
```

---

### vinOcr — Extract VINs from images using OCR (POST)

Required:

- `imageUrl` (string)  
  Example:

```swift
let vinocr = try await carsxe.vinOcr(imageUrl: "https://api.carsxe.com/img/apis/plate_recognition.JPG")
```

---

### yearMakeModel — Query vehicle by year, make, model and trim (optional)

Required:

- `year`, `make`, `model`  
  Optional:
- `trim`  
  Example:

```swift
let yymm = try await carsxe.yearMakeModel(["year": "2012", "make": "BMW", "model": "5 Series"])
```

---

### obdcodesdecoder — Decode OBD error/diagnostic codes

Required:

- `code`  
  Example:

```swift
let obdcode = try await carsxe.obdcodesdecoder(["code": "P0115"])
```

---

### lienAndTheft — Get lien and theft information

Required:

- `vin`  
  Example:

```swift
let lienTheft = try await carsxe.lienAndTheft(["vin": "2C3CDXFG1FH762860"])
```

---

### recallsYmm — Get safety recall data by year, make, and model

Required:

- `year`, `make`, `model`  
  Example:

```swift
let recalls = try await carsxe.recallsYmm([
    "year": "2026",
    "make": "toyota",
    "model": "corolla"
])
```

---

### submitBulkRecallBatch — Submit VINs for async bulk recall checking (POST)

Required (at least one):

- `vins` (array of 17-character VIN strings)
- `csv` (inline CSV text)
- `csvUrl` (HTTPS URL to a CSV file)  
  Optional:
- `webhookUrl`  
  Example:

```swift
let submitted = try await carsxe.submitBulkRecallBatch([
    "vins": [
        "1HGBH41JXMN109186",
        "5YJSA1E26HF000001",
        "1C4JJXR64PW696340"
    ],
    "webhookUrl": "https://your-server.com/webhook"
])
```

---

### getBulkRecallBatchStatus — Poll a bulk recalls batch

Required:

- `batchId`  
  Example:

```swift
let status = try await carsxe.getBulkRecallBatchStatus("brb_mnablbn7_wvbaqv")
```

---

### getBulkRecallBatchResults — Retrieve bulk recall results as JSON

Required:

- `batchId`  
  Example:

```swift
let results = try await carsxe.getBulkRecallBatchResults("brb_mnablbn7_wvbaqv")
```

---

### getBulkRecallBatchDownloadUrl / downloadBulkRecallBatch — Download bulk recall results as CSV

Required:

- `batchId`  
  Example:

```swift
let downloadUrl = try carsxe.getBulkRecallBatchDownloadUrl("brb_mnablbn7_wvbaqv")
let csvText = try await carsxe.downloadBulkRecallBatch("brb_mnablbn7_wvbaqv")
```

---

### ymmOptions — Populate year, make, model, and variant dropdowns

Optional:

- `dimension` (`years`, `makes`, `models`, `trims`, `variants`)
- `year`, `make`, `model`, `trim`  
  Example:

```swift
let years = try await carsxe.ymmOptions([:])
let makes = try await carsxe.ymmOptions(["year": "2026"])
let models = try await carsxe.ymmOptions(["make": "Toyota"])
let variants = try await carsxe.ymmOptions([
    "year": "2026",
    "make": "Toyota",
    "model": "Tacoma"
])
```

---

### ownershipVin — Look up registered owner(s) by VIN

Required:

- `vin`  
  Optional:
- `include` (`demographics`, `emails`, `phones`, `vehicle_history`)  
  Example:

```swift
let owners = try await carsxe.ownershipVin(["vin": "1FT8X3BT0BEA61538"])
```

---

### ownershipPerson — Resolve contact details by name and address

Required:

- `first_name`, `last_name`, `address`, `zip`  
  Optional:
- `include`  
  Example:

```swift
let person = try await carsxe.ownershipPerson([
    "first_name": "John",
    "last_name": "Sample",
    "address": "123 Example St",
    "zip": "90210"
])
```

---

### ownershipAddress — Find residents at a street address

Required:

- `address`, `zip`  
  Optional:
- `include`, `variant`  
  Example:

```swift
let residents = try await carsxe.ownershipAddress([
    "address": "123 Example St",
    "zip": "90210"
])
```

---

### ownershipZip — Search people in a ZIP code

Required:

- `zip`  
  Optional:
- `gender`, `min_age`, `max_age`, `income`, `page`, `limit`, `include`, `variant`  
  Example:

```swift
let records = try await carsxe.ownershipZip([
    "zip": "00000",
    "gender": "f",
    "min_age": "45"
])
```

---

## Notes & Best Practices

- Parameter requirements: Each endpoint requires specific parameters—see the Required/Optional fields above.
- Return values: JSON endpoints return Swift dictionaries (`[String: Any]`). `getBulkRecallBatchDownloadUrl` is a sync URL builder (`throws` → `String`). `downloadBulkRecallBatch` is `async throws` and returns CSV text.
- Error handling: Use do/catch with `try await` to handle errors from the API wrapper.
- Concurrency: HTTP methods use Swift concurrency (`URLSession.data(for:)` on Apple platforms). Call them from an async context — they no longer block a thread with a semaphore.
- Serialization: If you need to pass results between threads/tasks, consider serializing to Data (JSON) or decoding into Codable types before dispatching.
- More info: For advanced usage and full details, visit the [official API documentation](https://api.carsxe.com/docs).

---

## Overall

CarsXE API provides a wide range of powerful, easy-to-use tools for accessing and integrating vehicle data into your applications and services. Whether you're a developer or a business owner, you can quickly get the information you need to take your projects to the next level—without hassle or inconvenience.
