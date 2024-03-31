//
//  PreferenceKeyGenerator.swift
//
//
//  Created by Ben Gottlieb on 3/16/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

public enum PreferenceKeyGenerator: DeclarationMacro {
  public static func expansion(
	 of node: some FreestandingMacroExpansionSyntax,
	 in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
	  guard let keyName = name(from: node) else {
		  context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.error("Please provide a name for this key (as a string).")))
		  return []
	  }
	  guard let keyType = type(from: node) else {
		  context.diagnose(Diagnostic(node: Syntax(node), message: MacroFeedback.error("Please provide a type for this key (as a raw type).")))
		  return []
	  }
	  
	  let keyTypeName = "GeneratedPreferenceKey_\(keyName)"
	  return [
"""
struct \(raw: keyTypeName): PreferenceKey {
static func reduce(value: inout \(raw: keyType), nextValue: () -> \(raw: keyType)) {
	//value
}
}
var \(raw: keyName): \(raw: keyTypeName).Type {
	\(raw: keyTypeName).self
}
"""
	 ]
  }
	
	static func type(from node: some FreestandingMacroExpansionSyntax) -> String? {
		let args = node.argumentList.children(viewMode: .sourceAccurate)
		
		guard let segment = args[args.index(after: args.startIndex)].as(LabeledExprSyntax.self)?.expression else { return nil }
		
		return segment.description
	}
	
	static func name(from node: some FreestandingMacroExpansionSyntax) -> String? {
		guard let segment = node.argumentList.first?.as(LabeledExprSyntax.self)?.expression.as(StringLiteralExprSyntax.self)?.segments.first?.as(StringSegmentSyntax.self) else { return nil }
		
		return segment.description
	}
}
