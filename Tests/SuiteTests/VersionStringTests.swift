//
//  VersionStringTests.swift
//  Suite
//
//  Created by Claude Code on 1/14/25.
//

import Testing
import Suite

struct VersionStringTests {
    
    @Test func testVersionStringComparison() {
        let v1_0_0 = VersionString("1.0.0")
        let v1_0_1 = VersionString("1.0.1")
        let v1_1_0 = VersionString("1.1.0")
        let v2_0_0 = VersionString("2.0.0")
        
        #expect(v1_0_0 < v1_0_1)
        #expect(v1_0_1 < v1_1_0)
        #expect(v1_1_0 < v2_0_0)
        
        #expect(v2_0_0 > v1_1_0)
        #expect(v1_1_0 > v1_0_1)
        #expect(v1_0_1 > v1_0_0)
    }
    
    @Test func testVersionStringEquality() {
        let v1 = VersionString("1.2.3")
        let v2 = VersionString("1.2.3")
        let v3 = VersionString("1.2.4")
        
        #expect(v1 == v2)
        #expect(v1 != v3)
    }
    
    @Test func testVersionStringWithDifferentComponentCounts() {
        let v1_0 = VersionString("1.0")
        let v1_0_0 = VersionString("1.0.0")
        let v1_0_1 = VersionString("1.0.1")
        
        #expect(v1_0 == v1_0_0) // "1.0" should equal "1.0.0"
        #expect(v1_0 < v1_0_1)
        #expect(v1_0_0 < v1_0_1)
        
        let v2 = VersionString("2")
        let v2_0_0 = VersionString("2.0.0")
        #expect(v2 == v2_0_0)
    }
    
    @Test func testVersionStringWithLargerNumbers() {
        let v10_0_0 = VersionString("10.0.0")
        let v2_0_0 = VersionString("2.0.0")
        let v1_15_0 = VersionString("1.15.0")
        let v1_5_0 = VersionString("1.5.0")
        
        #expect(v10_0_0 > v2_0_0)
        #expect(v1_15_0 > v1_5_0) // 15 > 5, not string comparison
    }
    
    @Test func testVersionStringComponents() {
        // Note: components property is internal, so we test functionality through comparisons
        let version1 = VersionString("1.2.3")
        let version2 = VersionString("1.2.3")
        let version3 = VersionString("1.2.4")
        
        #expect(version1 == version2)
        #expect(version1 < version3)
    }
    
    @Test func testVersionStringWithInvalidComponents() {
        // Test with non-numeric components through version comparison
        let versionWithAlpha = VersionString("1.2.alpha")
        let normalVersion = VersionString("1.2")
        
        // These should be equivalent since alpha gets filtered out
        #expect(versionWithAlpha == normalVersion)
    }
    
    @Test func testVersionStringEdgeCases() {
        let v0_0_1 = VersionString("0.0.1")
        let v0_0_0 = VersionString("0.0.0")
        
        #expect(v0_0_1 > v0_0_0)
        
        let vWithSpaces = VersionString("1 . 2 . 3")
        let vNormal = VersionString("1.2.3")
        #expect(vWithSpaces == vNormal)
        
        let vSingleZero = VersionString("0")
        let vZeroZero = VersionString("0.0")
        #expect(vSingleZero == vZeroZero)
    }
    
    @Test func testVersionStringSorting() {
        let versions = [
            VersionString("2.1.0"),
            VersionString("1.0.0"),
            VersionString("1.10.0"),
            VersionString("1.2.0"),
            VersionString("10.0.0")
        ]
        
        let sorted = versions.sorted()
        let expected = [
            VersionString("1.0.0"),
            VersionString("1.2.0"),
            VersionString("1.10.0"),
            VersionString("2.1.0"),
            VersionString("10.0.0")
        ]
        
        #expect(sorted == expected)
    }
    
    @Test func testVersionStringInitialization() {
        let version = VersionString("1.2.3")
        let sameVersion = VersionString("1.2.3")
        #expect(version == sameVersion)
        
        let complexVersion = VersionString("1.2.3-beta.1")
        let otherVersion = VersionString("1.2.3")
        // Note: These should be different due to the beta suffix
        #expect(complexVersion != otherVersion)
    }
}
