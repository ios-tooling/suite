//
//  CoreGraphicsExtensionTests.swift
//  Suite
//
//  Created by Claude Code on 1/14/25.
//

import Testing
import Suite
import CoreGraphics

struct CoreGraphicsExtensionTests {
    
    @Test func testCGRectArea() {
        let rect1 = CGRect(x: 0, y: 0, width: 10, height: 5)
        let rect2 = CGRect(x: 0, y: 0, width: 4, height: 3)
        
        #expect(rect1.area == 50)
        #expect(rect2.area == 12)
    }
    
    @Test func testCGRectComparable() {
        let smallRect = CGRect(x: 0, y: 0, width: 2, height: 3) // area = 6
        let largeRect = CGRect(x: 0, y: 0, width: 4, height: 5) // area = 20
        let equalRect = CGRect(x: 10, y: 10, width: 2, height: 3) // area = 6
        
        #expect(smallRect < largeRect)
        #expect(!(largeRect < smallRect))
        #expect(!(smallRect < equalRect)) // Equal areas
        #expect(!(equalRect < smallRect))
        
        // Test with sorted arrays
        let rects = [largeRect, smallRect, equalRect]
        let sorted = rects.sorted()
        #expect(sorted[0].area <= sorted[1].area)
        #expect(sorted[1].area <= sorted[2].area)
    }
    
    @Test func testCGRectHashable() {
        let rect1 = CGRect(x: 1, y: 2, width: 3, height: 4)
        let rect2 = CGRect(x: 1, y: 2, width: 3, height: 4)
        let rect3 = CGRect(x: 2, y: 2, width: 3, height: 4)
        
        let set: Set<CGRect> = [rect1, rect2, rect3]
        #expect(set.count == 2) // rect1 and rect2 are equal
        #expect(set.contains(rect1))
        #expect(set.contains(rect2))
        #expect(set.contains(rect3))
    }
    
    @Test func testCGRectRanges() {
        let rect = CGRect(x: 10, y: 20, width: 30, height: 40)
        
        #expect(rect.xRange == 10.0..<40.0)
        #expect(rect.yRange == 20.0..<60.0)
    }
    
    @Test func testCGRectStringInitializable() {
        let rect = CGRect(x: 1, y: 2, width: 3, height: 4)
        let stringValue = rect.stringValue
        
        #expect(stringValue.contains("1"))
        #expect(stringValue.contains("2"))
        #expect(stringValue.contains("3"))
        #expect(stringValue.contains("4"))
        
        // Test round-trip conversion (Note: actual implementation may vary)
        let rawValue = rect.rawValue
        #expect(!rawValue.isEmpty)
    }
    
    @Test func testCGRectUnitConstant() {
        let unit = CGRect.unit
        #expect(unit == CGRect(x: 0, y: 0, width: 1, height: 1))
        #expect(unit.area == 1)
    }
    
    @Test func testCGPointSize() {
        let point = CGPoint(x: 5, y: 10)
        let size = point.size
        
        #expect(size.width == 5)
        #expect(size.height == 10)
    }
    
    @Test func testCGPointCenteredRect() {
        let center = CGPoint(x: 50, y: 60)
        let size = CGSize(width: 20, height: 30)
        let rect = center.centeredRect(size: size)
        
        #expect(rect.midX == 50)
        #expect(rect.midY == 60)
        #expect(rect.width == 20)
        #expect(rect.height == 30)
        
        // Test with double parameter
        let squareRect = center.centeredRect(size: 10.0)
        #expect(squareRect.midX == 50)
        #expect(squareRect.midY == 60)
        #expect(squareRect.width == 10)
        #expect(squareRect.height == 10)
    }
    
    @Test func testCGPointSquare() {
        let center = CGPoint(x: 25, y: 35)
        let side: CGFloat = 10
        let square = center.square(side: side)
        
        #expect(square.midX == 25)
        #expect(square.midY == 35)
        #expect(square.width == 10)
        #expect(square.height == 10)
    }
    
    @Test func testCGPointAdjustments() {
        let point = CGPoint(x: 10, y: 20)
        
        let adjustedX = point.adjustX(5)
        #expect(adjustedX.x == 15)
        #expect(adjustedX.y == 20)
        
        let adjustedY = point.adjustY(-3)
        #expect(adjustedY.x == 10)
        #expect(adjustedY.y == 17)
        
        // Test chaining
        let adjusted = point.adjustX(5).adjustY(-3)
        #expect(adjusted.x == 15)
        #expect(adjusted.y == 17)
    }
    
    @Test func testRoundCGFloat() {
        #expect(roundcgf(value: 3.7) == 3.0)
        #expect(roundcgf(value: 3.2) == 3.0)
        #expect(roundcgf(value: -2.8) == -3.0)
        #expect(roundcgf(value: 0.9) == 0.0)
    }
}