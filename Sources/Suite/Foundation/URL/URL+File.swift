//
//  URL+File.swift
//
//
//  Created by Ben Gottlieb on 12/30/19.
//

import Foundation
import UniformTypeIdentifiers

public extension URL {
	var isDirectory: Bool {
		var isDirectory: ObjCBool = false
		if !FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) { return false }
		return isDirectory.boolValue
	}

	var isFile: Bool {
		var isDirectory: ObjCBool = false
		if !FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) { return false }
		return !isDirectory.boolValue
	}

	var existsOnDisk: Bool {
		if !self.isFileURL { return false }
		return FileManager.default.fileExists(at: self)
	}

	var existingDirectory: URL? {
		if !isFileURL { return nil }

		if FileManager.default.directoryExists(at: self) { return self }

		do {
			try FileManager.default.createDirectory(at: self, withIntermediateDirectories: true, attributes: nil)
			return self
		} catch {
			Suite.logg(error: error, "Unable to create directory at \(path)")
			return nil
		}
	}

	var fileSize: Int64 { FileManager.default.fileSize(at: self) }

	var fileAttributes: [FileAttributeKey: Any]? {
		guard self.isFileURL else { return nil }
		return (try? FileManager.default.attributesOfItem(atPath: path)) ?? [:]
	}

	var createdAt: Date? {
		fileAttributes?[.creationDate] as? Date
	}

	var modifiedAt: Date? {
		get { fileAttributes?[.modificationDate] as? Date }
		nonmutating set {
			guard let newValue else { return }
			do {
				try FileManager.default.setAttributes([.modificationDate: newValue], ofItemAtPath: path)
			} catch {
				logg("Failed to set modification date: \(error)")
			}
		}
	}

	@available(iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 16, *)
	var fileType: UTType? {
		let nsURL = self as NSURL
		var object: AnyObject?
		try? nsURL.getResourceValue(&object, forKey: .contentTypeKey)
		return object as? UTType
	}
}

public extension Array where Element == URL {
	func sortedChronologically(oldestFirst: Bool = false) -> [Element] {
		self.sorted {
			guard let d1 = $0.createdAt else { return oldestFirst }
			guard let d2 = $1.createdAt else { return !oldestFirst }

			if oldestFirst { return d1 < d2 }
			return d1 > d2
		}
	}
}
