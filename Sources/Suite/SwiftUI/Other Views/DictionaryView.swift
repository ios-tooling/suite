//
//  DictionaryView.swift
//  Suite
//
//  Created by Ben Gottlieb on 8/18/25.
//

import SwiftUI

fileprivate let indentSize = 12.0

@available(macOS 12.0, iOS 14, watchOS 9, *)
public struct DictionaryView<Key: Hashable>: View {
	let dictionary: [Key: Any]
	fileprivate let lines: [LineInfo]

	public init(dictionary dict: [Key: Any], excluding: [String] = []) {
		dictionary = dict
		lines = LineInfo.build(from: dict, excluding: excluding).sorted()
	}
	
	public var body: some View {
		VStack(alignment: .leading) {
			
			ForEach(lines.indices, id: \.self) { index in
				let line = lines[index]
				
				Row(label: line.label, value: line.value)
					.padding(.leading, line.offset)
					.background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.1))
			}
		}
	}
}

@available(macOS 12.0, iOS 14, watchOS 9, *)
fileprivate struct Row: View {
	let label: String
	let value: Any
	
	var body: some View {
		HStack {
			VStack {
				HStack {
					Text(label)
						.bold()
					//Text(path).opacity(0.5)

					Spacer()
					if value is [AnyHashable: Any] {
						Image(systemName: "chevron.down")
							.imageScale(.small)
							.opacity(0.5)
					} else {
						Text(String(describing: value))
					}
				}
			}
		}
	}
}

fileprivate struct LineInfo: Comparable, Equatable, Identifiable {
	let key: Any
	let label: String
	let path: String
	var id: String { label + "\(indent)" }
	let value: Any
	let indent: Int
	var offset: Double { Double(indent) * indentSize }
	
	static func <(lhs: Self, rhs: Self) -> Bool { lhs.path < rhs.path }
	static func ==(lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
	
	init(_ key: Any, value: Any, indent: Int, path: String) {
		self.key = key
		self.value = value
		self.indent = indent
		self.path = path

		self.label = String(describing: key)
	}

	static func build(from dict: [AnyHashable: Any], indent: Int = 0, path: String = "", excluding: [String]) -> [Self] {
		var results: [Self] = []
		
		for (key, value) in dict {
			let keyLabel = String(describing: key)
			if excluding.contains(keyLabel) { continue }
			results += Self.build(from: key, value: value, indent: indent + 1, path: path + "/" + keyLabel, excluding: excluding)
		}
		return results

	}
	
	static func build(from key: Any, value: Any, indent: Int, path: String, excluding: [String]) -> [Self] {
		if let dict = value as? [AnyHashable: Any] {
			return [LineInfo(key, value: value, indent: indent, path: path)] + build(from: dict, indent: indent + 1, path: path, excluding: excluding)
		} else {
			return [LineInfo(key, value: value, indent: indent, path: path)]
		}
	}
}

#Preview {
	let subSubDict = ["black": 1, "white": 3, "red": 6]
	let subDict = ["black": true, "white": true, "red": true, "innie": subSubDict]
	if #available(macOS 12.0, iOS 14, watchOS 9, *) {
		DictionaryView(dictionary: [
			"1": 45,
			"graphene": "hello",
			"3": [1, 2, 3],
			"ambi": "dextrous",
			"zebra": subDict,
		])
		.padding(30)
	}
}
