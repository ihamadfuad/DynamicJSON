import Testing
import XCTest
import Foundation
@testable import DynamicJSON

final class DynamicFeatureFlagTests: XCTestCase {
    
    func testDynamicJSON() throws {
        let json = """
        {
            "createdAt": "2025-11-15T10:00:00Z",
            "updatedAt": 1640995200000,
            "userType": "premium",
            "isPremiumUser": "1",
            "featureToggle": true,
            "maxItems": "25",
            "discountRate": "12.5",
            "notificationsEnabled": "yes",
            "settings": {
                "darkMode": "on",
                "notifications": {
                    "email": "true",
                    "push": "false"
                }
            },
            "versions": [1, "2", 3.5],
            "flags": {
                "beta_feature": false,
                "new_ui": "true",
                "launch-date": "2024-01-01"
            },
            "nullValue": null
        }
        """.data(using: .utf8)!
        
        let dynamicJSONModel = try JSONDecoder().decode(DynamicJSON.self, from: json)
        
        // Dates (ISO8601 and UNIX ms)
        #expect(dynamicJSONModel.createdAt.as(Date.self) != nil)
        #expect(dynamicJSONModel.updatedAt.as(Date.self) != nil)
        
        // String interpretation
        #expect(dynamicJSONModel.userType.string == "premium")
        
        // Bool from "1", "yes", true, etc
        #expect(dynamicJSONModel.isPremiumUser.bool == true)
        #expect(dynamicJSONModel.notificationsEnabled.bool == true)
        #expect(dynamicJSONModel.featureToggle.bool == true)
        #expect(dynamicJSONModel.settings.darkMode.bool == true)
        #expect(dynamicJSONModel["settings.notifications.email"].bool == true)
        #expect(dynamicJSONModel.settings.notifications.push.bool == false)
        
        // Numeric conversions
        #expect(dynamicJSONModel.maxItems.int == 25)
        #expect(dynamicJSONModel.discountRate.double == 12.5)
        
        // Arrays
        let versions = dynamicJSONModel.versions.array
        #expect(versions?.count == 3)
        #expect(versions?[0].int == 1)
        #expect(versions?[1].int == 2)
        #expect(versions?[2].double == 3.5)
        
        // Nested dot-path access and dynamic member
        #expect(dynamicJSONModel["flags.beta_feature"].bool == false)
        #expect(dynamicJSONModel.flags["new_ui"].bool == true)
        #expect(dynamicJSONModel["flags.launch-date"].as(Date.self) != nil)
        
        // Nulls
        #expect(dynamicJSONModel.nullValue.isNull == true)
        #expect(dynamicJSONModel["doesNotExist"].isNull == true)
        
        // normalized and matched
        #expect(dynamicJSONModel.flags["new-u"].bool == true)        // typo match
        #expect(dynamicJSONModel.flags["NEWUI"].bool == true)      // all uppercase
        #expect(dynamicJSONModel.flags["new-ui"].bool == true)     // hyphen
        #expect(dynamicJSONModel.flags["new ui"].bool == true)     // space
        #expect(dynamicJSONModel.flags.beta_feature.bool == false)        // normalized
    }
    
    func testBenchmarkDynamicJSONPerformance() throws {
        
        let decoder = JSONDecoder()
        // Simulate a moderately large JSON
        let jsonString = (0..<1000).map {
            """
            "feature_\($0)": {
                "enabled": \($0 % 2 == 0),
                "rollout": "\($0 % 100)"
            }
            """
        }.joined(separator: ",\n")
        
        let wrapped = "{ \(jsonString) }"
        guard let data = wrapped.data(using: .utf8) else {
            return
        }
        
        // Run benchmark
        measure {
            let decoded = try? decoder.decode(DynamicJSON.self, from: data)
            #expect(decoded != nil)
            
            // Test accessing and converting various keys
            let sampleKey = "feature_123"
            let value = decoded?[sampleKey].dictionary?["enabled"]?.bool
            #expect(value != nil)
        }
    }
}

