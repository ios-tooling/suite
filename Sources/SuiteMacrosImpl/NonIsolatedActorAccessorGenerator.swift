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

public struct NonisolatedContainerGenerator {
	struct Validated {
		let varDecl: VariableDeclSyntax
		let patternBinding: PatternBindingSyntax
		let identifier: String
		let optionalType: TypeSyntax?
	}

	/// Validates that the decoration sits on a `nonisolated` `var` with either an initializer
	/// or an optional type, and returns the parts the expansion functions need. Emits diagnostics
	/// and returns nil on any failure so both PeerMacro and AccessorMacro can short-circuit
	/// without leaving half-generated code behind.
	static func validate(node: AttributeSyntax, declaration: some DeclSyntaxProtocol, context: some MacroExpansionContext) -> Validated? {
		guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.notVariableSyntax))
			return nil
		}

		guard let patternBinding = varDecl.bindings.first else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.missingAnnotation))
			return nil
		}

		guard let identifier = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
			context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.notAnIdentifier))
			return nil
		}

		// Iterate the full modifier list — `public nonisolated` must be detected as well as bare `nonisolated`.
		let hasNonisolatedKeyword = varDecl.modifiers.contains { $0.name.text.lowercased() == "nonisolated" }
		guard hasNonisolatedKeyword else {
			context.diagnose(Diagnostic(node: Syntax(declaration), message: MacroFeedback.error("Please add the `nonisolated` annotation to the variable declaration")))
			return nil
		}

		let optionalType = varDecl.optionalSyntaxType
		if patternBinding.initializer == nil && optionalType == nil {
			context.diagnose(Diagnostic(node: Syntax(declaration), message: MacroFeedback.error("`@NonisolatedContainer` requires either an initializer or an optional type")))
			return nil
		}

		return Validated(varDecl: varDecl, patternBinding: patternBinding, identifier: identifier, optionalType: optionalType)
	}
}

extension NonisolatedContainerGenerator: PeerMacro {
	public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
		guard let v = validate(node: node, declaration: declaration, context: context) else { return [] }

		let accessorName = "private nonisolated let nonIsolatedBackingContainer_\(v.identifier)"

		if let initializer = v.patternBinding.initializer {
			let trimmedInitializer = initializer.value
			if let optionalType = v.optionalType {
				return ["\(raw: accessorName): ThreadsafeMutex<\(raw: optionalType)?> = .init(\(trimmedInitializer))"]
			} else {
				return ["\(raw: accessorName) = ThreadsafeMutex(\(trimmedInitializer))"]
			}
		}

		// No initializer — must be optional (validated).
		if let optionalType = v.optionalType {
			return ["\(raw: accessorName): ThreadsafeMutex<\(raw: optionalType)?> = .init(nil)"]
		}
		return []
	}
}

extension NonisolatedContainerGenerator: AccessorMacro {
	public static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
		// Validation runs in PeerMacro too; we re-check here so a failed validation suppresses both
		// peers and accessors, avoiding "cannot find nonIsolatedBackingContainer_X" cascade errors.
		// Diagnostics are emitted by PeerMacro; we silently bail here.
		guard let v = silentValidate(node: node, declaration: declaration) else { return [] }

		let publishChanges = observingFlag(from: node)

		return [
			"""
			get { nonIsolatedBackingContainer_\(raw: v.identifier).value }
			""",
			publishChanges ?
				"""
				set { nonIsolatedBackingContainer_\(raw: v.identifier).value = newValue; objectWillChange.sendOnMain() }
				"""
				:
				"""
				set { nonIsolatedBackingContainer_\(raw: v.identifier).value = newValue }
				"""
		]
	}

	/// Same checks as `validate` but without diagnostics — used by AccessorMacro to avoid emitting
	/// a duplicate copy of every diagnostic the PeerMacro already emitted on the same site.
	private static func silentValidate(node: AttributeSyntax, declaration: some DeclSyntaxProtocol) -> Validated? {
		guard let varDecl = declaration.as(VariableDeclSyntax.self) else { return nil }
		guard let patternBinding = varDecl.bindings.first else { return nil }
		guard let identifier = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { return nil }
		guard varDecl.modifiers.contains(where: { $0.name.text.lowercased() == "nonisolated" }) else { return nil }
		let optionalType = varDecl.optionalSyntaxType
		if patternBinding.initializer == nil && optionalType == nil { return nil }
		return Validated(varDecl: varDecl, patternBinding: patternBinding, identifier: identifier, optionalType: optionalType)
	}

	/// Look up the `observing:` argument by label, not by position. The macro only declares a
	/// single argument today, but matching by label keeps this robust if more are added.
	private static func observingFlag(from node: AttributeSyntax) -> Bool {
		guard let args = node.arguments?.as(LabeledExprListSyntax.self) else { return false }
		for arg in args where arg.label?.text == "observing" {
			if let lit = arg.expression.as(BooleanLiteralExprSyntax.self) {
				return lit.literal.text.lowercased() == "true"
			}
		}
		return false
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
