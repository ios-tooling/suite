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
		
		var results: [DeclSyntax] = []
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
				return results
			}
			
			if let optionalType {
				results.append("\(raw: accessorName): CurrentValueSubject<\(raw: optionalType)?, Never> = .init(\(trimmedInitializer))")
			} else {
				results.append("\(raw: accessorName) = CurrentValueSubject(value: \(trimmedInitializer))")
			}
		} else if let optionalType {
			results.append("\(raw: accessorName): CurrentValueSubject<\(raw: optionalType)?, Never> = .init(nil)")
		}
		return results
	}
}

extension VariableDeclSyntax {
	var optionalSyntaxType: TypeSyntax? {
		bindings.first?.as(PatternBindingSyntax.self)?.typeAnnotation?.type.as(OptionalTypeSyntax.self)?.wrappedType
	}
	
	var nonOptionalSyntaxType: TypeSyntax? {
		bindings.first?.as(PatternBindingSyntax.self)?.typeAnnotation?.type.as(TypeSyntax.self)
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
		
		var publishChanges = false
		
		if let args = node.arguments?.children(viewMode: .sourceAccurate).first?.as(LabeledExprSyntax.self)?.expression.as(BooleanLiteralExprSyntax.self)?.literal {
				//context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("\(args.text)")))
			if "\(args)".lowercased() == "true" { publishChanges = true }
		}
		
		return [
				"""
				get { nonIsolatedActorAccessor_\(raw: identifier).value }
				""",
				 publishChanges ?
					"""
					set { nonIsolatedActorAccessor_\(raw: identifier).value = newValue; objectWillChange.sendOnMain() }
					"""
				:
				  """
				  set { nonIsolatedActorAccessor_\(raw: identifier).value = newValue }
				  """
				
			]
	}
}
