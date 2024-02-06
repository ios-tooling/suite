//
//  SimpleWebView.swift
//  Internal
//
//  Created by Ben Gottlieb on 7/9/23.
//

import SwiftUI
import WebKit

public typealias WebViewCallback = (WKWebView) -> Void
public typealias WebViewErrorCallback = (WKWebView, Error?) -> Void

@available(macOS 11.0, iOS 14, *)
public struct SimpleWebView: View {
	let request: URLRequest
	@Environment(\.webViewDidFinishLoading) var webViewDidFinishLoading
	@State var webView: WKWebView = .init()
	
	public init(url: URL) {
		self.request = URLRequest(url: url)
	}
	
	public init(request: URLRequest) {
		self.request = request
	}
	
	public var body: some View {
		EmbdeddedWebView(request: request, webView: webView, webViewDidFinishLoading: webViewDidFinishLoading)
			.preference(key: SimpleWebViewPreferenceKey.self, value: webView)
	}
}

#if os(macOS)
@available(macOS 11.0, *)
extension SimpleWebView {
	struct EmbdeddedWebView: NSViewRepresentable {
		let request: URLRequest
		let webView: WKWebView
		let webViewDidFinishLoading: WebViewErrorCallback?
		
		func updateNSView(_ uiView: NSViewType, context: Context) {
			load(request, into: context)
		}
		
		func makeNSView(context: Context) -> some NSView {
			load(request, into: context)
			return context.coordinator.webView
		}
		
		func makeCoordinator() -> Coordinator {
			Coordinator(webView: webView, webViewDidFinishLoading: webViewDidFinishLoading)
		}
		
		func load(_ request: URLRequest, into context: Context) {
			if context.coordinator.loadedRequest == request { return }
			
			context.coordinator.loadedRequest = request
			context.coordinator.webView.load(request)
		}
	}
}
#endif
	
#if os(iOS) || os(visionOS)
@available(iOS 14, *)
extension SimpleWebView {
	struct EmbdeddedWebView: UIViewRepresentable {
		let request: URLRequest
		let webView: WKWebView
		let webViewDidFinishLoading: WebViewErrorCallback?

		func updateUIView(_ uiView: UIViewType, context: Context) {
			load(request, into: context)
		}
		
		func makeUIView(context: Context) -> some UIView {
			load(request, into: context)
			return context.coordinator.webView
		}
		
		func load(_ request: URLRequest, into context: Context) {
			if context.coordinator.loadedRequest == request { return }
			
			context.coordinator.loadedRequest = request
			context.coordinator.webView.load(request)
		}
		
		func makeCoordinator() -> Coordinator {
			Coordinator(webView: webView, webViewDidFinishLoading: webViewDidFinishLoading)
		}
	}
}
#endif


#if os(iOS) || os(visionOS) || os(macOS)
@available(macOS 11.0, iOS 14, *)
extension SimpleWebView.EmbdeddedWebView {
	class Coordinator: NSObject, WKNavigationDelegate {
		let webView: WKWebView
		let webViewDidFinishLoading: WebViewErrorCallback?
		var loadedRequest: URLRequest?
		
		init(webView: WKWebView, webViewDidFinishLoading: WebViewErrorCallback?) {
			self.webView = webView
			self.webViewDidFinishLoading = webViewDidFinishLoading
			super.init()
			self.webView.navigationDelegate = self
		}
		
		func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
			self.webViewDidFinishLoading?(webView, nil)
		}
		
		func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
			self.webViewDidFinishLoading?(webView, error)
		}
	}
}
#endif
