//
//  StringExtensionTests.swift
//  Suite
//
//  Created by Claude Code on 1/14/25.
//

import Testing
import Suite

struct StringExtensionTests {
    
    @Test func testStringSubscriptingWithInt() {
        let testString = "Hello World"
        
        #expect(testString[0] == "H")
        #expect(testString[6] == "W")
        #expect(testString[10] == "d")
    }
    
    @Test func testStringSubscriptingWithRange() {
        let testString = "Hello World"
        
        #expect(testString[0..<5] == "Hello")
        #expect(testString[6..<11] == "World")
        #expect(testString[0...4] == "Hello")
        #expect(testString[6...10] == "World")
    }
    
    @Test func testStringSubscriptingWithPartialRange() {
        let testString = "Hello World"
        
        #expect(testString[..<5] == "Hello")
        #expect(testString[6...] == "World")
    }
    
    @Test func testEmailValidation() {
        #expect("test@example.com".isValidEmail == true)
        #expect("user.name+tag@domain.co.uk".isValidEmail == true)
        #expect("invalid.email".isValidEmail == false)
        #expect("@domain.com".isValidEmail == false)
        #expect("user@".isValidEmail == false)
        #expect("".isValidEmail == false)
    }
    
    @Test func testPhoneNumberValidation() {
        #expect("(555) 123-4567".isValidPhoneNumber == true)
        #expect("555-123-4567".isValidPhoneNumber == true)
        #expect("5551234567".isValidPhoneNumber == true)
        #expect("not a phone".isValidPhoneNumber == false)
        #expect("123".isValidPhoneNumber == false)
    }
    
    @Test func testPathExtension() {
        #expect("file.txt".pathExtension == "txt")
        #expect("document.pdf".pathExtension == "pdf")
        #expect("archive.tar.gz".pathExtension == "gz")
        #expect("noextension".pathExtension == nil)
        #expect("file.verylongextensionname".pathExtension == nil) // >10 chars
        #expect("file.".pathExtension == nil) // empty extension
    }
    
    @Test func testDeletingFileExtension() {
        #expect("file.txt".deletingFileExtension == "file")
        #expect("document.pdf".deletingFileExtension == "document")
        #expect("archive.tar.gz".deletingFileExtension == "archive.tar")
        #expect("noextension".deletingFileExtension == "noextension")
    }
    
    @Test func testNumbersOnly() {
        #expect("abc123def456".numbersOnly == "123456")
        #expect("no numbers here".numbersOnly == "")
        #expect("1234567890".numbersOnly == "1234567890")
        #expect("phone: (555) 123-4567".numbersOnly == "5551234567")
    }
    
    @Test func testStrippingCharacters() {
        let testString = "Hello, World! 123"
        #expect(testString.stripping(charactersIn: .punctuationCharacters) == "Hello World 123")
        #expect(testString.stripping(charactersIn: .decimalDigits) == "Hello, World! ")
        #expect(testString.stripping(charactersIn: .whitespacesAndNewlines) == "Hello,World!123")
    }
    
    @Test func testRemovingOccurrencesWords() {
        let testString = "The quick brown fox jumps over the lazy dog"
        let wordsToRemove = ["the", "fox"]
        
        #expect(testString.removingOccurrencesWords(of: wordsToRemove) == "quick brown jumps over lazy dog")
        #expect(testString.removingOccurrencesWords(of: wordsToRemove, caseInsensitive: false) == "The quick brown jumps over lazy dog")
    }
    
    @Test func testStringInitFromData() {
        let data = "Hello".data(using: .utf8)
        #expect(String(data: data, encoding: .utf8) == "Hello")
        #expect(String(data: nil, encoding: .utf8) == nil)
    }
    
    @Test func testStringInitFromLines() {
        let multiLineString = String("Line 1", "Line 2", "Line 3")
        #expect(multiLineString == "Line 1\nLine 2\nLine 3")
        
        let singleLine = String("Only one line")
        #expect(singleLine == "Only one line")
    }
    
    @Test func testStringPositionOfSubstring() {
        let testString = "Hello World"
        #expect(testString.position(of: "World") == 6)
        #expect(testString.position(of: "Hello") == 0)
        #expect(testString.position(of: "xyz") == nil)
    }
    
    @Test func testPathExpansion() {
        let homePath = "~/Documents"
        let expandedPath = homePath.expandingTildeInPath
        #expect(expandedPath.contains("/Documents"))
        #expect(!expandedPath.contains("~"))
        
        let _ = expandedPath.abbreviatingWithTildeInPath
        // Note: This might not always abbreviate depending on the actual path
    }
}
