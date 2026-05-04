//
//  View+PDF.swift
//
//
//  Created by Ben Gottlieb on 2/2/24.
//

import SwiftUI

enum ViewPDFError: Error, Sendable { case unableToCreateContext }

@available(iOS 16.0, macOS 14, watchOS 10, tvOS 16, *)
@MainActor public extension View {
	func toPDF(size: CGSize, at proposed: URL? = nil) async throws -> URL {
		let url = proposed ?? URL.caches.appendingPathComponent("\(UUID().uuidString).pdf", conformingTo: .pdf)
		try? FileManager.default.removeItem(at: url)
		let renderer = ImageRenderer(content: self.frame(width: size.width, height: size.height))

		var contextError: Error?
		renderer.render { size, context in
			var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
			guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
				contextError = ViewPDFError.unableToCreateContext
				return
			}

			pdf.beginPDFPage(nil)
			context(pdf)
			pdf.endPDFPage()
			pdf.closePDF()
		}
		if let contextError { throw contextError }
		return url
	}
}
