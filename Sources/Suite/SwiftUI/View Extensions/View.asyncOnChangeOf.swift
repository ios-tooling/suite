//
//  View.asyncOnChangeOf.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/5/25.
//

import SwiftUI

@available(iOS 17.0, macOS 14, watchOS 10, *)
public extension View {
	@ViewBuilder func asyncOnChangeOf<T: Equatable>(of value: T, initial: Bool = false, file: StaticString = #file, line: UInt = #line, perform action: @escaping () async throws -> ()) -> some View {
		onChange(of: value, initial: initial) {
			Task {
				do {
					try await action()
				} catch {
					print("asyncOnChange of failed, \(file):\(line): \(error)")
				}
			}
		}
	}
}
