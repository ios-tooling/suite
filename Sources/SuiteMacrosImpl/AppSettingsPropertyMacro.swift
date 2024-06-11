//
//  AppSettingsPropertyMacro.swift
//  
//
//  Created by Ben Gottlieb on 6/9/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct AppSettingsPropertyMacro: AccessorMacro {
	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AccessorDeclSyntax] {
		
		
		guard let variableDecl = declaration.as(VariableDeclSyntax.self),
				let patternBinding = variableDecl.bindings.as(PatternBindingListSyntax.self)?.first?.as(PatternBindingSyntax.self) else {
			
			context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("no pattern binding found.")))
			
			return []
		}
		
		guard let variableName = patternBinding.token?.strippedText else {
			context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("Variable name not found")))
			
			return []
		}
//		guard var identifier = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
//			
//			context.diagnose(Diagnostic(node: node, message: MacroFeedback.message("no identifier binding found.")))
//			
//			return []
//		}
		guard let varType = patternBinding.type else {
			context.diagnose(Diagnostic(node: node, message: MacroFeedback.message(patternBinding.description)))
			
			return []
		}

		return [
			AccessorDeclSyntax(stringLiteral: getterString(for: varType, variableName: variableName, initializer: patternBinding.initializer?.literalStringValue)),

			AccessorDeclSyntax(stringLiteral: setterString(for: varType, variableName: variableName, initializer: patternBinding.initializer?.literalStringValue)),
		]
		
	}
	
	
	static func getterString(for type: AppSettingsType, variableName: String, initializer: String?) -> String {
		if let initializer {
			if type.canBeOptional {
 """
  get { \(type.accessorName)(for: "\(variableName)") ?? \(initializer) }
 """
			} else {
  """
  get { hasValue(for: \"\(variableName)\") ? \(type.accessorName)(for: "\(variableName)") : \(initializer) }
  """
			}
		} else {
  """
  get { \(type.accessorName)(for: "\(variableName)") }
  """
		}
	}

	static func setterString(for type: AppSettingsType, variableName: String, initializer: String?) -> String {
		"""
			set { 
				objectWillChange.send()
				\(type.setterName)(newValue, for: "\(variableName)")
			}
		"""
	}

}
