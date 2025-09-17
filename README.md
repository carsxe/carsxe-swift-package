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
       .package(url: "https://github.com/carsxe/carsxe-swift-package.git", from: "1.0.1")
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

The Swift package exposes methods that throw on error and return dynamic JSON as `[String: Any]`. Use do/catch to handle errors.

Example (synchronous/throwing style):
```swift
let API_KEY = "YOUR_API_KEY"
let carsxe = CarsXE(apiKey: API_KEY)
let vin = "WBAFR7C57CC811956"

do {
    let vehicle = try carsxe.specs(["vin": vin])
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
    let plateResult = try carsxe.plateImageRecognition(imageUrl: "https://api.carsxe.com/img/apis/plate_recognition.JPG")
    print(plateResult)
} catch {
    print("Plate image error: \(error)")
}
```

Note: Depending on the runtime and package version you use, there may also be async or completion-based helpers. Check the package source for async variants or completion wrappers.

---

## 📚 Endpoints

The CarsXE Swift package provides the following public methods (signatures may be `throws` and return `[String: Any]`):

### specs — Decode VIN & get full vehicle specifications
Required:
- `vin`  
Optional:
- `deepdata`  
- `disableIntVINDecoding`  

Example:
```swift
let vehicle = try carsxe.specs(["vin": "WBAFR7C57CC811956"])
```

---

### internationalVinDecoder — Decode VIN with worldwide support
Required:
- `vin`  
Example:
```swift
let intvin = try carsxe.internationalVinDecoder(["vin": "WF0MXXGBWM8R43240"])
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
let decodedPlate = try carsxe.platedecoder(["plate": "7XER187", "state": "CA", "country": "US"])
```

---

### marketValue — Estimate vehicle market value based on VIN
Required:
- `vin`  
Optional:
- `state`  
Example:
```swift
let marketvalue = try carsxe.marketValue(["vin": "WBAFR7C57CC811956"])
```

---

### history — Retrieve vehicle history
Required:
- `vin`  
Example:
```swift
let history = try carsxe.history(["vin": "WBAFR7C57CC811956"])
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
let images = try carsxe.images(["make": "BMW", "model": "X5", "year": "2019"])
```

---

### recalls — Get safety recall data for a VIN
Required:
- `vin`  
Example:
```swift
let recalls = try carsxe.recalls(["vin": "1C4JJXR64PW696340"])
```

---

### plateImageRecognition — Read & decode plates from images (POST)
Required:
- `imageUrl` (string)  
Example:
```swift
let plateImg = try carsxe.plateImageRecognition(imageUrl: "https://api.carsxe.com/img/apis/plate_recognition.JPG")
```

---

### vinOcr — Extract VINs from images using OCR (POST)
Required:
- `imageUrl` (string)  
Example:
```swift
let vinocr = try carsxe.vinOcr(imageUrl: "https://api.carsxe.com/img/apis/plate_recognition.JPG")
```

---

### yearMakeModel — Query vehicle by year, make, model and trim (optional)
Required:
- `year`, `make`, `model`  
Optional:
- `trim`  
Example:
```swift
let yymm = try carsxe.yearMakeModel(["year": "2012", "make": "BMW", "model": "5 Series"])
```

---

### obdcodesdecoder — Decode OBD error/diagnostic codes
Required:
- `code`  
Example:
```swift
let obdcode = try carsxe.obdcodesdecoder(["code": "P0115"])
```

---

## Notes & Best Practices

- Parameter requirements: Each endpoint requires specific parameters—see the Required/Optional fields above.
- Return values: All responses from this package are Swift dictionaries ([String: Any]) for easy and flexible access.
- Error handling: Use do/catch blocks to gracefully handle errors thrown by the API wrapper.
- Threading & concurrency: Some package builds expose synchronous (blocking) wrappers that use URLSession + semaphores — avoid calling those from the main/UI thread. If the package or your code uses async/await, prefer keeping network calls and immediate processing in the same async context or convert responses to typed Codable/Sendable models before crossing concurrency boundaries.
- Serialization: If you need to pass results between threads/tasks, consider serializing to Data (JSON) or decoding into Codable types before dispatching.
- More info: For advanced usage and full details, visit the [official API documentation](https://api.carsxe.com/docs).

---

## Overall

CarsXE API provides a wide range of powerful, easy-to-use tools for accessing and integrating vehicle data into your applications and services. Whether you're a developer or a business owner, you can quickly get the information you need to take your projects to the next level—without hassle or inconvenience.