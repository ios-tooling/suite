//
//  MacroTests.swift
//
//
//  Created by Ben Gottlieb on 3/30/24.
//

import Testing
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
@testable import SuiteMacrosImpl

private let macros: [String: MacroSpec] = [
	"GeneratedPreferenceKey": MacroSpec(type: PreferenceKeyGenerator.self),
	"NonisolatedContainer": MacroSpec(type: NonisolatedContainerGenerator.self),
]

private func expand(
	_ source: String,
	expandsTo expected: String,
	diagnostics: [DiagnosticSpec] = [],
	indentationWidth: Trivia = .spaces(4),
	sourceLocation: Testing.SourceLocation = #_sourceLocation
) {
	assertMacroExpansion(
		source,
		expandedSource: expected,
		diagnostics: diagnostics,
		macroSpecs: macros,
		indentationWidth: indentationWidth,
		failureHandler: { failure in
			Issue.record(
				Comment(rawValue: failure.message),
				sourceLocation: sourceLocation
			)
		}
	)
}

@Suite struct PreferenceKeyMacroTests {
	@Test func generatesPreferenceKeyWithDefault() {
		expand(
			"""
			#GeneratedPreferenceKey(name: "ItemHeight", type: CGFloat.self, defaultValue: 0)
			""",
			expandsTo: """
			struct GeneratedPreferenceKey_ItemHeight: PreferenceKey {
			    static let defaultValue: CGFloat = 0
			    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
			        preferenceReduce(value: &value, nextValue: nextValue)
			    }
			}
			var ItemHeight: GeneratedPreferenceKey_ItemHeight.Type {
			    GeneratedPreferenceKey_ItemHeight.self
			}
			"""
		)
	}

	@Test func generatesOptionalKeyWithoutDefault() {
		expand(
			"""
			#GeneratedPreferenceKey(name: "Selection", type: String?.self)
			""",
			expandsTo: """
			struct GeneratedPreferenceKey_Selection: PreferenceKey {

			    static func reduce(value: inout String?, nextValue: () -> String?) {
			        preferenceReduce(value: &value, nextValue: nextValue)
			    }
			}
			var Selection: GeneratedPreferenceKey_Selection.Type {
			    GeneratedPreferenceKey_Selection.self
			}
			"""
		)
	}

	@Test func diagnoseInvalidIdentifier() {
		expand(
			"""
			#GeneratedPreferenceKey(name: "my key", type: Int.self, defaultValue: 0)
			""",
			expandsTo: """
			""",
			diagnostics: [
				DiagnosticSpec(message: "`my key` is not a valid Swift identifier.", line: 1, column: 1)
			]
		)
	}

	@Test func diagnoseMissingDefaultForNonOptional() {
		expand(
			"""
			#GeneratedPreferenceKey(name: "Count", type: Int.self)
			""",
			expandsTo: """
			""",
			diagnostics: [
				DiagnosticSpec(message: "Non-optional types must provide a defaultValue", line: 1, column: 1)
			]
		)
	}
}

@Suite struct NonisolatedContainerMacroTests {
	@Test func generatesBackingContainerForNonOptional() {
		expand(
			"""
			class C {
				@NonisolatedContainer
				nonisolated var count: Int = 0
			}
			""",
			expandsTo: """
			class C {
				nonisolated var count: Int {
				    get {
				        nonIsolatedBackingContainer_count.value
				    }
				    set {
				        nonIsolatedBackingContainer_count.value = newValue
				    }
				}

				private nonisolated let nonIsolatedBackingContainer_count = ThreadsafeMutex(0)
			}
			"""
		)
	}

	@Test func generatesBackingContainerForOptional() {
		expand(
			"""
			class C {
				@NonisolatedContainer
				nonisolated var name: String?
			}
			""",
			expandsTo: """
			class C {
				nonisolated var name: String? {
				    get {
				        nonIsolatedBackingContainer_name.value
				    }
				    set {
				        nonIsolatedBackingContainer_name.value = newValue
				    }
				}

				private nonisolated let nonIsolatedBackingContainer_name: ThreadsafeMutex<String?> = .init(nil)
			}
			"""
		)
	}

	@Test func observingTrueAddsObjectWillChange() {
		expand(
			"""
			class C {
				@NonisolatedContainer(observing: true)
				nonisolated var count: Int = 0
			}
			""",
			expandsTo: """
			class C {
				nonisolated var count: Int {
				    get {
				        nonIsolatedBackingContainer_count.value
				    }
				    set {
				        nonIsolatedBackingContainer_count.value = newValue;
				        objectWillChange.sendOnMain()
				    }
				}

				private nonisolated let nonIsolatedBackingContainer_count = ThreadsafeMutex(0)
			}
			"""
		)
	}

	@Test func diagnoseMissingNonisolated() {
		// Validation suppresses both peer and accessor expansion when `nonisolated` is missing,
		// so the declaration is left unmodified.
		expand(
			"""
			class C {
				@NonisolatedContainer
				var count: Int = 0
			}
			""",
			expandsTo: """
			class C {
				var count: Int = 0
			}
			""",
			diagnostics: [
				DiagnosticSpec(message: "Please add the `nonisolated` annotation to the variable declaration", line: 2, column: 2)
			]
		)
	}

	@Test func diagnoseNonOptionalWithoutInitializer() {
		// Same: bail out without expanding when there's no seed value.
		expand(
			"""
			class C {
				@NonisolatedContainer
				nonisolated var count: Int
			}
			""",
			expandsTo: """
			class C {
				nonisolated var count: Int
			}
			""",
			diagnostics: [
				DiagnosticSpec(message: "`@NonisolatedContainer` requires either an initializer or an optional type", line: 2, column: 2)
			]
		)
	}
}
