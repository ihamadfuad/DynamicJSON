# 🧩 DynamicJSON

`DynamicJSON` is a resilient, smart, and flexible wrapper for decoding and interacting 
with dynamic or loosely-structured JSON in Swift. It supports fuzzy key matching, 
automatic type casting, and dot-path access — making it ideal for APIs, 
configuration files, feature flags, and analytics payloads.

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
.package(url: "https://github.com/ihamadfouad/DynamicJSON-SDK.git", from: "1.0.0")

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
let json = try JSONDecoder().decode(DynamicJSON.self, from: jsonData)

let isEnabled = json.featureToggle.bool                  // true
let maxItems = json["maxItems"].int                      // 25
let discount = json.discountRate.double                  // 12.5
let launch = json.launchDate.as(Date.self)               // 2025-01-01

let emailOn = json.settings.notifications.email.bool     // true
let pushOn = json["settings.notifications.push"].bool    // false
```

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
    •    UNIX timestamp: 1704067200 or 1704067200000
 
## 🔬 API

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

## 🧪 Testing

Includes a full real-world test case covering:
    •    All primitive types
    •    Arrays and nested keys
    •    Date strings and timestamps
    •    Fuzzy and normalized keys
    •    Null and missing key handling
