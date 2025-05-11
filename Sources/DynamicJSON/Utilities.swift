//
//  Utilities.swift
//  DynamicFeatureFlag
//
//  Created by Hamad Ali on 11/05/2025.
//

import Foundation

extension String {
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
