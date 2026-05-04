//
//  URL+Path.swift
//
//
//  Created by Ben Gottlieb on 12/30/19.
//

import Foundation

public extension URL {
	@available(iOS 16.0, macOS 13, watchOS 9, tvOS 16, *)
	var containsHomeDirectory: Bool {
		let path = self.path(percentEncoded: false)
		let home = Self.homeDirectory
		return path.contains(home.path) || path.contains("~")
	}

	var removingHomeDirectory: URL {
		if !isFileURL || path.contains("~") { return self }
		return URL(string: path.abbreviatingWithTildeInPath) ?? self
	}

	@available(iOS 16.0, macOS 13, watchOS 9, tvOS 16, *)
	var addingHomeDirectory: URL {
		if !path.contains("~") { return self }
		let path = self.path(percentEncoded: false).replacingOccurrences(of: "~", with: "")
		let home = Self.homeDirectory
		if path.contains(home.path) { return self }
		return home.appending(path: path)
	}

	func isSubdirectory(of url: URL) -> Bool {
		path.hasPrefix(url.path)
	}

	var componentDirectoryURLs: [URL]? {
		let components = path.components(separatedBy: "/")
		var builtUp = URL(fileURLWithPath: "/")

		return [builtUp] + components.map { component in
			builtUp = builtUp.appendingPathComponent(component)
			return builtUp
		}
	}

	func pathRelative(to parent: URL) -> String? {
		let myPath = self.normalizedString
		let parentPath = parent.normalizedString

		if !myPath.hasPrefix(parentPath) { return nil }
		return String(myPath.dropFirst(parentPath.count))
	}

	var isBundleURL: Bool { scheme == Self.bundleScheme }

	var toFileURL: URL? {
		guard !isFileURL else { return self }
		guard isBundleURL else { return nil }

		var bundle = Bundle.main
		if #available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16, *) {
			if let host = host(percentEncoded: false), let new = Bundle(identifier: host) { bundle = new }
		} else {
			if let host, let new = Bundle(identifier: host) { bundle = new }
		}

		return bundle.url(forResource: lastPathComponent, withExtension: nil)
	}

	func replacingPathExtension(with ext: String) -> URL {
		deletingPathExtension().appendingPathExtension(ext)
	}

	var normalizedString: String {
		guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return absoluteString }

		let queryItems = components.queryItems?.sorted() ?? []
		let queryString = queryItems.map { $0.name + "=" + $0.value }.joined(separator: "&")
		let scheme = components.scheme ?? "https"
		let host = components.host ?? "sample.com"
		var path = components.path

		if isFileURL, (path.hasPrefix("/private/var") || path.hasPrefix("private/var")) {
			path = path.replacingOccurrences(of: "private/var/", with: "var/")
		}

		var result = scheme + "://" + host
		if let port = components.port { result += ":\(port)" }
		result += path
		if queryItems.isNotEmpty { result += "?" + queryString }

		return result
	}

	func contains(fileURL: URL) -> Bool {
		if !fileURL.isFileURL || !isFileURL { return false }

		let myAbs = absoluteString.trimmingCharacters(in: .init(charactersIn: "/"))
		let newAbs = fileURL.absoluteString

		return newAbs.hasPrefix(myAbs)
	}

	func isSameFile(as url: URL) -> Bool {
		url.standardizedFileURL == standardizedFileURL
	}
}
