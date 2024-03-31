//
//  MacroFeedback.swift
//  
//
//  Created by Ben Gottlieb on 3/16/24.
//

import SwiftSyntax
import SwiftDiagnostics

enum MacroFeedback: DiagnosticMessage {
	 case noDefaultArgument, missingAnnotation, notAnIdentifier, notVariableSyntax
	 case message(String)
	 case error(String)

	var severity: DiagnosticSeverity {
		switch self {
		case .message: .warning
		case .error: .error
		default: .error
		}
	}

	 var message: String {
		  switch self {
		  case .noDefaultArgument: "Missing default value."
		  case .missingAnnotation: "Missing annotation."
		  case .notAnIdentifier: "Invalid identifier."
		  case .notVariableSyntax: "Invalid syntax"
		  case .message(let msg): msg
		  case .error(let msg): msg
		  }
	 }

	 var diagnosticID: MessageID {
		  MessageID(domain: "SuiteMacros", id: message)
	 }
}
