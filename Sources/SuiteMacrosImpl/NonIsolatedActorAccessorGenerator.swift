//
//  NonisolatedContainerGenerator.swift
//
//
//  Created by Ben Gottlieb on 3/16/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct NonisolatedContainerGenerator: PeerMacro {
	public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
		
		var results: [DeclSyntax] = []
		// Skip non-variables
		guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.notVariableSyntax))
			return []
		}
		
		guard var patternBinding = varDecl.bindings.first else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.missingAnnotation))
			return []
		}
		
		guard let identifier = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.notAnIdentifier))
			return []
		}
		
		var hasNonisolatedKeyword = false
		for child in varDecl.children(viewMode: .all) {
			if let modifier = child.as(DeclModifierListSyntax.self) {
				if let keyword = modifier.first {
					if keyword.name.text.lowercased() == "nonisolated" {
						hasNonisolatedKeyword = true
					}
				}
			}
		}
		
		if !hasNonisolatedKeyword {
			context.diagnose(Diagnostic(node: declaration, message: MacroFeedback.error("Please add the `nonisolated` annotation to the variable declaration")))

		}

		let accessorName = "private nonisolated let nonIsolatedBackingContainer_\(identifier)"
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
				results.append("\(raw: accessorName): ThreadsafeMutex<\(raw: optionalType)?> = .init(\(trimmedInitializer))")
			} else {
				results.append("\(raw: accessorName) = ThreadsafeMutex(\(trimmedInitializer))")
			}
		} else if let optionalType {
			results.append("\(raw: accessorName): ThreadsafeMutex<\(raw: optionalType)?> = .init(nil)")
		}
		return results
	}
}

extension VariableDeclSyntax {
	var optionalSyntaxType: TypeSyntax? {
		bindings.first?.typeAnnotation?.type.as(OptionalTypeSyntax.self)?.wrappedType
	}
	
	var nonOptionalSyntaxType: TypeSyntax? {
		bindings.first?.typeAnnotation?.type
	}
}

extension IdentifierTypeSyntax {
	 var type: SyntaxProtocol? {
		  genericArgumentClause?.arguments.first?.argument.as(OptionalTypeSyntax.self)?.wrappedType
		  ?? genericArgumentClause?.arguments.first
	 }
}

extension NonisolatedContainerGenerator: AccessorMacro {
	public static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
		
		// Skip non-variables
		guard let varDecl = declaration.as(VariableDeclSyntax.self) else { return [] }
		
		guard let patternBinding = varDecl.bindings.first else {
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
				get { nonIsolatedBackingContainer_\(raw: identifier).value }
				""",
				 publishChanges ?
					"""
					set { nonIsolatedBackingContainer_\(raw: identifier).value = newValue; objectWillChange.sendOnMain() }
					"""
				:
				  """
				  set { nonIsolatedBackingContainer_\(raw: identifier).value = newValue }
				  """
				
			]
	}
}
