//
//  OptionalExtensionTests.swift
//  Suite
//
//  Created by Claude Code on 1/14/25.
//

import Testing
import Suite

struct OptionalExtensionTests {
    
    @Test func testOptionalComparable() {
        let a: Int? = 5
        let b: Int? = 10
        let c: Int? = nil
        let d: Int? = 5
        
        #expect(a < b)
        #expect(!(b < a))
        #expect(!(a < c)) // 5 is not less than nil
        #expect(c < a) // nil is less than 5
        #expect(!(a < d)) // 5 is not less than 5
        #expect(c < b) // nil is less than 10
        
        // Test with strings
        let str1: String? = "apple"
        let str2: String? = "banana"
        let str3: String? = nil
        
        #expect(str1 < str2)
        #expect(str3 < str1)
        #expect(!(str1 < str3))
    }
    
    @Test func testOptionalUnwrap() throws {
        let some: Int? = 42
        let none: Int? = nil
        
        #expect(try some.unwrap() == 42)
        
        do {
            _ = try none.unwrap()
            #expect(Bool(false), "Should have thrown an error")
        } catch Optional<Int>.UnwrappedOptionalError.failedToUnwrap {
            // Expected error
        } catch {
            #expect(Bool(false), "Wrong error type thrown")
        }
    }
    
    @Test func testOptionalCollectionIsEmpty() {
        let someArray: [Int]? = [1, 2, 3]
        let emptyArray: [Int]? = []
        let nilArray: [Int]? = nil
        
        #expect(!someArray.isEmpty)
        #expect(emptyArray.isEmpty)
        #expect(nilArray.isEmpty)
        
        // Test with strings (which are collections)
        let someString: String? = "hello"
        let emptyString: String? = ""
        let nilString: String? = nil
        
        #expect(!someString.isEmpty)
        #expect(emptyString.isEmpty)
        #expect(nilString.isEmpty)
    }
    
    @Test func testOptionalCollectionIsNotEmpty() {
        let someArray: [Int]? = [1, 2, 3]
        let emptyArray: [Int]? = []
        let nilArray: [Int]? = nil
        
        #expect(someArray.isNotEmpty)
        #expect(!emptyArray.isNotEmpty)
        #expect(!nilArray.isNotEmpty)
        
        // Test with dictionaries
        let someDict: [String: Int]? = ["key": 1]
        let emptyDict: [String: Int]? = [:]
        let nilDict: [String: Int]? = nil
        
        #expect(someDict.isNotEmpty)
        #expect(!emptyDict.isNotEmpty)
        #expect(!nilDict.isNotEmpty)
    }
    
    @Test func testOptionalCollectionWithSets() {
        let someSet: Set<String>? = ["a", "b", "c"]
        let emptySet: Set<String>? = []
        let nilSet: Set<String>? = nil
        
        #expect(!someSet.isEmpty)
        #expect(emptySet.isEmpty)
        #expect(nilSet.isEmpty)
        
        #expect(someSet.isNotEmpty)
        #expect(!emptySet.isNotEmpty)
        #expect(!nilSet.isNotEmpty)
    }
    
    @Test func testUnwrappedOptionalErrorProperties() {
        let error = Optional<String>.UnwrappedOptionalError.failedToUnwrap
        
        // Test that it's a proper error type
        let errorAsError: Error = error
        #expect(errorAsError is Optional<String>.UnwrappedOptionalError)
        
        // Test Sendable conformance (compile-time check)
        func sendableFunction(_: any Error & Sendable) {}
        sendableFunction(error)
    }
    
    @Test func testOptionalChaining() {
        struct TestStruct {
            let array: [Int]
        }
        
        let someStruct: TestStruct? = TestStruct(array: [1, 2, 3])
        let nilStruct: TestStruct? = nil
        let emptyStruct: TestStruct? = TestStruct(array: [])
        
        #expect(!(someStruct?.array.isEmpty ?? true))
        #expect(nilStruct?.array.isEmpty == nil) // Returns nil, not true/false
        #expect(emptyStruct?.array.isEmpty == true)
        
        // Use our extension
        let someOptionalArray: [Int]? = someStruct?.array
        let nilOptionalArray: [Int]? = nilStruct?.array
        let emptyOptionalArray: [Int]? = emptyStruct?.array
        
        #expect(!someOptionalArray.isEmpty)
        #expect(nilOptionalArray.isEmpty)
        #expect(emptyOptionalArray.isEmpty)
    }
}