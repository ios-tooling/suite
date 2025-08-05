//
//  OnDemandFetcher.swift
//
//
//  Created by Ben Gottlieb on 12/23/23.
//

import Foundation

#if os(iOS)
import UIKit

public struct OnDemandFetcher {
	struct StoredDictionary: Codable {
		let version: Int
		let dictionary: [String: String]
	}
	
	enum OnDemandResourceError: Error, Sendable { case resourceNotFound }
	
	public static func fetchDictionary(name: String, tag: String? = nil, version: Int = 1) async throws -> [String: String] {
		let keychainKey = "ondemand_\(name)"
		if let keychainData = Keychain.data(forKey: keychainKey), let cached = try? JSONDecoder().decode(StoredDictionary.self, from: keychainData), cached.version == version {
			return cached.dictionary
		}
		
		let request = NSBundleResourceRequest(tags: [tag ?? name], bundle: .main)
		request.loadingPriority = 1
		try await request.beginAccessingResources()
		
		guard let asset = NSDataAsset(name: name, bundle: request.bundle) else { throw OnDemandResourceError.resourceNotFound }
		
		let json = try JSONDecoder().decode([String: String].self, from: asset.data)
		let cache = StoredDictionary(version: version, dictionary: json)
		
		if let cacheData = try? JSONEncoder().encode(cache) {
			Keychain.set(cacheData, forKey: keychainKey)
		}
		
		request.endAccessingResources()
		return json
	}
}
#endif
