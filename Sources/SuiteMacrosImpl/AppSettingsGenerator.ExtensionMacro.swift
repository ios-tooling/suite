//
//  AppSettingsGenerator.ExtensionMacro.swift
//
//
//  Created by Ben Gottlieb on 6/9/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics


extension AppSettingsGenerator: ExtensionMacro {
	public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		
		guard declaration.as(ClassDeclSyntax.self) != nil else {
			throw MacroFeedback.error("Macro `AppSettings` can only be applied to a class")
		}
		
		var results: [ExtensionDeclSyntax] = []

		/*
		 LabeledExprListSyntax
		 ╰─[0]: LabeledExprSyntax
			├─label: identifier("group")
			├─colon: colon
			╰─expression: StringLiteralExprSyntax
			  ├─openingQuote: stringQuote
			  ├─segments: StringLiteralSegmentListSyntax
			  │ ╰─[0]: StringSegmentSyntax
			  │   ╰─content: stringSegment("group.com.standalone.prometheus")
			  ╰─closingQuote: stringQuote
		 */

		results.append(try userDefaultsDecl(type: type, suiteName: node.arguments?.trimmedDescription))
		results.append(try ExtensionDeclSyntax("extension \(type.trimmed): ObservableObject, UserDefaultsContainer {}"))

//		context.diagnose(Diagnostic(node: node, message: MacroFeedback.message(node.arguments!.trimmedDescription.debugDescription ?? "--")))
		return results
	}
	

	
	static func userDefaultsDecl(type: some SwiftSyntax.TypeSyntaxProtocol, suiteName: String?) throws -> ExtensionDeclSyntax {
		if let suiteName, !suiteName.isEmpty {
			return ExtensionDeclSyntax(extendedType: type, memberBlock: try MemberBlockSyntax {
				try VariableDeclSyntax(
	 """
	  public nonisolated var userDefaults: UserDefaults { UserDefaults(suiteName: \(raw: suiteName)) ?? .standard }
	 """
			) })
		} else {
			return ExtensionDeclSyntax(extendedType: type, memberBlock: try MemberBlockSyntax {
				try VariableDeclSyntax(
"""
	 public nonisolated var userDefaults: UserDefaults { .standard }
"""
			) })
		}
	}
}

