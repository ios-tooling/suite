//
//  WebConsole.swift
//
//
//  Created by Ben Gottlieb on 2/5/24.
//

import SwiftUI
import WebKit

public class WebConsole: NSObject, ObservableObject {
	public let webView: WKWebView
	
	public enum State { case idle, starting, loading(URLRequest?), loaded(URLRequest?), failed(URLRequest?, Error) }
	
	@Published public var state: State = .idle
	public var loadedURL: URL? { webView.url }
	
	weak var originalNavigationDelegate: WKNavigationDelegate?
	
	public init(_ webView: WKWebView) {
		self.webView = webView
		
		super.init()
		
		self.originalNavigationDelegate = webView.navigationDelegate
		webView.navigationDelegate = self
	}
}

extension WebConsole: WKNavigationDelegate {
	public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		if originalNavigationDelegate?.responds(to: NSSelectorFromString("webView:decidePolicyForNavigationAction:decisionHandler:")) == true {
			originalNavigationDelegate?.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
		} else {
			decisionHandler(.allow)
		}
	}

	public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
		if originalNavigationDelegate?.responds(to: #selector(webView(_:decidePolicyFor:preferences:decisionHandler:))) == true {
			originalNavigationDelegate?.webView?(webView, decidePolicyFor: navigationAction, preferences: preferences) { policy, prefs in
				if policy == .allow {
					self.state = .loading(navigationAction.request)
				}
				decisionHandler(policy, prefs)
			}
		} else {
			self.state = .loading(navigationAction.request)
			decisionHandler(.allow, preferences)
		}
	}

	public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
		if originalNavigationDelegate?.responds(to: NSSelectorFromString("webView:decidePolicyForNavigationResponse:decisionHandler:")) == true {
			originalNavigationDelegate?.webView?(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler)
		} else {
			decisionHandler(.allow)
		}
	}

	public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
		self.state = .starting
		originalNavigationDelegate?.webView?(webView, didStartProvisionalNavigation: navigation)
	}

	public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
		originalNavigationDelegate?.webView?(webView, didReceiveServerRedirectForProvisionalNavigation: navigation)
	}

	public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		originalNavigationDelegate?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
	}

	public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
		originalNavigationDelegate?.webView?(webView, didCommit: navigation)
	}

	public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
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
		if case let .loading(request) = state {
			state = .failed(request, error)
		} else if let url = webView.url {
			state = .failed(URLRequest(url: url), error)
		} else {
			state = .failed(nil, error)
		}

		originalNavigationDelegate?.webView?(webView, didFail: navigation, withError: error)
	}

	@available(iOS 14.0, *)
	public func webView(_ webView: WKWebView, authenticationChallenge challenge: URLAuthenticationChallenge, shouldAllowDeprecatedTLS decisionHandler: @escaping (Bool) -> Void) {
		if originalNavigationDelegate?.responds(to: #selector(webView(_:authenticationChallenge:shouldAllowDeprecatedTLS:))) == true {
			originalNavigationDelegate?.webView?(webView, authenticationChallenge: challenge, shouldAllowDeprecatedTLS: decisionHandler)
		} else {
			decisionHandler(true)
		}
	}

	public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		if originalNavigationDelegate?.responds(to: #selector(webView(_:didReceive:completionHandler:))) == true {
			originalNavigationDelegate?.webView?(webView, didReceive: challenge, completionHandler: completionHandler)
		} else {
			completionHandler(.useCredential, challenge.proposedCredential)
		}
	}

	public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
		originalNavigationDelegate?.webViewWebContentProcessDidTerminate?(webView)
	}

	@available(iOS 14.5, *)
	public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
		originalNavigationDelegate?.webView?(webView, navigationAction: navigationAction, didBecome: download)
	}

	@available(iOS 14.5, *)
	public func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
		originalNavigationDelegate?.webView?(webView, navigationResponse: navigationResponse, didBecome: download)
	}

}
