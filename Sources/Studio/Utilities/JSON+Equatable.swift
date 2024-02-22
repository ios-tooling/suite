//
//  JSON+Equatable.swift
//
//
//  Created by Ben Gottlieb on 2/22/24.
//

import Foundation

fileprivate extension Dictionary where Key == String {
	var sortedKeys: [String] { keys.map { $0 }.sorted() }
}

public func compareTwoJSONValues(lValue: Any?, rValue: Any?) -> Bool {
	guard let lValue, let rValue else { return lValue == nil && rValue == nil }
	
	if let lInt = lValue as? Int, let rInt = rValue as? Int {
		return lInt == rInt
	}
	if let lString = lValue as? String, let rString = rValue as? String {
		return lString == rString
	}
	if let lFloat = lValue as? Float, let rFloat = rValue as? Float {
		return lFloat == rFloat
	}
	if let lDouble = lValue as? Double, let rDouble = rValue as? Double {
		return lDouble == rDouble
	}
	if let lDate = lValue as? Date, let rDate = rValue as? Date {
		return lDate == rDate
	}
	if let lData = lValue as? Data, let rData = rValue as? Data {
		return lData == rData
	}
	if let lDictionary = lValue as? [String: Any], let rDictionary = rValue as? [String: Any] {
		return compareTwoJSONDictionaries(lDictionary: lDictionary, rDictionary: rDictionary)
	}
	if let lArray = lValue as? [Any], let rArray = rValue as? [Any] {
		return compareTwoJSONArrays(lArray: lArray, rArray: rArray)
	}
	return false
}


public func compareTwoJSONDictionaries(lDictionary: [String: Any]?, rDictionary: [String: Any]?) -> Bool {
	guard let lDictionary, let rDictionary else { return lDictionary == nil && rDictionary == nil }
	if lDictionary.sortedKeys != rDictionary.sortedKeys { return false }
	
	for (key, lValue) in lDictionary {
		if !compareTwoJSONValues(lValue: lValue, rValue: rDictionary[key]) { return false }
	}
	return true
}

public func compareTwoJSONArrays(lArray: [Any]?, rArray: [Any]?) -> Bool {
	guard let lArray, let rArray else { return lArray == nil && rArray == nil }
	if lArray.count != rArray.count { return false }
	
	for index in lArray.indices {
		if !compareTwoJSONValues(lValue: lArray[index], rValue: rArray[index]) { return false }
	}
	return true
}
