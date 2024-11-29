//
//  ModelContext.swift
//  Suite
//
//  Created by Ben Gottlieb on 11/29/24.
//

import Foundation
import SwiftData


@available(iOS 17, macOS 14, *)
public extension ModelContext {
	func reportedSave() {
		do {
			try save()
		} catch {
			print("Failed to save database: \(error)")
		}
	}
	
	func allModels<T: PersistentModel>(matching predicate: Predicate<T>? = nil, sortedBy: [SortDescriptor<T>]? = nil) -> [T] {
		var descriptor = FetchDescriptor<T>()
		if let predicate {
			descriptor.predicate = predicate
		}
		if let sortedBy {
			descriptor.sortBy = sortedBy
		}
		return (try? fetch(descriptor)) ?? []
	}

	func countModels<T: PersistentModel>(_ modelType: T) -> Int {
		let descriptor = FetchDescriptor<T>()
		return (try? fetch(descriptor).count) ?? 0
	}

}
