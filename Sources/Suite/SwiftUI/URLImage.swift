//
//  URLImage.swift
//  
//
//  Created by Ben Gottlieb on 1/7/21.
//

import Foundation

#if canImport(SwiftUI)
#if canImport(Combine)

import SwiftUI
import Combine

#if canImport(UIKit)
	import UIKit
	typealias FrameworkImage = UIImage
#elseif canImport(AppKit)
	import AppKit
	typealias FrameworkImage = NSImage
#endif

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public struct URLImage: View {
	let placeholder: Image?
	let imageURL: URL?
	let contentMode: ContentMode
	@State var frameworkImage: FrameworkImage?
	
	public init(url: URL?, contentMode: ContentMode = .fit, placeholder: Image? = nil) {
		imageURL = url
		self.contentMode = contentMode
		self.placeholder = placeholder
		if let url = url, let image = ImageCache.instance.cachedValue(for: url) {
			_frameworkImage = State(wrappedValue: image)
		}
	}
	
	var imageView: Image {
		if let image = frameworkImage {
			#if os(OSX)
			return Image(nsImage: image)
			#else
			return Image(uiImage: image)
			#endif
		}
		
		if let placeholder = placeholder { return placeholder }
		if #available(OSX 11.0, *) {
			return Image(systemName: "square")
		} else {
			return Image("")
		}
	}
	
	public var body: some View {
		imageView
			.resizable()
			.aspectRatio(contentMode: contentMode)
			.id(imageURL)
			.onAppear() {
				if let imageURL = imageURL, frameworkImage == nil {
					URLSession.shared.dataTaskPublisher(for: imageURL)
									.map { UIImage(data: $0.data) }
									.replaceError(with: nil)
									.receive(on: DispatchQueue.main)
						.eraseToAnyPublisher()
						.onSuccess { image in
							frameworkImage = image
						}
						
//					ImageCache.instance.fetch(for: imageURL)
//						.receive(on: RunLoop.main)
//						.eraseToAnyPublisher()
//						.onSuccess { image in
//							frameworkImage = image
//						}
				}
			}
	}
}




#endif
#endif
