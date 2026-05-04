//
//  String+Random.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/10/19.
//

import Foundation

public extension String {
	static func entropicString(length: Int = 32) -> String {
		precondition(length > 0)
		let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
		var result = ""
		var remainingLength = length

		while remainingLength > 0 {
			let randoms: [UInt8] = (0..<16).map { _ in
				var random: UInt8 = 0
				let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
				if errorCode != errSecSuccess {
					if #available(iOS 14.0, macOS 12, watchOS 9, tvOS 14, *) {
						SuiteLogger.error("Unable to generate a random string, SecRandomCopyBytes failed with OSStatus \(errorCode, privacy: .public)")
					}
					return 0
				}
				return random
			}

			randoms.forEach { random in
				if remainingLength == 0 { return }

				if random < charset.count {
					result.append(charset[Int(random)])
					remainingLength -= 1
				}
			}
		}

		return result
	}

	static func randomEmoji(facesOnly: Bool = false) -> String {
		var range = [UInt32](0x1F601...0x1F64F)
		if !facesOnly { range += [UInt32](0x1F300...0x1F530) }
		let ascii = range.randomElement()!
		return UnicodeScalar(ascii)?.description ?? "🌈"
	}
}
