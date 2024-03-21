//
//  NonIsolatedActorAccessorGenerator.swift
//
//
//  Created by Ben Gottlieb on 3/16/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct NonIsolatedActorAccessorGenerator: PeerMacro {
	public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
		
		// Skip non-variables
		guard let varDecl = declaration.as(VariableDeclSyntax.self) else { 
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.notVariableSyntax))
			return []
		}
		
		guard var patternBinding = varDecl.bindings.first?.as(PatternBindingSyntax.self) else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.missingAnnotation))
			return []
		}
		
		guard let identifier = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.notAnIdentifier))
			return []
		}
		
		let accessorName = "private let nonIsolatedActorAccessor_\(identifier)"
		let optionalType = varDecl.optionalSyntaxType
		patternBinding.pattern = PatternSyntax(IdentifierPatternSyntax(identifier: .identifier("defaultValue")))

		if let initializer = patternBinding.initializer {
			let isOptional = patternBinding.typeAnnotation?.type.is(OptionalTypeSyntax.self) ?? false
			let hasDefaultValue = patternBinding.initializer != nil
			let trimmedInitializer = initializer.value
			
			guard isOptional || hasDefaultValue else {
				context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.noDefaultArgument))
				return []
			}
			
			if let optionalType {
				return ["\(raw: accessorName): CurrentValueSubject<\(raw: optionalType)?, Never> = .init(\(trimmedInitializer))"]
			}

			return ["\(raw: accessorName) = CurrentValueSubject(value: \(trimmedInitializer))"]
		}

		if let optionalType {
			return [
				"\(raw: accessorName): CurrentValueSubject<\(raw: optionalType)?, Never> = .init(nil)"
			]
		}
		return []
	}
}

extension VariableDeclSyntax {
	var optionalSyntaxType: TypeSyntax? {
		bindings.first?.as(PatternBindingSyntax.self)?.typeAnnotation?.type.as(OptionalTypeSyntax.self)?.wrappedType
	}
}

extension IdentifierTypeSyntax {
	 var type: SyntaxProtocol? {
		  genericArgumentClause?.arguments.first?.as(GenericArgumentSyntax.self)?.argument.as(OptionalTypeSyntax.self)?.wrappedType
		  ?? genericArgumentClause?.arguments.first?.as(GenericArgumentSyntax.self)
	 }
}

extension NonIsolatedActorAccessorGenerator: AccessorMacro {
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
		
		return [
				"""
				get { nonIsolatedActorAccessor_\(raw: identifier).value }
				""",
				"""
				set { nonIsolatedActorAccessor_\(raw: identifier).value = newValue }
				"""
		]
	}
}
