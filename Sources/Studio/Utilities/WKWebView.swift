//
//  WKWebView.swift
//
//
//  Created by Ben Gottlieb on 2/4/24.
//

import Foundation
import WebKit

enum WKWebViewError: Error { case unableToExtractHTML, noDataReturned, badDataReturned }

public extension WKWebView {
	@MainActor var html: String {
		get async throws {
			let raw = try await evaluateJavaScript("document.documentElement.outerHTML.toString()") as? String
			if let raw { return raw }
			throw WKWebViewError.unableToExtractHTML
		}
	}
	
	@MainActor func decode<Result: Decodable>(script: String) async throws -> Result {
		guard let raw = try await evaluateJavaScript(script) as? String else { throw WKWebViewError.noDataReturned }
		guard let data = raw.data(using: .utf8) else { throw WKWebViewError.badDataReturned }
		
		return try JSONDecoder().decode(Result.self, from: data)
	}
}
