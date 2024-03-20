//
//  MacroFeedback.swift
//  
//
//  Created by Ben Gottlieb on 3/16/24.
//

import SwiftSyntax
import SwiftDiagnostics

enum MacroFeedback: String, DiagnosticMessage {
	 case noDefaultArgument, missingAnnotation, notAnIdentifier, notVariableSyntax

	 var severity: DiagnosticSeverity { return .error }

	 var message: String {
		  switch self {
		  case .noDefaultArgument: "Missing default value."
		  case .missingAnnotation: "Missing annotation."
		  case .notAnIdentifier: "Invalid identifier."
		  case .notVariableSyntax: "Invalid syntax"
		  }
	 }

	 var diagnosticID: MessageID {
		  MessageID(domain: "SuiteMacros", id: rawValue)
	 }
}
