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
        // Convert hyphens and spaces to underscores for a unified delimiter
        let sanitized = self
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        
        // Pattern splits between lowercase/digit followed by uppercase, or on existing underscores
        let pattern = #"(?<=[a-z0-9])(?=[A-Z])|_"#
        // Compile the regular expression
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        
        let range = NSRange(sanitized.startIndex..<sanitized.endIndex, in: sanitized)
        // Insert underscores where pattern matches (e.g., camelCase -> camel_Case)
        let spaced = regex.stringByReplacingMatches(in: sanitized, options: [], range: range, withTemplate: "_")
        
        // Normalize by lowercasing and rejoining with single underscores
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
        
        // Convert both strings into character arrays for index-based access
        let source = Array(self)
        let target = Array(target)
        
        // If either string is empty, the distance is simply the length of the other
        guard !source.isEmpty else { return target.count }
        guard !target.isEmpty else { return source.count }
        
        // Initialize the previous row of distances (edit distances from empty string to target)
        var previous = Array(0...target.count)
        
        // Prepare the current row to be computed during iteration
        var current = [Int](repeating: 0, count: target.count + 1)
        
        // Loop through each character in the source string
        for i in 1...source.count {
            
            current[0] = i
            
            // Calculate cost: 0 if characters match, 1 otherwise
            for j in 1...target.count {
                
                // Compute the minimum edit distance considering insertion, deletion, and substitution
                let cost = source[i - 1] == target[j - 1] ? 0 : 1
                
                current[j] = Swift.min(
                    current[j - 1] + 1,      // insertion
                    previous[j] + 1,         // deletion
                    previous[j - 1] + cost   // substitution
                )
            }
            
            // Move current row to previous for next iteration
            swap(&previous, &current)
        }
        
        // Final distance is the last value in the previous row
        return previous[target.count]
    }
}

extension Dictionary where Key == String, Value == DynamicJSON {
    
    /// Note: The Levenshtein distance is a metric for measuring the difference between two strings. Specifically, it calculates the minimum number of single-character edits required to transform one string into the other
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
        
        // Normalize the input key for consistent comparison
        let normalized = key.normalizedKey()
        
        // Step 1: Attempt partial match by checking if any stored key contains the normalized key
        if let partial = self.first(where: { $0.key.contains(normalized) }) {
            // Log and return the first partial match found
            logMatch(key, partial.key)
            return partial.value
        }
        
        // Step 2: Perform fuzzy matching using Levenshtein distance
        let maxDistance = 2
        var bestMatchKey: String?
        var bestMatchValue: DynamicJSON?
        
        // Initialize tracking variables for the best fuzzy match found
        var bestDistance = Int.max
        
        for (storedKey, value) in self {
            // Compute the Levenshtein distance between normalized input and stored key
            let distance = normalized.levenshteinDistance(to: storedKey)
            if distance <= maxDistance && distance < bestDistance {
                // Update best match if the distance is within threshold and better than previous
                bestDistance = distance
                bestMatchKey = storedKey
                bestMatchValue = value
            }
        }
        
        // If a suitable fuzzy match was found, return it
        if let key = bestMatchKey, let value = bestMatchValue {
            logMatch(key, key)
            return value
        }
        
        // No match found; return nil
        return nil
    }
}
