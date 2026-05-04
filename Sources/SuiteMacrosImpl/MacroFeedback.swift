//
//  MacroFeedback.swift
//
//
//  Created by Ben Gottlieb on 3/16/24.
//

import SwiftSyntax
import SwiftDiagnostics

enum MacroFeedback: DiagnosticMessage, Error {
	case noDefaultArgument
	case missingAnnotation
	case notAnIdentifier
	case notVariableSyntax
	case message(String)
	case error(String)

	var severity: DiagnosticSeverity {
		switch self {
		case .noDefaultArgument, .missingAnnotation, .notAnIdentifier, .notVariableSyntax, .error: .error
		case .message: .warning
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

	private var stableID: String {
		switch self {
		case .noDefaultArgument: "noDefaultArgument"
		case .missingAnnotation: "missingAnnotation"
		case .notAnIdentifier: "notAnIdentifier"
		case .notVariableSyntax: "notVariableSyntax"
		case .message: "message"
		case .error: "error"
		}
	}

	var diagnosticID: MessageID {
		MessageID(domain: "SuiteMacros", id: stableID)
	}
}
