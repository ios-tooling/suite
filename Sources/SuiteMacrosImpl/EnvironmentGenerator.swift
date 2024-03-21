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
			if let signature = varDecl.closureSignature(node: node, in: context) {
				return [
					  """
					  private struct GeneratedEnvironmentKey_\(raw: identifier): EnvironmentKey {
					  static let defaultValue: \(raw: signature) = \(raw: initialValue)
					  }
					  """
					  ]
			} else {
				context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("Add a function signature for better type safety")))

				return [
					 """
					 private struct GeneratedEnvironmentKey_\(raw: identifier): EnvironmentKey {
					 static let defaultValue = \(raw: initialValue)
					 }
					 """
				]
			}
		} else {
			context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("no default value ")))
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

extension VariableDeclSyntax {
	func closureSignature(node: AttributeSyntax, in context: some MacroExpansionContext) -> String? {
		guard let raw = self.bindings.first?.typeAnnotation?.description else { return nil }
		var trimmed = raw.trimmingCharacters(in: .init(charactersIn: ": "))
		
		if trimmed.contains("@Sendable") { return trimmed }
		context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("Make your closure @Sendable for improved concurrency safety")))

		if trimmed.hasPrefix("("), trimmed.hasSuffix(")") { trimmed = String(trimmed.dropFirst().dropLast()) }
		
		return "(@Sendable \(trimmed))"
	}
	
	// 	@GeneratedEnvironmentKey var actionBlock = { (int: Int) -> Int in print("Hello"); return 2 }

	/*
	func closureArgs(node: AttributeSyntax, in context: some MacroExpansionContext) -> [String]? {
		guard let parameterClause = self.bindings.first?.as(PatternBindingSyntax.self)?.initializer?.value.as(ClosureExprSyntax.self)?.signature?.parameterClause else { return nil }

		//context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("1. \(parameterClause.debugDescription)")))

	//	if parameterClause.is(ClosureShorthandParameterListSyntax.self) { return [] }
		//context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("2. \(parameterClause)")))
		//context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("3. \(parameterClause.as(ClosureParameterClauseSyntax.self)?.parameters.compactMap { $0.type?.as(IdentifierTypeSyntax.self)?.name })")))
		
		return nil
	}
	
	func closureReturnType(node: AttributeSyntax, in context: some MacroExpansionContext) -> String? {
		guard let parameterClause = self.bindings.first?.as(PatternBindingSyntax.self)?.initializer?.value.as(ClosureExprSyntax.self)?.signature?.parameterClause else { return nil }

		return nil
	}
	 */
}

extension TypeSyntax {
	var arguments: [String]? {
		guard let functionType = self.as(FunctionTypeSyntax.self) else { return nil }

		return functionType.parameters.map { "\($0)" }
	}
	
	var returnType: String? {
		guard let functionType = self.as(FunctionTypeSyntax.self) else { return nil }
		
		return "\(functionType.returnClause)".replacingOccurrences(of: "->", with: "")
	}
	
	var functionSignature: String? {
		guard let functionType = self.as(FunctionTypeSyntax.self), let arguments else { return nil }
		var result = "(" + arguments.joined() + ")"
		
		result.append("\(functionType.returnClause)")
		
		return result
	}
}

/*
 FunctionTypeSyntax
 ├─leftParen: leftParen
 ├─parameters: TupleTypeElementListSyntax
 │ ╰─[0]: TupleTypeElementSyntax
 │   ╰─type: IdentifierTypeSyntax
 │     ╰─name: identifier("Int")
 ├─rightParen: rightParen
 ╰─returnClause: ReturnClauseSyntax
	├─arrow: arrow
	╰─type: IdentifierTypeSyntax
	  ╰─name: identifier("Bool"))
 */

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
		
//		let args = varDecl.nonOptionalSyntaxType?.arguments
//		let returnType = varDecl.nonOptionalSyntaxType?.returnType
		
//		if let args, let returnType {
//			return [
//				 """
//				 get { self[GeneratedEnvironmentKey_\(raw: identifier).self].block }
//				 """,
//					"""
//					set { self[GeneratedEnvironmentKey_\(raw: identifier).self] = newValue }
//					"""
//			]
//		} else {
			return [
				 """
				 get { self[GeneratedEnvironmentKey_\(raw: identifier).self] }
				 """,
				 """
				 set { self[GeneratedEnvironmentKey_\(raw: identifier).self] = newValue }
				 """
			]
		}
//	}
}
