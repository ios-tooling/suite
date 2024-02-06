//
//  SwiftUIView.swift
//
//
//  Created by Ben Gottlieb on 2/2/24.
//

import SwiftUI

enum ViewPDFError: Error { case unableToCreateContext }

@available(iOS 16.0, macOS 14, watchOS 10, *)
@MainActor public extension View {
	func toPDF(size: CGSize, at proposed: URL? = nil) async throws -> URL {
		let url = proposed ?? URL.caches.appendingPathComponent("\(self).pdf", conformingTo: .pdf)
		try? FileManager.default.removeItem(at: url)
		let renderer = ImageRenderer(content: self.frame(width: size.width, height: size.height))


		renderer.render { size, context in
			var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
			guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
				return //throw ViewPDFError.unableToCreateContext
			}

			pdf.beginPDFPage(nil)
			context(pdf)
			pdf.endPDFPage()
			pdf.closePDF()
		}
		return url
	}
}
