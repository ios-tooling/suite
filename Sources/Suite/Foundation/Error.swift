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
}
