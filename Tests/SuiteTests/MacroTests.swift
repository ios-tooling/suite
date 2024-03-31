//
//  MacroTests.swift
//  
//
//  Created by Ben Gottlieb on 3/30/24.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import Suite
import SuiteMacrosImpl

let testMacros: [String: Macro.Type] = [
	"GeneratedPreferenceKey": PreferenceKeyGenerator.self
]

extension PreferenceValues {
	#GeneratedPreferenceKey(name: "Test", type: String?)
}

final class MacroTests: XCTestCase {
	func testPreferenceKey() {
		assertMacroExpansion(
"""
extension PreferenceValues {
	#GeneratedPreferenceKey(name: "Test", type: String?)
}
""", expandedSource:
"""
extension PreferenceValues {
	struct GeneratedPreferenceKey_Test: PreferenceKey {

		static func reduce(value: inout String?, nextValue: () -> String?) {
				preferenceReduce(value: &value, nextValue: nextValue)
			}
	}
	var Test: GeneratedPreferenceKey_Test.Type {
		GeneratedPreferenceKey_Test.self
	}
}
""", macros: testMacros, indentationWidth: .tab)
	}
}
