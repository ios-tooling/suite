//
//  SimpleWebView.swift
//  Internal
//
//  Created by Ben Gottlieb on 7/9/23.
//

import SwiftUI
import WebKit

#if os(macOS)
public struct SimpleWebView: NSViewRepresentable {
	let request: URLRequest
	
	public init(url: URL) {
		self.request = URLRequest(url: url)
	}
	
	public init(request: URLRequest) {
		self.request = request
	}

	public func updateNSView(_ uiView: NSViewType, context: Context) {
		load(request, into: context)
	}
	
	public func makeNSView(context: Context) -> some NSView {
		load(request, into: context)
		return context.coordinator.webView
	}
	
	public func makeCoordinator() -> Coordinator {
		Coordinator()
	}
	
	func load(_ request: URLRequest, into context: Context) {
		if context.coordinator.loadedRequest == request { return }
		
		context.coordinator.loadedRequest = request
		context.coordinator.webView.load(request)
	}
}

#endif

#if os(iOS) || os(visionOS)
public struct SimpleWebView: UIViewRepresentable {
	let request: URLRequest
	
	public func updateUIView(_ uiView: UIViewType, context: Context) {
		load(request, into: context)
	}
	
	public init(url: URL) {
		self.request = URLRequest(url: url)
	}
	
	public init(request: URLRequest) {
		self.request = request
	}
	
	public func makeUIView(context: Context) -> some UIView {
		load(request, into: context)
		return context.coordinator.webView
	}
	
	func load(_ request: URLRequest, into context: Context) {
		if context.coordinator.loadedRequest == request { return }
		
		context.coordinator.loadedRequest = request
		context.coordinator.webView.load(request)
	}
	
	public func makeCoordinator() -> Coordinator {
		Coordinator()
	}
}
#endif

#if os(iOS) || os(visionOS) || os(macOS)
extension SimpleWebView {
	public class Coordinator: NSObject, WKNavigationDelegate {
		let webView: WKWebView
		var loadedRequest: URLRequest?
		
		override init() {
			webView = WKWebView()
			super.init()
			webView.navigationDelegate = self
		}
	}
}
#endif
