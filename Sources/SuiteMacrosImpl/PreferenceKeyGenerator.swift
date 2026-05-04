//
//  PreferenceKeyGenerator.swift
//
//
//  Created by Ben Gottlieb on 3/16/24.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public enum PreferenceKeyGenerator: DeclarationMacro {
	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard let keyName = name(from: node) else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.error("Please provide a name for this key (as a string).")))
			return []
		}

		guard isValidIdentifier(keyName) else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.error("`\(keyName)` is not a valid Swift identifier.")))
			return []
		}

		guard let keyType = type(from: node) else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.error("Please provide a type for this key.")))
			return []
		}

		var defaultClause: String?
		if let defaultValue = self.defaultValue(from: node) {
			defaultClause = "static let defaultValue: \(keyType) = \(defaultValue)"
		} else if !keyType.hasSuffix("?") {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.error("Non-optional types must provide a defaultValue")))
			return []
		}
		let keyTypeName = "GeneratedPreferenceKey_\(keyName)"
		return [
"""
struct \(raw: keyTypeName): PreferenceKey {
    \(raw: defaultClause ?? "")
    static func reduce(value: inout \(raw: keyType), nextValue: () -> \(raw: keyType)) {
        preferenceReduce(value: &value, nextValue: nextValue)
    }
}
var \(raw: keyName): \(raw: keyTypeName).Type {
    \(raw: keyTypeName).self
}
"""
		]
	}

	static func type(from node: some FreestandingMacroExpansionSyntax) -> String? {
		let args = node.arguments
		guard args.count >= 2 else { return nil }

		let secondIndex = args.index(after: args.startIndex)
		let segment = args[secondIndex].expression

		let typeString = segment.description.trimmingCharacters(in: .whitespacesAndNewlines)
		if typeString.hasSuffix(".self") {
			return String(typeString.dropLast(5)).trimmingCharacters(in: .whitespacesAndNewlines)
		}
		return typeString
	}

	static func defaultValue(from node: some FreestandingMacroExpansionSyntax) -> String? {
		let args = node.arguments
		guard args.count == 3 else { return nil }
		guard let last = args.last else { return nil }
		return last.expression.description
	}

	static func name(from node: some FreestandingMacroExpansionSyntax) -> String? {
		guard let first = node.arguments.first?.expression.as(StringLiteralExprSyntax.self) else { return nil }
		guard let segment = first.segments.first?.as(StringSegmentSyntax.self) else { return nil }
		return segment.content.text
	}

	private static func isValidIdentifier(_ name: String) -> Bool {
		guard !name.isEmpty else { return false }
		guard let first = name.unicodeScalars.first else { return false }
		// Swift identifiers: first char must be a letter or `_`; subsequent may also include digits.
		let head = CharacterSet.letters.union(CharacterSet(charactersIn: "_"))
		let tail = head.union(.decimalDigits)
		guard head.contains(first) else { return false }
		for scalar in name.unicodeScalars.dropFirst() {
			if !tail.contains(scalar) { return false }
		}
		return true
	}
}
