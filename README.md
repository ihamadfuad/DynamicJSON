# 🧩 DynamicJSON

`DynamicJSON` is a resilient, smart, and flexible wrapper for decoding and interacting 
with dynamic or loosely-structured JSON in Swift. It supports fuzzy key matching, 
automatic type casting, and dot-path access — making it ideal for APIs, 
configuration files, feature flags, and analytics payloads.

---

## 🔁 Before vs After Using DynamicJSON

### ❌ Before (Vanilla Decoding)

```swift
struct Raw: Decodable {
    let feature_toggle: String?
    let darkMode: String?
}

let decoded = try? JSONDecoder().decode(Raw.self, from: jsonData)

let isEnabled = decoded?.feature_toggle == "true"
let isDark = decoded?.darkMode == "on"
```

- You need to define intermediate models
- Compare strings manually
- Deal with missing keys and nils everywhere

---

### ✅ After (Using DynamicJSON)

```swift
let json = try JSONDecoder().decode(DynamicJSON.self, from: jsonData)

let isEnabled = json.featureToggle.bool
let isDark = json.darkMode.bool
```

- No need for models
- One-line type-safe checks
- Supports formats like `"yes"`, `"on"`, `"1"`, and more

---

## ✨ Why DynamicJSON?

Working with JSON in Swift can be painful — especially when the structure is inconsistent, 
values are loosely typed, or keys are formatted in unpredictable ways.

- Some keys are `camelCase`, others are `snake_case`, or even `ALLCAPS`
- Values might be `"true"`, `true`, `"1"`, `1`, or `"yes"` — all meaning the same thing
- Dates can show up in a dozen formats, or even as raw timestamps
- Typos happen — from backend devs or third-party APIs

That’s where `DynamicJSON` comes in. It’s a smart, forgiving, and developer-friendly way 
to decode and work with dynamic JSON data. Whether you're pulling feature flags, 
remote config, analytics events, or responses from external APIs 
`DynamicJSON` makes it all seamless.

`DynamicJSON` handles all of this for you — so you don’t have to write dozens of if-lets, custom decoders, or fail silently.

✅ Normalized key lookup  
✅ Fuzzy match for typos and partial keys  
✅ Smart casting for `Bool`, `Int`, `Double`, `String`, `Date`  
✅ Dot-path access for deep nested values  
✅ Dynamic member syntax (`json.user.name`)  
✅ Type-safe `.as()` casting method

in other words, you ask for what you want, and it finds it — no matter how the data was sent.

---

## 💡 Key Use Cases

- 🔧 Feature flag systems where keys may be inconsistent or added dynamically
- 📦 Remote configuration delivery (AB testing, UI settings, runtime tuning)
- 📊 Analytics and event tracking systems that send flexible JSON payloads
- 🌐 APIs that return unpredictable or evolving response schemas
- 🔌 Third-party integrations where key names and formats can’t be controlled
- 🗂 Legacy systems with inconsistent formatting and naming conventions
- 🧪 Testing tools that need to mock flexible or partial JSON payloads
- ⚙️ Backend-driven UI state (e.g., hiding/showing features remotely)
- 📁 JSON-based configuration files or local overrides in development builds
- 🧵 Telemetry logs and diagnostic data where key/value shape varies per device

---

## 📦 Installation

```swift
.package(url: "https://github.com/ihamadfuad/DynamicJSON.git", from: "1.0.0")

import DynamicJSON

```

## ✅ Features Overview

| Category           | Feature                                                                 | Example or Notes                                                 |
|--------------------|-------------------------------------------------------------------------|------------------------------------------------------------------|
| 🔑 Key Access      | Dot-path access                                                         | `json["user.settings.notifications.email"]`                     |
|                    | Dynamic member access                                                   | `json.user.settings.notifications.email`                        |
|                    | Subscript with format normalization                                     | `json["UserSettings"] == json.user_settings`                    |
|                    | Case-insensitive and format-tolerant key matching                       | Matches camelCase, snake_case, kebab-case, etc.                 |
|                    | Fuzzy key matching (typo-tolerant)                                      | `"featurTogle"` → `"feature_toggle"`                            |
|                    | Partial key match support                                               | `"beta"` → `"beta_feature_x"`                                   |
|                    | Auto-normalized lookup for deep and flat structures                     | Works seamlessly at any nesting depth                           |
| 🔄 Type Conversion | Boolean from string/number/words                                         | `"true"`, `"yes"`, `"1"`, `1`, etc.                             |
|                    | Integer parsing from string, float, bool                                | `"25"`, `25.0`, `true`                                          |
|                    | Double parsing from string/int/bool                                     | `"12.5"`, `1`, `true`                                           |
|                    | String coercion from bool, number                                       | `true` → `"true"`, `42.0` → `"42"`                              |
|                    | Date parsing from multiple formats                                      | ISO8601, MySQL, RFC3339, short, timestamps                      |
|                    | Generic `.as(T.self)` casting                                           | `json["key"].as(Int.self)`                                      |
| 🧩 JSON Structure  | `.array` to unwrap JSON arrays                                           | Returns `[DynamicJSON]?`                                        |
|                    | `.dictionary` to unwrap objects                                         | Returns `[String: DynamicJSON]?`                                |
|                    | `.isNull` to check for `null` or missing values                         | Returns `true` if `null` or nonexistent                         |
| 🔍 Developer Tools | Logs fuzzy/partial matches with warnings                                | Helpful for debugging mismatches                                |
|                    | Gracefully returns `.null` instead of crashing on access                | Safe fallback handling                                          |
| 🛠 Use Flexibility | Works with deeply nested and mixed-type JSON                            | Great for dynamic payloads                                      |
|                    | Handles inconsistent or unpredictable backends                          | Makes JSON-safe across the board                                |

# 🚀 Usage Example

```json
{
  "featureToggle": "true",
  "maxItems": "25",
  "discountRate": 12.5,
  "launchDate": "2025-01-01T00:00:00Z",
  "settings": {
    "dark_mode": "on",
    "notifications": {
      "email": "yes",
      "push": false
    }
  }
}
```

```swift
do {
    let json = try JSONDecoder().decode(DynamicJSON.self, from: jsonData)

    let isEnabled = json.featureToggle.bool                  // true
    let maxItems = json["maxItems"].int                      // 25
    let discount = json.discountRate.double                  // 12.5
    let launch = json.launchDate.as(Date.self)               // 2025-01-01

    let emailOn = json.settings.notifications.email.bool     // true
    let pushOn = json["settings.notifications.push"].bool    // false
} catch {
    print("Failed to decode JSON: \(error)")
}
```

---

## 🧠 Smart Key Matching

DynamicJSON will normalize and match keys like:
•    "FeatureToggle" → "feature_toggle"
•    "darkMode" → "dark_mode"
•    "beta-feature-x" → "beta_feature_x"
•    "FEATURETOGGLE" → "feature_toggle"
•    "featurTogle" → fuzzy match → "feature_toggle"
 
📅 Date Parsing

Supports:
•    2024-01-01T12:34:56Z
•    2024-01-01T12:34:56.123Z
•    2024-01-01 12:34:56
•    2024-01-01
•    01/01/2024
•    01-01-2024
•    UNIX timestamp & with milisoconds: 1704067200 or 1704067200000
 
## 🔬 More in depth

Accessors

```swift
json["key"]
json.key
json["nested.key.path"]
json.key.bool / .int / .double / .string / .date
json.key.as(Int.self)
```

Containers

```swift
json.array → [DynamicJSON]?
json.dictionary → [String: DynamicJSON]?
json.isNull → Bool
```


---

## 🎯 Frequently Asked Questions

### ❓ What happens if a key is missing?
You’ll get `.null` back. You can check using `json["key"].isNull` or safely unwrap optional values.

---

### ❓ Will this crash if the JSON is malformed?
No. If decoding fails, it throws like any regular `Decodable` type. Accessing values afterward will never crash — you’ll just get `nil` or `.null`.

---

### ❓ Does it work with nested objects and arrays?
Yes. You can drill down using dot-paths (`json["user.settings.notifications"]`) or dynamic members (`json.user.settings.notifications`).

---

### ❓ Can I use it alongside regular `Codable` structs?
Absolutely. Use `DynamicJSON` for dynamic/unknown parts of the payload, and `Codable` for strict parts.

---

### ❓ What date formats are supported?
Out of the box:
- ISO8601
- RFC3339 with milliseconds
- MySQL datetime (`yyyy-MM-dd HH:mm:ss`)
- Short format (`yyyy-MM-dd`)
- Timestamps in seconds and milliseconds

---

### ❓ How is it different from `[String: Any]`?
Unlike `[String: Any]`, `DynamicJSON` is type-safe, supports dot access, fuzzy keys, smart casting, and works with Swift’s `Decodable`.

---

### ❓ Can I use this in production apps?
Yes — it's designed to be resilient, readable, and production-safe.

---

### ❓ Will this impact performance?
Key normalization and fuzzy matching are optimized and fast for typical payloads. If needed, you can disable fuzzy matching in future versions.

---

### ❓ What Swift versions are supported?
Swift 5.9 and later (uses modern `Decodable` patterns and dynamic member lookup).

---

### ❓ Is this tested?
Yes — it includes extensive tests for decoding, type coercion, fuzzy keys, date formats, and more.
