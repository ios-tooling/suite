//
//  WKWebView.swift
//
//
//  Created by Ben Gottlieb on 2/4/24.
//

import Foundation
import WebKit

enum WKWebViewError: Error { case unableToExtractHTML }

public extension WKWebView {
	var html: String {
		get async throws {
			let raw = try await evaluateJavaScript("document.documentElement.outerHTML.toString()") as? String
			if let raw { return raw }
			throw WKWebViewError.unableToExtractHTML
		}
	}
}
