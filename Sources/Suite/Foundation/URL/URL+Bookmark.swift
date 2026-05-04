//
//  URL+Bookmark.swift
//
//
//  Created by Ben Gottlieb on 12/30/19.
//

import Foundation

#if os(OSX)
public extension URL {
	@discardableResult
	func accessSecurely(block: () -> Void) -> Bool {
		if !hasValidBookmarkData || !startAccessingSecurityScopedResource() { return false }
		block()
		stopAccessingSecurityScopedResource()
		return true
	}

	init?(secureBookmarkData data: Data?) {
		var stale = false
		guard let data = data else {
			self.init(string: "")
			return nil
		}
		do {
			self = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale)
			if stale { return nil }
		} catch {
			return nil
		}
	}

	var hasValidBookmarkData: Bool {
		guard let data = secureBookmarkData else { return false }
		return URL(secureBookmarkData: data) != nil
	}

	var secureBookmarkData: Data? {
		do {
			return try self.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
		} catch {
			Suite.logg(error: error, "Unable to extract secure data: \(error)")
			return nil
		}
	}
}
#endif
