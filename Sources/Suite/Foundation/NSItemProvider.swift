//
//  NSItemProvider.swift
//  Internal
//
//  Created by Ben Gottlieb on 8/26/25.
//

import Foundation
import UniformTypeIdentifiers

#if canImport(UIKit)
	import UIKit
	typealias NSItemProviderImage = UIImage
#elseif canImport(AppKit)
	import AppKit
	typealias NSItemProviderImage = NSImage
#endif

@available(iOS 14.0, macOS 12, watchOS 8, *)
extension [NSItemProvider] {
	public func extractURL() async -> URL? {
		for itemProvider in self {
			if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
				do {
					let item = try await itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil)
					if let url = extractURLFromItem(item: item) { return url }
				} catch {
					print("Error loading URL: \(error)")
					continue
				}
			}
		}

		for itemProvider in self {
			if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
				do {
					let item = try await itemProvider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil)
					if let url = extractURLFromItem(item: item) { return url }
				} catch {
					continue
				}
			}
		}
		return nil
	}
	
	func extractURLFromItem(item: (any NSSecureCoding)?) -> URL? {
		if let url = item as? URL {
			return url
		}
		if let urlData = item as? Data,
			let urlString = String(data: urlData, encoding: .utf8),
			let url = URL(string: urlString) {
			return url
		}
		return nil
	}
	
	#if canImport(UIKit)
		public func extractImage() async -> UIImage? { await extractProviderImage() }
	#else
		public func extractImage() async -> NSImage? { await extractProviderImage() }
	#endif
	
	 /// Extracts the first image found in the item providers (UIImage on iOS, NSImage on macOS)
	func extractProviderImage() async -> NSItemProviderImage? {
		// Try different image types in order of preference for macOS
		let imageTypes = [ UTType.png.identifier, UTType.jpeg.identifier, UTType.tiff.identifier, "com.apple.pict", UTType.image.identifier, ]
		
		for imageType in imageTypes {
			for itemProvider in self {
				if itemProvider.hasItemConformingToTypeIdentifier(imageType) {
					if let image = await extractImageFromProvider(itemProvider, typeIdentifier: imageType) {
						return image
					}
				}
			}
		}
		
		return nil
	}
	 
	 private func extractImageFromProvider(_ itemProvider: NSItemProvider, typeIdentifier: String = "public.image") async -> NSItemProviderImage? {
		  guard itemProvider.hasItemConformingToTypeIdentifier(typeIdentifier) else {
				return nil
		  }
		  
		  do {
				let item = try await itemProvider.loadItem(forTypeIdentifier: typeIdentifier, options: nil)
				
				#if canImport(AppKit)
				  // On macOS, try multiple approaches to get the actual image
				  if let image = item as? NSImage, !image.representations.isEmpty { return image } // Check if this is a placeholder by examining its representations
					  
				  if let imageData = item as? Data, let image = NSImage(data: imageData) { return image }
				  
				  // Try loading as file URL if it's a file reference
				  if let fileURL = item as? URL, fileURL.isFileURL, let imageData = try? Data(contentsOf: fileURL), let image = NSImage(data: imageData) {
					  return image
				  }
				#elseif canImport(UIKit)
				  if let image = item as? UIImage { return image }
				  
				  if let url = item as? URL, url.isFileURL, let image = UIImage(contentsOf: url) { return image }
				  
				  if let imageData = item as? Data, let image = UIImage(data: imageData) { return image }
				#endif
				
		  } catch {
				print("Error loading image with type \(typeIdentifier): \(error)")
		  }
		  
		  return nil
	 }
}
