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
		
//		context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("\(varDecl.nonOptionalSyntaxType)")))
//		context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("\(varDecl.nonOptionalSyntaxType?.functionSignature)")))

		let args = varDecl.nonOptionalSyntaxType?.arguments
		let returnType = varDecl.nonOptionalSyntaxType?.returnType
		
		if patternBinding.isVoidClosure, let initialValue = patternBinding.initializer?.value {
			if let args, let returnType {
				context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("Closure args: \(args), return type: \(returnType))")))
				return [
					  """
					  private struct GeneratedEnvironmentKey_\(raw: identifier): EnvironmentKey {
					  static let defaultValue = BlockWrapper<\(raw: args[0]), \(raw: returnType)>\(raw: initialValue)
					  }
					  """
					  ]
			} else {
				context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("1. \(varDecl.bindings.first?.as(PatternBindingSyntax.self)?.initializer?.value.as(ClosureExprSyntax.self)?.signature?.parameterClause)")))
				context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("2. \(varDecl.bindings.first?.as(PatternBindingSyntax.self)?.initializer?.value.as(ClosureExprSyntax.self)?.signature?.parameterClause?.as(ClosureParameterClauseSyntax.self)?.parameters.compactMap { $0.type?.as(IdentifierTypeSyntax.self)?.name })")))
				return [
					 """
					 private struct GeneratedEnvironmentKey_\(raw: identifier): EnvironmentKey {
					 static let defaultValue = BlockWrapper \(raw: initialValue)
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

// 	@GeneratedEnvironmentKey var actionBlock = { (int: Int) -> Int in print("Hello"); return 2 }


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
		
		let args = varDecl.nonOptionalSyntaxType?.arguments
		let returnType = varDecl.nonOptionalSyntaxType?.returnType
		
		if let args, let returnType {
			return [
				 """
				 get { self[GeneratedEnvironmentKey_\(raw: identifier).self].block }
				 """,
					"""
					set { self[GeneratedEnvironmentKey_\(raw: identifier).self] = BlockWrapper<\(raw: args[0]), \(raw: returnType)>(block: newValue) }
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
