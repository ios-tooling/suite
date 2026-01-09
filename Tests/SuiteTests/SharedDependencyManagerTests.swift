//
//  SharedDependencyManagerTests.swift
//  Suite
//
//  Created by Ben Gottlieb on 8/31/25.
//

import Testing
import Suite

class TestDependency { }

struct SharedDependencyManagerTests {
	@Test func testDefaults() throws {
		SharedDependencyManager.instance.register(TestDependency(), .default)
	}
}
