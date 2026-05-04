//
//  String.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/10/19.
//  Copyright (c) 2019 Stand Alone, Inc. All rights reserved.
//

import Foundation

public extension String {
	init?(data: Data?, encoding: String.Encoding = .ascii) {
		guard let data = data else { return nil }
		self.init(data: data, encoding: encoding)
	}

	init(_ lines: String...) {
		self = ""
		for (idx, item) in lines.enumerated() {
			self += "\(item)"
			if idx < lines.count - 1 {
				self += "\n"
			}
		}
	}

	static let OK = NSLocalizedString("OK", comment: "OK")
	static let Cancel = NSLocalizedString("Cancel", comment: "Cancel")

	var abbreviatingWithTildeInPath: String { String(NSString(string: self).abbreviatingWithTildeInPath) }
	var expandingTildeInPath: String { String(NSString(string: self).expandingTildeInPath) }

	var pathExtension: String? {
		guard let ext = self.components(separatedBy: ".").last else { return nil }
		if ext.count < 10, !ext.isEmpty { return ext }
		return nil
	}

	var deletingFileExtension: String {
		guard let ext = self.pathExtension else { return self }
		let index = self.index(self.endIndex, offsetBy: -(ext.count + 2))
		return String(self[...index])
	}

	func removingOccurrencesWords(of remove: [String], caseInsensitive: Bool = true) -> String {
		let components = components(separatedBy: .whitespacesAndNewlines)
		let removeThese = caseInsensitive ? remove.map { $0.lowercased() } : remove
		let results = components.filter { !(caseInsensitive ? removeThese.contains($0.lowercased()) : removeThese.contains($0)) }
		return results.joined(separator: " ")
	}

	func stripping(charactersIn set: CharacterSet) -> String {
		String(unicodeScalars.filter { !set.contains($0) })
	}

	func stringByRemovingCharactersInSet(set: CharacterSet) -> String {
		var result = ""
		var count = 0

		for scalar in self.unicodeScalars {
			if !set.contains(scalar) {
				result += String(self[count])
			}
			count += 1
		}
		return result
	}
}

public extension String {
	static func +(left: String?, right: String) -> String {
		(left ?? "") + right
	}

	static func +(left: String, right: String?) -> String {
		left + (right ?? "")
	}

	static func ==(left: String, right: String?) -> Bool {
		if right == nil { return false }
		return left == right!
	}

	static func ==(left: String?, right: String) -> Bool {
		if left == nil { return false }
		return left! == right
	}
}
