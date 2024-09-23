//
//  JSON Types.swift
//  Suite
//
//  Created by Ben Gottlieb on 9/23/24.
//

import Foundation

public typealias JSONRequirements = Codable & Sendable & Hashable
public protocol JSONDataType: JSONRequirements { }

extension String: JSONDataType { }
extension Bool: JSONDataType { }
extension Int: JSONDataType { }
extension Double: JSONDataType { }
extension Date: JSONDataType { }
extension Data: JSONDataType { }
extension Dictionary: JSONDataType where Key == String, Value: JSONDataType { }
extension Array: JSONDataType where Element: JSONDataType { }

public typealias JSONDictionary = [String: (any JSONRequirements)]

