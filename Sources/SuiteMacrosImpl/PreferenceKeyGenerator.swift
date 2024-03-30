//
//  PreferenceKeyGenerator.swift
//
//
//  Created by Ben Gottlieb on 3/16/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct PreferenceKeyGenerator: PeerMacro {
	public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
				
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
		
		guard let keyType = patternBinding.typeAnnotation?.type else {
			context.diagnose(Diagnostic(node: node, message: MacroFeedback.error("Must declare a type.")))
			return []
		}
		
		return [
			 """
			 struct GeneratedPreferenceKey_\(raw: identifier): PreferenceKey {
			 public static func reduce(value: inout \(raw: keyType), nextValue: () -> \(raw: keyType)) {
			 value = value ?? nextValue()
			 }
			 }
			 """
		]

		context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("tttype: \(keyType)")))

		if patternBinding.isVoidClosure, let initialValue = patternBinding.initializer?.value {
			if let signature = varDecl.closureSignature(node: node, in: context) {
				context.diagnose(Diagnostic(node: node, message: MacroFeedback.error("Signature: \(signature)")))
				return []
				
//				return [
					  
//					  ]
			} else {
				context.diagnose(Diagnostic(node: node, message: MacroFeedback.error("Signature: \(initialValue)")))
				return []

//				return [
//					 """
//					 private struct GeneratedPreferenceKey_\(raw: identifier): PreferenceKey {
//					 static let defaultValue = \(raw: initialValue)
//					 }
//					 """
//				]
			}
		} else {
			context.diagnose(Diagnostic(node: node, message: MacroFeedback.error("Missing type info")))
			return []
//			return [
//				"""
//				private struct GeneratedPreferenceKey_\(raw: identifier): PreferenceKey {
//					static let \(patternBinding) \(raw: isOptional && !hasDefaultValue ? "= nil" : "")
//				}
//				"""
//			]
		}
	 }
}

extension PreferenceKeyGenerator: AccessorMacro {
	public static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
		return [
				 """
				 get { nil }
				 """,
			]
		}
}
