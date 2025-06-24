//
//  Error.swift
//  
//
//  Created by Ben Gottlieb on 8/1/21.
//

import Foundation

public typealias ErrorCallback = (Error?) -> Void

public protocol DisplayableError: Error {
	var errorTitle: String { get }
	var errorMessage: String { get }
}

public extension Error {
	var isFileNotFound: Bool {
		let error = self as NSError
		
		return error.domain == NSCocoaErrorDomain && error.code == 260
	}
	
	var isCancellation: Bool {
        if self is CancellationError { return true }
        
		let error = self as NSError
		
		return error.code == 1001
	}
	
	var decodingDescription: String? {
		guard let error = self as? DecodingError else { return nil }
		
		return switch error {
		case .typeMismatch(let key, let context):
			"Type Mismatch \(key), path: \(context.pathDescription)"
		case .valueNotFound(let key, let context):
			"Value not Found error \(key), path: \(context.pathDescription)"
		case .keyNotFound(let key, let context):
			"Key not Found error \(key), path: \(context.pathDescription)"
		case .dataCorrupted(let key):
			"error \(key): \(error.localizedDescription)"
		default:
			"ERROR: \(error.localizedDescription)"
		}
	}
}

extension DecodingError.Context {
	var pathDescription: String {
		return codingPath.map( {
			if let index = $0.intValue {
				"[\(index)]"
			} else {
				$0.stringValue
			}
		}).joined(separator: ", ")
	}
}
