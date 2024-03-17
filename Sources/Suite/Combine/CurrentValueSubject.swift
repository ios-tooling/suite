//
//  CurrentValueSubject.swift
//
//
//  Created by Ben Gottlieb on 3/16/24.
//

import Combine

extension CurrentValueSubject: @unchecked Sendable { }

public extension CurrentValueSubject where Failure == Never {
	convenience init(value: Output) {
		self.init(value)
	}
	
	static func initial(_ value: Output) -> Self {
		.init(value: value)
	}
}

