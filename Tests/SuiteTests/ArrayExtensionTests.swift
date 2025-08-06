//
//  ArrayExtensionTests.swift
//  Suite
//
//  Created by Claude Code on 1/14/25.
//

import Testing
import Suite

struct ArrayExtensionTests {
    
    @Test func testRemoveEquatableElement() {
        var numbers = [1, 2, 3, 4, 5, 3]
        numbers.remove(3) // Should remove first occurrence
        #expect(numbers == [1, 2, 4, 5, 3])
        
        numbers.remove(6) // Element not in array
        #expect(numbers == [1, 2, 4, 5, 3])
    }
    
    @Test func testObjectsAtIndexSet() {
        let numbers = [10, 20, 30, 40, 50]
        let indexSet = IndexSet([0, 2, 4])
        
        #expect(numbers.objects(at: indexSet) == [10, 30, 50])
        #expect(numbers[indexSet] == [10, 30, 50]) // subscript version
        
        // Test with out-of-bounds indices
        let invalidIndexSet = IndexSet([0, 10, 2])
        #expect(numbers.objects(at: invalidIndexSet) == [10, 30])
    }
    
    @Test func testIndicesMatching() {
        let numbers = [1, 2, 3, 4, 5, 6]
        let evenIndices = numbers.indicesMatching { $0 % 2 == 0 }
        #expect(evenIndices == [1, 3, 5]) // indices of [2, 4, 6]
        
        let largeIndices = numbers.indicesMatching { $0 > 10 }
        #expect(largeIndices.isEmpty)
    }
    
    @Test func testFirstAndLastElements() {
        let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        
        #expect(numbers.first(3) == [1, 2, 3])
        #expect(numbers.first(15) == numbers) // More than available
        
        #expect(numbers.last(3) == [8, 9, 10])
        #expect(numbers.last(15) == numbers) // More than available
    }
    
    @Test func testNumericSum() {
        let integers = [1, 2, 3, 4, 5]
        #expect(integers.sum() == 15)
        
        let doubles = [1.5, 2.5, 3.0]
        #expect(doubles.sum() == 7.0)
        
        let emptyArray: [Int] = []
        #expect(emptyArray.sum() == 0)
    }
    
    @Test func testFloatingPointAverage() {
        let doubles = [1.0, 2.0, 3.0, 4.0, 5.0]
        #expect(doubles.average() == 3.0)
        
        let emptyArray: [Double] = []
        #expect(emptyArray.average() == nil)
        
        let singleElement = [42.0]
        #expect(singleElement.average() == 42.0)
    }
    
    @Test func testRemovingDuplicates() {
        let withDuplicates = [1, 2, 3, 2, 4, 3, 5]
        let unique = withDuplicates.removingDuplicates()
        #expect(unique == [1, 2, 3, 4, 5])
        
        let noDuplicates = [1, 2, 3, 4, 5]
        #expect(noDuplicates.removingDuplicates() == noDuplicates)
        
        let empty: [Int] = []
        #expect(empty.removingDuplicates().isEmpty)
    }
    
    @Test func testToggleElement() {
        var numbers = [1, 2, 3, 4]
        
        numbers.toggle(3) // Remove existing element
        #expect(numbers == [1, 2, 4])
        
        numbers.toggle(5) // Add new element
        #expect(numbers == [1, 2, 4, 5])
        
        numbers.toggle(2) // Remove existing element
        #expect(numbers == [1, 4, 5])
    }
    
    @Test func testIdentifiableSubscript() {
        struct TestItem: Identifiable, Equatable {
            let id: Int
            let name: String
        }
        
        var items = [
            TestItem(id: 1, name: "First"),
            TestItem(id: 2, name: "Second"),
            TestItem(id: 3, name: "Third")
        ]
        
        let searchItem = TestItem(id: 2, name: "")
        #expect(items[id: searchItem]?.name == "Second")
        
        // Test setting
        items[id: searchItem] = TestItem(id: 2, name: "Updated")
        #expect(items[1].name == "Updated")
        
        // Test adding new item
        let newItem = TestItem(id: 4, name: "Fourth")
        items[id: newItem] = newItem
        #expect(items.count == 4)
        #expect(items.last?.name == "Fourth")
    }
    
    @Test func testOptionalIndexSubscript() {
        let numbers = [10, 20, 30, 40, 50]
        
        #expect(numbers[index: 2] == 30)
        #expect(numbers[index: nil] == nil)
        #expect(numbers[index: 10] == nil) // Out of bounds
        #expect(numbers[index: -1] == nil) // Negative index
    }
    
    @Test func testBreakIntoChunks() {
        let numbers = Array(1...10)
        
        // Basic chunking
        let chunks = numbers.breakIntoChunks(ofSize: 3)
        #expect(chunks.count == 4)
        #expect(chunks[0] == [1, 2, 3])
        #expect(chunks[1] == [4, 5, 6])
        #expect(chunks[2] == [7, 8, 9])
        #expect(chunks[3] == [10])
        
        // With growth factor
        let growingChunks = numbers.breakIntoChunks(ofSize: 2, growth: 2.0)
        #expect(growingChunks[0] == [1, 2])
        #expect(growingChunks[1] == [3, 4])
        #expect(growingChunks[2] == [5, 6, 7, 8])
		  #expect(growingChunks[3] == [9, 10])

        // Empty array
        let empty: [Int] = []
        #expect(empty.breakIntoChunks(ofSize: 3).isEmpty)
        
        // Array smaller than chunk size
        let small = [1, 2]
        let smallChunks = small.breakIntoChunks(ofSize: 5)
        #expect(smallChunks == [[1, 2]])
    }
    
    @Test func testRawRepresentableArray() {
        enum TestEnum: String, CaseIterable {
            case first, second, third
        }
        
        let enumArray: [TestEnum] = [.first, .second, .third]
        let rawValue = enumArray.rawValue
        #expect(rawValue == "first;second;third")
        
        let reconstructed = [TestEnum](rawValue: rawValue)
        #expect(reconstructed == enumArray)
        
        // Test with invalid raw value
        let invalid = [TestEnum](rawValue: "first;invalid;third")
        #expect(invalid == [.first, .third]) // Invalid values are filtered out
    }
    
    @Test func testCollectionSplitByKeyPath() {
        struct Person: Equatable {
            let name: String
            let age: Int
        }
        
        let people = [
            Person(name: "Alice", age: 25),
            Person(name: "Bob", age: 30),
            Person(name: "Charlie", age: 25),
            Person(name: "David", age: 30)
        ]
        
        let groupedByAge = people.split(by: \.age)
        #expect(groupedByAge.count == 2)
        
        // Find the group with age 25
        let age25Group = groupedByAge.first { group in
            group.first?.age == 25
        }
        #expect(age25Group?.count == 2)
        #expect(age25Group?.contains(Person(name: "Alice", age: 25)) == true)
        #expect(age25Group?.contains(Person(name: "Charlie", age: 25)) == true)
    }
}
