//
//  File.swift
//  Suite
//
//  Created by Ben Gottlieb on 10/28/24.
//

import Foundation
import Swift


@available(iOS 17.0, macOS 14, watchOS 9, *)
public struct SlogButton: View {
	public init() { }
	
	@State private var isShowingLogs = false
	
	public var body: some View {
		Button("Logs") {
			isShowingLogs.toggle()
		}
		.sheet(isPresented: $isShowingLogs) {
			SlogScreen()
		}
	}
}
