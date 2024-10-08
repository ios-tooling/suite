//
//  WebConsole.swift
//
//
//  Created by Ben Gottlieb on 2/5/24.
//

#if canImport(WebKit)

import SwiftUI
import WebKit
import OSLog

@available(iOS 14.0, macOS 11.0, *)
fileprivate let logger = Logger(subsystem: "suite", category: "webconsole")

@available(macOS 12.0, iOS 15, watchOS 10, *)
@MainActor public class WebConsole: NSObject, ObservableObject {
	public private(set) var webView: WKWebView?
	
	public enum State: Sendable { case idle, starting(URL?), loading(URLRequest?), loaded(URLRequest?), failed(URLRequest?, Error) }
	
	@Published public var state: State = .idle
	@Published public var loadedURL: URL?
	var logAllMessages = false
	
	weak var originalNavigationDelegate: WKNavigationDelegate?
	var urlObservation: NSKeyValueObservation?
	
	public func setWebView(_ webView: WKWebView?) {
		if webView == self.webView { return }
		urlObservation?.invalidate()
		urlObservation = nil
		self.webView?.removeObserver(self, forKeyPath: "url")
		
		self.webView?.navigationDelegate = originalNavigationDelegate
		self.webView = webView
		self.originalNavigationDelegate = self.webView?.navigationDelegate
		self.webView?.navigationDelegate = self
		
		urlObservation = webView?.observe(\.url) { webView, change in
			Task { @MainActor in self.loadedURL = webView.url }
		}
	}
	
	public func shutdown() {
		setWebView(nil)
	}
	
	deinit {
		if self.webView != nil {
			logger.warning("WebConsole: PLEASE CALL SHUTDOWN FIRST")
		}
	}
	
	public init(_ webView: WKWebView? = nil) {
		self.webView = webView
		
		super.init()
		setWebView(webView)
	}
	
	func log(_ message: String) {
		if !logAllMessages { return }
		
		logger.info("WebView: \(message)")
	}
	
	@MainActor public func run(script: String) async throws -> String {
		guard let webView else { return "" }
		let fullScript = "\(script)"
		let result = try await webView.evaluateJavaScript(fullScript)
		return result as? String ?? ""
	}
}

@available(macOS 12.0, iOS 15, watchOS 10, *)
@MainActor extension WebConsole: WKNavigationDelegate {
	public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
		log(#function)
		if originalNavigationDelegate?.responds(to: NSSelectorFromString("webView:decidePolicyForNavigationAction:decisionHandler:")) == true {
			originalNavigationDelegate?.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
		} else {
			decisionHandler(.allow)
		}
	}

	public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
		log(#function)
		if originalNavigationDelegate?.responds(to: #selector(webView(_:decidePolicyFor:preferences:decisionHandler:))) == true {
			originalNavigationDelegate?.webView?(webView, decidePolicyFor: navigationAction, preferences: preferences) { policy, prefs in
				if policy == .allow {
					self.state = .loading(navigationAction.request)
				}
				decisionHandler(policy, prefs)
			}
		} else {
			if navigationAction.targetFrame?.isMainFrame == true, navigationAction.request.url != .blank {
				self.state = .loading(navigationAction.request)
			}
			decisionHandler(.allow, preferences)
		}
	}

	public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping @MainActor @Sendable (WKNavigationResponsePolicy) -> Void) {
		log(#function)
		if originalNavigationDelegate?.responds(to: NSSelectorFromString("webView:decidePolicyForNavigationResponse:decisionHandler:")) == true {
			originalNavigationDelegate?.webView?(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler)
		} else {
			decisionHandler(.allow)
		}
	}

	public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
		log(#function)
		self.state = .starting(webView.url)
		originalNavigationDelegate?.webView?(webView, didStartProvisionalNavigation: navigation)
	}

	public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
		log(#function)
		originalNavigationDelegate?.webView?(webView, didReceiveServerRedirectForProvisionalNavigation: navigation)
	}

	public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		log(#function)
		originalNavigationDelegate?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
	}

	public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
		log(#function)
		originalNavigationDelegate?.webView?(webView, didCommit: navigation)
	}

	public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		log(#function)
		if case let .loading(url) = state {
			state = .loaded(url)
		} else if let url = webView.url {
			state = .loaded(URLRequest(url: url))
		} else {
			state = .loaded(nil)
		}

		originalNavigationDelegate?.webView?(webView, didFinish: navigation)
	}
	
	public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		log(#function)
		if case let .loading(request) = state {
			state = .failed(request, error)
		} else if let url = webView.url {
			state = .failed(URLRequest(url: url), error)
		} else {
			state = .failed(nil, error)
		}

		originalNavigationDelegate?.webView?(webView, didFail: navigation, withError: error)
	}

//	@objc public func webView(_ webView: WKWebView, shouldAllowDeprecatedTLSFor challenge: URLAuthenticationChallenge) async -> Bool {
//		log(#function)
//		if originalNavigationDelegate?.responds(to: #selector(webView(_:shouldAllowDeprecatedTLSFor:))) == true {
//			return await originalNavigationDelegate?.webView?(webView, shouldAllowDeprecatedTLSFor: challenge) ?? true
//		} else {
//			return true
//		}
//	}

	@objc public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping @MainActor @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		log(#function)
		if originalNavigationDelegate?.responds(to: #selector(webView(_:didReceive:completionHandler:))) == true {
			originalNavigationDelegate?.webView?(webView, didReceive: challenge, completionHandler: completionHandler)
		} else {
			completionHandler(.useCredential, challenge.proposedCredential)
		}
	}

	public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
		log(#function)
		originalNavigationDelegate?.webViewWebContentProcessDidTerminate?(webView)
	}

	@available(iOS 15, macOS 12, *)
	public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
		log(#function)
		originalNavigationDelegate?.webView?(webView, navigationAction: navigationAction, didBecome: download)
	}

	@available(iOS 15, macOS 12, *)
	public func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
		log(#function)
		originalNavigationDelegate?.webView?(webView, navigationResponse: navigationResponse, didBecome: download)
	}

}
#endif
