//
//  String+Validation.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/10/19.
//

import Foundation

public extension String {
	var numbersOnly: String {
		self.reduce("") { result, chr in
			"0123456789".contains(chr) ? result + String(chr) : result
		}
	}

	var mayBeURL: Bool {
		let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.contains(" ") { return false }
		if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") { return true }

		let commonTLDs = ["com", "org", "net", "edu", "gov", "io", "co", "dev", "app", "me"]
		let dotComponents = trimmed.components(separatedBy: ".")
		if dotComponents.count >= 2, let tld = dotComponents.last?.lowercased(), commonTLDs.contains(tld) {
			return true
		}

		return false
	}

	var isValidEmail: Bool {
		let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,50}"
		let emailTest = NSPredicate(format: "SELF MATCHES %@", argumentArray: [emailRegEx])
		return emailTest.evaluate(with: self)
	}

	var isValidPhoneNumber: Bool {
		let types: NSTextCheckingResult.CheckingType = [.phoneNumber]
		guard let detector = try? NSDataDetector(types: types.rawValue) else { return false }
		if let match = detector.matches(in: self, options: [], range: NSMakeRange(0, self.count)).first?.phoneNumber {
			return match == self
		} else {
			return false
		}
	}
}
