//
//  EnvironmentKeyGenerator.swift
//
//
//  Created by Ben Gottlieb on 3/16/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct EnvironmentKeyGenerator: PeerMacro {
	public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
				
		// Skip non-variables
		guard let varDecl = declaration.as(VariableDeclSyntax.self) else { return [] }
		
		guard var patternBinding = varDecl.bindings.first?.as(PatternBindingSyntax.self) else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.missingAnnotation))
			return []
		}
		
		guard let identifier = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.notAnIdentifier))
			return []
		}
		
		patternBinding.pattern = PatternSyntax(IdentifierPatternSyntax(identifier: .identifier("defaultValue")))
		
		let isOptional = patternBinding.typeAnnotation?.type.is(OptionalTypeSyntax.self) ?? false
		let hasDefaultValue = patternBinding.initializer != nil
		
		guard isOptional || hasDefaultValue else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.noDefaultArgument))
			return []
		}
		
		if patternBinding.isVoidClosure, let initialValue = patternBinding.initializer?.value {
			return [
				"""
				private struct GeneratedEnvironmentKey_\(raw: identifier): EnvironmentKey {
				static let defaultValue = BlockWrapper \(raw: initialValue)
				}
				"""
			]
		} else {
			return [
				"""
				private struct GeneratedEnvironmentKey_\(raw: identifier): EnvironmentKey {
					static let \(patternBinding) \(raw: isOptional && !hasDefaultValue ? "= nil" : "")
				}
				"""
			]
		}
	 }
}

extension PatternBindingSyntax {
	var sendableBlock: String? {
		guard let value = initializer?.value.trimmedDescription, value.hasPrefix("{"), value.hasSuffix("}") else { return nil }
		
		if value.contains("@Sendable") { return value }
		let stripped = String(value.dropFirst().dropLast())
		
		return "{ @Sendable in \(stripped) }"
	}
	var isVoidClosure: Bool {
		guard let raw = initializer?.value else { return false }
		let string = raw.trimmedDescription
		return string.hasPrefix("{") && string.hasSuffix("}")
	}
}

extension EnvironmentKeyGenerator: AccessorMacro {
	public static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
		
		// Skip non-variables
		guard let varDecl = declaration.as(VariableDeclSyntax.self) else { return [] }
		
		guard let patternBinding = varDecl.bindings.first?.as(PatternBindingSyntax.self) else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.missingAnnotation))
			return []
		}
		
		guard let identifier = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.notAnIdentifier))
			return []
		}
		
		if patternBinding.isVoidClosure {
			return [
				 """
				 get { self[GeneratedEnvironmentKey_\(raw: identifier).self].block }
				 """,
				 """
				 set { self[GeneratedEnvironmentKey_\(raw: identifier).self] = BlockWrapper(block: newValue) }
				 """
			]
		} else {
			return [
				 """
				 get { self[GeneratedEnvironmentKey_\(raw: identifier).self] }
				 """,
				 """
				 set { self[GeneratedEnvironmentKey_\(raw: identifier).self] = newValue }
				 """
			]
		}
	}
}
