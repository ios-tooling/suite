//
//  ImageTests.swift
//  
//
//  Created by Ben Gottlieb on 11/19/21.
//

import Testing
import Suite

struct ImageTests {
    
    @Test func testResizing() throws {
        let landscape = CGRect(x: 0, y: 0, width: 1024, height: 768)
        let portrait = CGRect(x: 0, y: 0, width: 768, height: 1024)
        let square = CGRect(x: 0, y: 0, width: 300, height: 300)
        
         let horizontalLetterboxing = landscape.within(limit: square, placed: .scaleAspectFit)
         let verticalLetterboxing = portrait.within(limit: square, placed: .scaleAspectFit)

         #expect(horizontalLetterboxing.width == square.width && horizontalLetterboxing.aspectRatio == landscape.aspectRatio)
         #expect(verticalLetterboxing.height == square.height && verticalLetterboxing.aspectRatio == portrait.aspectRatio)
        
        // Test basic area calculation instead
		 #expect(landscape.area == 1024.0 * 768)
        #expect(portrait.area == 768.0 * 1024)
        #expect(square.area == 300.0 * 300)
    }
    
}
