//
//  JSONEncoder.swift
//  Suite
//
//  Created by Ben Gottlieb on 6/11/25.
//

import Foundation

public extension JSONEncoder {
	static let `default`: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [ .sortedKeys ]
		return encoder
	}()
	
	static let debug: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [ .withoutEscapingSlashes, .prettyPrinted, .sortedKeys ]
		return encoder
	}()
}

@available(iOS 10.0, *)
public extension JSONEncoder {
	static let iso8601Encoder: JSONEncoder = {
		let encoder = JSONEncoder.default
		
		encoder.dateEncodingStrategy = .iso8601
		return encoder
	}()
}

extension JSONEncoder.DateEncodingStrategy {
	public var decodingStrategy: JSONDecoder.DateDecodingStrategy {
		  switch self {
		  case .deferredToDate: return .deferredToDate
		  case .secondsSince1970: return .secondsSince1970
		  case .millisecondsSince1970: return .millisecondsSince1970
		  case .iso8601: return .iso8601
		  default: return .default
		  }
	 }
}
