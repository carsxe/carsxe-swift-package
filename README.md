# 🚗 CarsXE API (Swift Package)

[![Swift Version](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg)](https://github.com/carsxe/carsxe-swift-package)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**CarsXE** is a powerful and developer-friendly API that gives you instant access to a wide range of vehicle data. From VIN decoding and market value estimation to vehicle history, images, OBD code explanations, and plate recognition, CarsXE provides everything you need to build automotive applications at scale.

🌐 **Website:** [https://api.carsxe.com](https://api.carsxe.com)  
📄 **Docs:** [https://api.carsxe.com/docs](https://api.carsxe.com/docs)  
📦 **All Products:** [https://api.carsxe.com/all-products](https://api.carsxe.com/all-products)

To get started with the CarsXE API, follow these steps:

1. **Sign up for a CarsXE account:**

   - [Register here](https://api.carsxe.com/register)
   - Add a [payment method](https://api.carsxe.com/dashboard/billing#payment-methods) to activate your subscription and get your API key.

2. **Add the CarsXE Swift Package to Your Project:**

   #### Using Swift Package Manager

   Add this package to your `Package.swift`:

   ```swift
   dependencies: [
       .package(url: "https://github.com/carsxe/carsxe-swift-package.git", from: "1.0.0")
   ]
   ```

   Or add it through Xcode: **File → Add Package Dependencies...**  
   Enter: `https://github.com/carsxe/carsxe-swift-package.git`

3. **Import the CarsXE Swift Package into your code:**

   ```swift
   import carsxe
   ```

4. **Initialize the API with your API key:**

   ```swift
   let API_KEY = "YOUR_API_KEY"
   let carsxe = CarsXE(apiKey: API_KEY)
   ```

5. **Use the various endpoint methods provided by the API to access the data you need.**

---

## Usage

```swift
let vin = "WBAFR7C57CC811956"

Task {
    do {
        let vehicle = try await carsxe.specs(["vin": vin])
        print(vehicle["input"]?["vin"] ?? "Unknown VIN")
    } catch {
        print("Error: \(error)")
    }
}
```

---

## 📚 Endpoints

The CarsXE API provides the following endpoint methods:

### `specs` – Decode VIN & get full vehicle specifications

**Required:**

- `vin`

**Optional:**

- `deepdata`
- `disableIntVINDecoding`

**Example:**

```swift
let vehicle = try await carsxe.specs(["vin": "WBAFR7C57CC811956"])
```

---

### `intVinDecoder` – Decode VIN with worldwide support

**Required:**

- `vin`

**Optional:**

- None

**Example:**

```swift
let intVin = try await carsxe.intVinDecoder(["vin": "WF0MXXGBWM8R43240"])
```

---

### `plateDecoder` – Decode license plate info (plate, country)

**Required:**

- `plate`
- `country` (always required except for US, where it is optional and defaults to 'US')

**Optional:**

- `state` (required for some countries, e.g. US, AU, CA)
- `district` (required for Pakistan)

> **Note:**
>
> - The `state` parameter is required only when applicable (for
>   specific countries such as US, AU, CA, etc.).
> - For Pakistan (`country='pk'`), both `state` and `district`
>   are required.

**Example:**

```swift
let decodedPlate = try await carsxe.plateDecoder(["plate": "7XER187", "state": "CA", "country": "US"])
```

---

### `marketValue` – Estimate vehicle market value based on VIN

**Required:**

- `vin`

**Optional:**

- `state`

**Example:**

```swift
let marketValue = try await carsxe.marketValue(["vin": "WBAFR7C57CC811956"])
```

---

### `history` – Retrieve vehicle history

**Required:**

- `vin`

**Optional:**

- None

**Example:**

```swift
let history = try await carsxe.history(["vin": "WBAFR7C57CC811956"])
```

---

### `images` – Fetch images by make, model, year, trim

**Required:**

- `make`
- `model`

**Optional:**

- `year`
- `trim`
- `color`
- `transparent`
- `angle`
- `photoType`
- `size`
- `license`

**Example:**

```swift
let images = try await carsxe.images(["make": "BMW", "model": "X5", "year": "2019"])
```

---

### `recalls` – Get safety recall data for a VIN

**Required:**

- `vin`

**Optional:**

- None

**Example:**

```swift
let recalls = try await carsxe.recalls(["vin": "1C4JJXR64PW696340"])
```

---

### `plateImageRecognition` – Read & decode plates from images

**Required:**

- `upload_url`

**Optional:**

- None

**Example:**

```swift
let plateImg = try await carsxe.plateImageRecognition(["upload_url": "https://api.carsxe.com/img/apis/plate_recognition.JPG"])
```

---

### `vinOcr` – Extract VINs from images using OCR

**Required:**

- `upload_url`

**Optional:**

- None

**Example:**

```swift
let vinOcr = try await carsxe.vinOcr(["upload_url": "https://api.carsxe.com/img/apis/plate_recognition.JPG"])
```

---

### `yearMakeModel` – Query vehicle by year, make, model and trim (optional)

**Required:**

- `year`
- `make`
- `model`

**Optional:**

- `trim`

**Example:**

```swift
let ymm = try await carsxe.yearMakeModel(["year": "2012", "make": "BMW", "model": "5 Series"])
```

---

### `obdCodesDecoder` – Decode OBD error/diagnostic codes

**Required:**

- `code`

**Optional:**

- None

**Example:**

```swift
let obdCode = try await carsxe.obdCodesDecoder(["code": "P0115"])
```

---

## Notes & Best Practices

- **Parameter requirements:** Each endpoint requires specific parameters—see the Required/Optional fields above.
- **Return values:** All responses are Swift dictionaries for easy access and manipulation.
- **Error handling:** Use `do/catch` blocks to gracefully handle API errors.
- **More info:** For advanced usage and full details, visit the [official API documentation](https://api.carsxe.com/docs).

---

## Overall

CarsXE API provides a wide range of powerful, easy-to-use tools for accessing and integrating vehicle data into your applications and services. Whether you're a developer or a business owner, you can quickly get the information you need to take your projects to the next level—without hassle or inconvenience.