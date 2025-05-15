//
//  CommandLine.swift
//  
//
//  Created by ben on 3/29/20.
//

import Foundation

public extension CommandLine {
	static func threadsafeArguments() -> [String] {
		UnsafeBufferPointer<UnsafeMutablePointer<CChar>?>(
		  start: CommandLine.unsafeArgv,
		  count: Int(CommandLine.argc)
		).lazy
		  .compactMap { $0 }
		  .compactMap { String(validatingCString: $0) }
	}

	static func bool(for key: String) -> Bool {
		if let string = self.string(for: key)?.lowercased() {
			return string == "y" || string == "yes" || string == "true"
		}
		
		return self.line(for: key) != nil
	}

	static func int(for key: String) -> Int? {
		guard let raw = self.string(for: key) else { return nil }
		guard let number = Int(raw.numbersOnly) else { return nil }
		if raw.hasPrefix("-") { return number * -1 }
		return number
	}

	static func uint64(for key: String) -> UInt64? {
		guard let raw = self.string(for: key) else { return nil }
		return UInt64(raw.numbersOnly)
	}

	static func string(for key: String) -> String? {
		let punct = CharacterSet.punctuationCharacters
		for arg in threadsafeArguments() {
			let comps = arg.components(separatedBy: "=")
			if comps.count < 2 { continue }
			
			if comps[0].trimmingCharacters(in: punct) == key { return Array(comps.dropFirst()).joined(separator: "=").trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
		}
		return nil
	}

	static func line(for key: String) -> String? {
		let punct = CharacterSet.punctuationCharacters
		for arg in threadsafeArguments() {
			if arg.trimmingCharacters(in: punct).hasPrefix(key) { return arg }
		}
		return nil
	}
}
