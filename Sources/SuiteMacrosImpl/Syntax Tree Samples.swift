//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 6/9/24.
//

import Foundation

/*
 
 PatternBindingSyntax
 ├─pattern: IdentifierPatternSyntax
 │ ╰─identifier: identifier("variable_name")
 ├─typeAnnotation: TypeAnnotationSyntax
 │ ├─colon: colon
 │ ╰─type: IdentifierTypeSyntax
 │   ╰─name: identifier("Int")
 ╰─initializer: InitializerClauseSyntax
	├─equal: equal
	╰─value: IntegerLiteralExprSyntax
	  ╰─literal: integerLiteral("7")
 
 PatternBindingSyntax
 ├─pattern: IdentifierPatternSyntax
 │ ╰─identifier: identifier("variable_name")
 ├─typeAnnotation: TypeAnnotationSyntax
 │ ├─colon: colon
 │ ╰─type: IdentifierTypeSyntax
 │   ╰─name: identifier("String")
 ╰─initializer: InitializerClauseSyntax
	├─equal: equal
	╰─value: StringLiteralExprSyntax
	  ├─openingQuote: stringQuote
	  ├─segments: StringLiteralSegmentListSyntax
	  │ ╰─[0]: StringSegmentSyntax
	  │   ╰─content: stringSegment("string contents")
	  ╰─closingQuote: stringQuote
 
 PatternBindingSyntax
 ├─pattern: IdentifierPatternSyntax
 │ ╰─identifier: identifier("optionalString")
 ╰─typeAnnotation: TypeAnnotationSyntax
	├─colon: colon
	╰─type: OptionalTypeSyntax
	  ├─wrappedType: IdentifierTypeSyntax
	  │ ╰─name: identifier("String")
	  ╰─questionMark: postfixQuestionMark
 
 PatternBindingSyntax
 ├─pattern: IdentifierPatternSyntax
 │ ╰─identifier: identifier("date_variable_name")
 ╰─initializer: InitializerClauseSyntax
	├─equal: equal
	╰─value: MemberAccessExprSyntax
	  ├─base: DeclReferenceExprSyntax
	  │ ╰─baseName: identifier("Date")
	  ├─period: period
	  ╰─declName: DeclReferenceExprSyntax
		 ╰─baseName: identifier("now")
 */
