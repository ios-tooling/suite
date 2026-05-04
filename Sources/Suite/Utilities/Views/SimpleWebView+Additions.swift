//
//  SimpleWebViewAdditions.swift
//  
//
//  Created by Ben Gottlieb on 2/4/24.
//

#if canImport(WebKit)
import SwiftUI
import WebKit

struct WebViewDidFinishLoadingEnvironmentKey: EnvironmentKey {
	nonisolated(unsafe) static let defaultValue: WebViewErrorCallback? = nil
}

public extension EnvironmentValues {
	var webViewDidFinishLoading: WebViewErrorCallback?  {
		get { self[WebViewDidFinishLoadingEnvironmentKey.self] }
		set { self[WebViewDidFinishLoadingEnvironmentKey.self] = newValue }
	}
}

@available(macOS 11.0, iOS 14, *)
struct SimpleWebViewPreferenceKey: PreferenceKey {
	typealias Value = WKWebView?
	
	static func reduce(value: inout WKWebView?, nextValue: () -> WKWebView?) {
		value = value ?? nextValue()
	}
}

@available(macOS 11.0, iOS 14, *)
struct SimpleWebViewAccessor<Content: View>: View {
	@State var webView: WKWebView?
	let content: Content
	var callback: WebViewCallback
	
	init(content: Content, callback: @escaping WebViewCallback) {
		self.content = content
		self.callback = callback
	}
	
	var body: some View {
		content
			.onPreferenceChange(SimpleWebViewPreferenceKey.self) { [$webView] newView in $webView.wrappedValue = newView }
            .onAppear {
                if let webView { callback(webView) }
            }
       #if os(visionOS)
            .onChange(of: webView) { if let webView { callback(webView) } }
        #else
			.onChange(of: webView) { webView in if let webView { callback(webView) } }
        #endif
	}
}

@available(macOS 11.0, iOS 14, *)
public extension View {
	func embeddedWebView(callback: @escaping (WKWebView) -> Void) -> some View {
		SimpleWebViewAccessor(content: self, callback: callback)
	}
}
#endif
