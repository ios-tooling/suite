//
//  URL+Files.swift
//  
//
//  Created by Ben Gottlieb on 7/2/21.
//

import Foundation
import AVFoundation

#if !os(watchOS)
public extension URL {
	var audioDuration: TimeInterval? {
		get async throws {
			let asset = AVURLAsset(url: self)
			
			let reader = try AVAssetReader(asset: asset)
			#if os(visionOS)
				let time: CMTime = try await reader.asset.load(.duration)
				return time.seconds
			#else
				return reader.asset.duration.seconds
			#endif
		}
	}
	
	#if !os(visionOS)
	var audioDurationSync: TimeInterval? {
		get {
			let asset = AVURLAsset(url: self)
			
			guard let reader = try? AVAssetReader(asset: asset) else { return nil }
			return reader.asset.duration.seconds
		}
	}
	#endif
}
#endif

public extension URL {
	static func systemDirectoryURL(which: FileManager.SearchPathDirectory) -> URL? {
		guard let path = NSSearchPathForDirectoriesInDomains(which, [.userDomainMask], true).first else { return nil }
		let url = URL(fileURLWithPath: path)
		if !FileManager.default.fileExists(at: url) { try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil) }
		return url
	}
	
	static let documents: URL = { return systemDirectoryURL(which: .documentDirectory)! }()
	static let applicationSupport: URL = { return systemDirectoryURL(which: .applicationSupportDirectory)! }()
	static let library: URL = { return systemDirectoryURL(which: .libraryDirectory)! }()
	static let caches: URL = { return systemDirectoryURL(which: .cachesDirectory)! }()
	static let applicationSpecificSupport: URL = { return systemDirectoryURL(which: .applicationSupportDirectory)!.appendingPathComponent(Bundle.main.bundleIdentifier ?? Bundle.main.name) }()
	static let temp: URL = { return URL(fileURLWithPath: NSTemporaryDirectory()) }()
	
	static func document(named path: String) -> URL {
		let url = URL.documents + path
		_ = url.dropLast().existingDirectory
		return url
	}

	static func cache(named path: String) -> URL {
		let url = URL.caches + path
		_ = url.dropLast().existingDirectory
		return url
	}

	static func tempFile(named path: String) -> URL {
		let url = URL.temp + path
		_ = url.dropLast().existingDirectory
		return url
	}

	static func library(named path: String) -> URL {
		let url = URL.library + path
		_ = url.dropLast().existingDirectory
		return url
	}

	static func bundled(in bundle: Bundle = .main, named name: String, withExtension ext: String? = nil, subDirectory: String? = nil) -> URL? {
		bundle.url(forResource: name, withExtension: ext, subdirectory: subDirectory)
	}
	
	func removeFromDisk() throws {
		guard isFileURL else { return }
		if FileManager.default.fileExists(at: self) { try FileManager.default.removeItem(at: self) }
	}
}
