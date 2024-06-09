//
//  AppSettingsGenerator.swift
//
//
//  Created by Ben Gottlieb on 6/8/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct AppSettingsGenerator: MemberMacro {
	public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
		
		let members = declaration.memberBlock.members
			.compactMap { $0.decl.as(VariableDeclSyntax.self)?.patternBinding }
		
		
		var results: [DeclSyntax] = []
		
		for variable in members {
			if let token = variable.token?.strippedText, let type = variable.type {
				context.diagnose(Diagnostic(node: variable, message: MacroFeedback.message(variable.debugDescription)))
				if let value = variable.initialValue {
					results.append("""
						var \(raw: token)_backing: \(raw: type.declaration) = \(raw: value)
					""")
				} else {
					results.append("""
						var \(raw: token)_backing: \(raw: type.declaration) = \(raw: "nil")
					""")
				}
			} else {
				context.diagnose(Diagnostic(node: variable, message: MacroFeedback.message(variable.debugDescription)))
			}
		}
		
		return results
	}
}

extension VariableDeclSyntax {
	var patternBinding: PatternBindingSyntax? {
		bindings.first?.as(PatternBindingSyntax.self)
	}
}

extension PatternBindingSyntax {
	var token: TokenSyntax? {
		pattern.as(IdentifierPatternSyntax.self)?.identifier
	}
	

	var type: AppSettingsType? {
		if let typeAnnotation, let ident = typeAnnotation.type.as(IdentifierTypeSyntax.self) { return ident.appSettingsType }
		

		if let typeAnnotation, let opt = typeAnnotation.type.as(OptionalTypeSyntax.self) {
			return opt.wrappedType.as(IdentifierTypeSyntax.self)?.appSettingsType?.optionalized
		}
		
		if let initializer {
			if initializer.value.as(IntegerLiteralExprSyntax.self) != nil { return .integer }
			if initializer.value.as(StringLiteralExprSyntax.self) != nil { return .string }
			if initializer.value.as(BooleanLiteralExprSyntax.self) != nil { return .bool }
			if initializer.value.as(FloatLiteralExprSyntax.self) != nil { return .double }
		}
		
		return nil
	}
	
	var initialValue: String? {
		if let initializer, let value = initializer.literalStringValue {
			return value
		}
		return nil
	}
}

extension IdentifierTypeSyntax {
	var appSettingsType: AppSettingsType? {
		.init(rawValue: name.strippedText)
	}
}

extension InitializerClauseSyntax {
	var literalStringValue: String? {
		if let value = self.value.as(IntegerLiteralExprSyntax.self) {
			return "\(value.literal)"
		}
		
		if let value = self.value.as(BooleanLiteralExprSyntax.self) {
			return "\(value.literal)"
		}

		if let value = self.value.as(FloatLiteralExprSyntax.self) {
			return "\(value.literal)"
		}

		if let value = self.value.as(StringLiteralExprSyntax.self) {
			return value.quotedString
		}
		
		return nil
	}
}

extension StringLiteralExprSyntax {
	var unquotedString: String {
		segments.map { $0.as(StringSegmentSyntax.self)?.content.text ?? "" }.joined(separator: "")
	}

	var quotedString: String {
		"\"" + segments.map { $0.as(StringSegmentSyntax.self)?.content.text ?? "" }.joined(separator: "") + "\""
	}

}

extension TokenSyntax {
	var strippedText: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
}
