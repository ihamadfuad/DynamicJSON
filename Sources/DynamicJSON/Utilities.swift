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
        let pattern = #"(?<=[a-z0-9])(?=[A-Z])|[_\-\s]+"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        
        let range = NSRange(startIndex..<endIndex, in: self)
        let spaced = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "_")
        
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
        let (m, n) = (source.count, target.count)
        
        var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }
        
        for i in 1...m {
            for j in 1...n {
                let cost = source[i - 1] == target[j - 1] ? 0 : 1
                matrix[i][j] = Swift.min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }
        
        return matrix[m][n]
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
        
        if let partial = self.first(where: { $0.key.contains(normalized) }) {
            logMatch(key, partial.key)
            return partial.value
        }
        
        let maxDistance = 2
        let best = self.map { ($0.key, $0.value, normalized.levenshteinDistance(to: $0.key)) }
            .filter { $0.2 <= maxDistance }
            .sorted(by: { $0.2 < $1.2 })
            .first
        
        if let (matchKey, value, _) = best {
            logMatch(key, matchKey)
            return value
        }
        
        return nil
    }
}
