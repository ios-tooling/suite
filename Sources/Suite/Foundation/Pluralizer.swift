//
//  Pluralizer.swift
//  
//
//  Created by Ben Gottlieb on 12/18/20.
//

import Foundation


public final class Pluralizer: Sendable {
	public static let instance = Pluralizer()
	
	init() {
		
	}
	
	nonisolated let plurals: CurrentValueSubject<[String: String], Never> = .init([:])
	
	public nonisolated func pluralize(_ count: Int, _ singular: String, spelledOut: Bool = false) -> String {
		if count == 1 { return "1 " + singular }
		return "\(count) \(self[singular])"
	}
	
	public nonisolated subscript(singular: String) -> String {
		get {
			if let plural = plurals.value[singular.lowercased()] { return plural }
			
			if singular.hasSuffix("s") { return singular }
			return singular + "s"
		}
		
		set {
			plurals.value[singular.lowercased()] = newValue
		}
	}
}
