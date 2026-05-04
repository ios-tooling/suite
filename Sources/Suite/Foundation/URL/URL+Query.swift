//
//  URL+Query.swift
//
//
//  Created by Ben Gottlieb on 12/30/19.
//

import Foundation

public extension URL {
	init?(_ string: String, _ query: [String: String]) {
		guard var base = URL(string: string) else { return nil }
		base.queryDictionary = query
		self = base
	}

	subscript(name: String) -> String? {
		guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return nil }
		return components.queryItems?.first { $0.name == name }?.value
	}

	var queryDictionary: [String: String] {
		get {
			guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return [:] }
			var pairs: [String: String] = [:]

			for item in components.queryItems ?? [] {
				pairs[item.name] = item.value
			}
			return pairs
		}
		set {
			guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return }

			components.queryItems = newValue.keys.map { URLQueryItem(name: $0, value: newValue[$0]) }
			if let newURL = components.url {
				self = newURL
			}
		}
	}
}

extension URLQueryItem: @retroactive Comparable {
	public static func <(lhs: URLQueryItem, rhs: URLQueryItem) -> Bool {
		lhs.name < rhs.name
	}
}
