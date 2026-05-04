//
//  Identifiable.swift
//  
//
//  Created by Ben Gottlieb on 6/6/20.
//

import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public extension Array where Element: Identifiable {
	/// Read or replace the element with `id`. Setting to `nil` removes the element if present;
	/// setting a non-nil value when no element with `id` exists **appends** the new value.
	subscript(id id: Element.ID) -> Element? {
		get {
			guard let index = self.firstIndex(where: { $0.id == id }) else { return nil }
			return self[index]
		}

		set {
			if let index = self.firstIndex(where: { $0.id == id }) {
				if let element = newValue {
					self[index] = element
				} else {
					self.remove(at: index)
				}
			} else if let element = newValue {
				self.append(element)
			}
		}
	}
}

// Note: making primitives Identifiable lets them be used directly with `ForEach`, but duplicate
// values share an ID — diffing/animation will misbehave when the array contains duplicates.
extension String: @retroactive Identifiable {
	public var id: Self { self }
}

extension Int: @retroactive Identifiable {
	public var id: Self { self }
}

extension Double: @retroactive Identifiable {
	public var id: Self { self }
}

extension Float: @retroactive Identifiable {
	public var id: Self { self }
}
