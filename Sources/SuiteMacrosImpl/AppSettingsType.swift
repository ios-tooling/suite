//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 6/9/24.
//

import Foundation

indirect enum AppSettingsType { case string, bool, integer, double, float, data, date, uuid, other(String), optional(AppSettingsType)
	var declaration: String {
		switch self {
		case .string: "String"
		case .bool: "Bool"
		case .integer: "Int"
		case .double: "Double"
		case .float: "Float"
		case .data: "Data"
		case .date: "Date"
		case .uuid: "UUID"
		case .other(let name): "\(name)"
		case .optional(let type): "\(type.declaration)?"
		}
	}
	
	var canBeOptional: Bool {
		switch self {
		case .string, .data, .date, .other: true
		default: false
		}
	}

	var accessorName: String {
		switch self {
		case .string: "string"
		case .bool: "bool"
		case .integer: "int"
		case .double: "double"
		case .float: "float"
		case .data: "data"
		case .date: "date"
		case .uuid: "uuid"
		case .optional(let kind): kind.accessorName
		case .other: "object"
		}
	}

	var setterName: String {
		switch self {
		case .string: "setString"
		case .bool: "setBool"
		case .integer: "setInt"
		case .double: "setDouble"
		case .float: "setFloat"
		case .data: "setData"
		case .date: "setDate"
		case .uuid: "setUUID"
		case .optional(let kind): kind.setterName
		case .other: "setObject"
		}
	}

	var optionalized: AppSettingsType { .optional(self) }
	
	init(rawValue: String) {
		switch rawValue {
		case "String": self = .string
		case "Bool": self = .bool
		case "Int": self = .integer
		case "Double": self = .double
		case "Float": self = .float
		case "Data": self = .data
		case "Date": self = .date
		case "UUID": self = .uuid
		default: self = .other(rawValue)
		}
	}
}

