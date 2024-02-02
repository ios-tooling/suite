//
//  SimpleWebView.swift
//  Internal
//
//  Created by Ben Gottlieb on 7/9/23.
//

import SwiftUI
import WebKit

#if os(macOS)
public struct SimpleWebViewWrapper: NSViewRepresentable {
	let url: URL
	
	public init(url: URL) {
		self.url = url
	}
	
	public func updateNSView(_ uiView: NSViewType, context: Context) {
		context.coordinator.webView.load(URLRequest(url: url))
	}
	
	public func makeNSView(context: Context) -> some NSView {
		context.coordinator.webView.load(URLRequest(url: url))
		return context.coordinator.webView
	}
	
	public func makeCoordinator() -> Coordinator {
		Coordinator()
	}
	
	public class Coordinator: NSObject, WKNavigationDelegate {
		let webView: WKWebView
		
		override init() {
			webView = WKWebView()
			super.init()
			webView.navigationDelegate = self
		}
	}
}

#endif

#if os(iOS) || os(visionOS)
public struct SimpleWebViewWrapper: UIViewRepresentable {
	let request: URLRequest
	@State private var loadedRequest: URLRequest?
	
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
		if loadedRequest == request { return }
		
		loadedRequest = request
		context.coordinator.webView.load(request)
	}
	
	public func makeCoordinator() -> Coordinator {
		Coordinator()
	}
	
	public class Coordinator: NSObject, WKNavigationDelegate {
		let webView: WKWebView
		
		override init() {
			webView = WKWebView()
			super.init()
			webView.navigationDelegate = self
		}
	}
}
#endif
