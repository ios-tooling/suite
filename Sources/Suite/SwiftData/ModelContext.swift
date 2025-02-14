//
//  ModelContext.swift
//  Suite
//
//  Created by Ben Gottlieb on 11/29/24.
//

import Foundation
import SwiftData

@available(iOS 17, macOS 14, watchOS 10, *)
public protocol PresavablePersistentModel: PersistentModel {
	func presave()
}

@available(iOS 17, macOS 14, watchOS 10, *)
public extension ModelContext {
	func presave() {
		for model in changedModelsArray {
			(model as? any PresavablePersistentModel)?.presave()
		}
	}

	func reportedSave() {
		presave()
		do {
			try save()
		} catch {
			SuiteLogger.error("Failed to save database \(error, privacy: .public)")
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
