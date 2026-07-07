//
//  StorageLocation.swift
//  Suite
//
//  Created by Ben Gottlieb on 7/7/26.
//

import Foundation

/// Where an `Outbox` or `Journal` lives on disk. These hold user data that
/// cannot be re-fetched, so `.library` and `.documents` (never purged by the
/// OS) are the sensible roots; `.caches` exists for truly disposable uses.
public enum StorageLocation: Sendable {
	case caches
	case library
	case documents
	case custom(URL)

	public func url(forFile name: String) -> URL {
		switch self {
		case .custom(let url): url
		default: base.appendingPathComponent(name)
		}
	}

	public func directory(named name: String) -> URL {
		switch self {
		case .custom(let url): url
		default: base.appendingPathComponent(name)
		}
	}

	var base: URL {
		switch self {
		case .caches: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
		case .library: FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
		case .documents: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		case .custom(let url): url
		}
	}
}

/// The date codec used for an `Outbox`/`Journal`'s JSON files. Unlike caches,
/// these files are irreplaceable, so the codec must stay compatible with the
/// data already on disk — pick the case matching the site's historical format.
public enum StorageDateCodec: Sendable {
	case iso8601
	case deferredToDate

	var encoder: JSONEncoder {
		let encoder = JSONEncoder()
		if case .iso8601 = self { encoder.dateEncodingStrategy = .iso8601 }
		return encoder
	}

	var decoder: JSONDecoder {
		let decoder = JSONDecoder()
		if case .iso8601 = self { decoder.dateDecodingStrategy = .iso8601 }
		return decoder
	}
}
