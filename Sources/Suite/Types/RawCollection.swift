//
//  RawCollection.swift
//  
//
//  Created by Ben Gottlieb on 1/27/23.
//

import Foundation

public protocol StringInitializable: Hashable {
	init?(rawValue: String)
	var stringValue: String { get }
}
