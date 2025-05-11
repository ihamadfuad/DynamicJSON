//
//  Utilities.swift
//  DynamicFeatureFlag
//
//  Created by Hamad Ali on 11/05/2025.
//

import Foundation

extension String {
    /// Normalizes a key string into lowercase snake_case format.
    ///
    /// This helps unify access to JSON keys that may use various formats such as:
    /// - camelCase
    /// - PascalCase
    /// - snake_case
    /// - kebab-case
    /// - Spaced strings ("Feature Toggle")
    ///
    /// For example:
    /// - "betaFeatureX" -> "beta_feature_x"
    /// - "BETA-FEATURE-X" -> "beta_feature_x"
    /// - "Feature Toggle" -> "feature_toggle"
    ///
    /// Returns: A normalized version of the string for consistent lookup.
    func normalizedKey() -> String {
        // Replace hyphens and spaces with underscores for consistent splitting
        let sanitized = self
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        
        let pattern = #"(?<=[a-z0-9])(?=[A-Z])|_"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        
        let range = NSRange(sanitized.startIndex..<sanitized.endIndex, in: sanitized)
        let spaced = regex.stringByReplacingMatches(in: sanitized, options: [], range: range, withTemplate: "_")
        
        return spaced
            .split(separator: "_")
            .map { $0.lowercased() }
            .joined(separator: "_")
    }
    
    /// Calculates the Levenshtein distance between two strings.
    ///
    /// The Levenshtein distance is a measure of how many single-character edits
    /// (insertions, deletions, or substitutions) are required to change one word into another.
    ///
    /// This is useful for implementing fuzzy string matching.
    ///
    /// - Parameter target: The string to compare against.
    /// - Returns: The number of edits needed to match the target.
    func levenshteinDistance(to target: String) -> Int {
        let source = Array(self)
        let target = Array(target)
        
        guard !source.isEmpty else { return target.count }
        guard !target.isEmpty else { return source.count }
        
        var previous = Array(0...target.count)
        var current = [Int](repeating: 0, count: target.count + 1)
        
        for i in 1...source.count {
            current[0] = i
            for j in 1...target.count {
                let cost = source[i - 1] == target[j - 1] ? 0 : 1
                current[j] = Swift.min(
                    current[j - 1] + 1,      // insertion
                    previous[j] + 1,         // deletion
                    previous[j - 1] + cost   // substitution
                )
            }
            swap(&previous, &current)
        }
        
        return previous[target.count]
    }
}

extension Dictionary where Key == String, Value == DynamicJSON {
    /// Attempts to find the best-matching key in the dictionary for a given lookup key.
    ///
    /// Matching is performed in the following order:
    /// 1. Exact match (after normalization)
    /// 2. Partial containment (normalized query is a substring of a key)
    /// 3. Fuzzy match using Levenshtein distance (within a threshold)
    ///
    /// - Parameters:
    ///   - key: The original key string provided for lookup.
    ///   - logMatch: A closure used to report fallback key matches for debugging.
    /// - Returns: The best matching `DynamicJSON` value, or `nil` if no reasonable match found.
    func fuzzyMatch(for key: String, logMatch: (_ original: String, _ matched: String) -> Void) -> DynamicJSON? {
        let normalized = key.normalizedKey()
        
        // Try partial match
        if let partial = self.first(where: { $0.key.contains(normalized) }) {
            logMatch(key, partial.key)
            return partial.value
        }
        
        // Fuzzy match
        let maxDistance = 2
        var bestMatchKey: String?
        var bestMatchValue: DynamicJSON?
        var bestDistance = Int.max
        
        for (storedKey, value) in self {
            let distance = normalized.levenshteinDistance(to: storedKey)
            if distance <= maxDistance && distance < bestDistance {
                bestDistance = distance
                bestMatchKey = storedKey
                bestMatchValue = value
            }
        }
        
        if let key = bestMatchKey, let value = bestMatchValue {
            logMatch(key, key)
            return value
        }
        
        return nil
    }
}
