//
//  CollectionDifference.swift
//  
//
//  Created by Ben Gottlieb on 11/25/20.
//

import Foundation

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension CollectionDifference {
	var inserted: [ChangeElement] {
		self.compactMap { diff in
			switch diff {
			case .insert(_, let item, _): return item
			default: return nil
			}
		}
	}

	var removed: [ChangeElement] {
		self.compactMap { diff in
			switch diff {
			case .remove(_, let item, _): return item
			default: return nil
			}
		}
	}
}
