//
//  DynamicJSON.swift
//  DynamicFeatureFlag
//
//  Created by Hamad Ali on 11/05/2025.
//

import Foundation
import Combine

@dynamicMemberLookup
public enum DynamicJSON: Decodable {
    case dictionary([String: DynamicJSON])
    case array([DynamicJSON])
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: DynamicCodingKeys.self) {
            var dict: [String: DynamicJSON] = [:]
            for key in container.allKeys {
                let normalized = key.stringValue.normalizedKey()
                dict[normalized] = try container.decode(DynamicJSON.self, forKey: key)
            }
            self = .dictionary(dict)
        } else if var arrayContainer = try? decoder.unkeyedContainer() {
            var arr: [DynamicJSON] = []
            while !arrayContainer.isAtEnd {
                arr.append(try arrayContainer.decode(DynamicJSON.self))
            }
            self = .array(arr)
        } else if let val = try? decoder.singleValueContainer().decode(Bool.self) {
            self = .bool(val)
        } else if let val = try? decoder.singleValueContainer().decode(Double.self) {
            self = .number(val)
        } else if let val = try? decoder.singleValueContainer().decode(String.self) {
            self = .string(val)
        } else {
            self = .null
        }
    }
    
    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? = nil
        init?(intValue: Int) { nil }
    }
    
    public subscript(dynamicMember key: String) -> DynamicJSON {
        self[key]
    }
    
    public subscript(_ key: String) -> DynamicJSON {
        let parts = key.split(separator: ".").map { String($0).normalizedKey() }
        return parts.reduce(self) { current, part in
            guard case .dictionary(let dict) = current else { return .null }
            if let exact = dict[part] {
                return exact
            }
            return dict.fuzzyMatch(for: part) { original, matched in
                print("⚠️ [DynamicJSON] '\(original)' matched with '\(matched)' via fuzzy/partial logic.")
            } ?? .null
        }
    }
    
    public var bool: Bool? {
        switch self {
        case .bool(let val): return val
        case .number(let num): return num != 0
        case .string(let str): return ["1", "true", "yes", "on"].contains(str.lowercased())
        default: return nil
        }
    }
    
    public var string: String? {
        switch self {
        case .string(let str): return str
        case .number(let num):
            if num.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(num))
            } else {
                return String(num)
            }
        case .bool(let b): return String(b)
        default: return nil
        }
    }
    
    public var date: Date? {
        switch self {
        case .string(let str):
            
            // Try ISO8601 first
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: str) {
                return date
            }
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            // Try fallback formats
            let fallbackFormats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
                "yyyy-MM-dd'T'HH:mm:ssXXXXX",
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd",
                "MM/dd/yyyy",
                "dd-MM-yyyy"
            ]
            
            for format in fallbackFormats {
                formatter.dateFormat = format
                if let date = formatter.date(from: str) {
                    return date
                }
            }
            return nil
        case .number(let num):
            // If it's a large number, treat as milliseconds
            if num > 1_000_000_000_000 {
                return Date(timeIntervalSince1970: num / 1000)
            } else {
                return Date(timeIntervalSince1970: num)
            }
        default: return nil
        }
    }
    
    public var int: Int? {
        switch self {
        case .number(let num):
            return Int(num)
        case .string(let str):
            if let intVal = Int(str) {
                return intVal
            } else if let doubleVal = Double(str) {
                return Int(doubleVal)
            } else if ["true", "yes", "on"].contains(str.lowercased()) {
                return 1
            } else if ["false", "no", "off"].contains(str.lowercased()) {
                return 0
            }
            return nil
        case .bool(let b):
            return b ? 1 : 0
        default:
            return nil
        }
    }
    
    public var double: Double? {
        switch self {
        case .number(let num): return num
        case .string(let str):
            if let doubleVal = Double(str) {
                return doubleVal
            } else if let intVal = Int(str) {
                return Double(intVal)
            } else if ["true", "yes", "on"].contains(str.lowercased()) {
                return 1.0
            } else if ["false", "no", "off"].contains(str.lowercased()) {
                return 0.0
            }
            return nil
        case .bool(let b): return b ? 1.0 : 0.0
        default:
            return nil
        }
    }
    
    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }
    
    public var dictionary: [String: DynamicJSON]? {
        if case .dictionary(let dict) = self { return dict }
        return nil
    }
    
    public var array: [DynamicJSON]? {
        if case .array(let arr) = self { return arr }
        return nil
    }
    
    public func `as`<T>(_ type: T.Type) -> T? {
        switch type {
        case is Bool.Type:
            return bool as? T
        case is Int.Type:
            return int as? T
        case is Double.Type:
            return double as? T
        case is String.Type:
            return string as? T
        case is Date.Type:
            return date as? T
        default:
            return nil
        }
    }
}
