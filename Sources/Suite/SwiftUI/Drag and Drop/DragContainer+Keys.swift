//
//  w
//  Internal
//
//  Created by Ben Gottlieb on 3/14/23.
//

import SwiftUI

#if os(macOS)
	typealias DragImage = NSImage
	extension Image {
		init(dragImage: DragImage) { self.init(nsImage: dragImage) }
	}
	@available(OSX 13, iOS 16, tvOS 13, watchOS 8, *)
	extension ImageRenderer {
		@MainActor var dragImage: NSImage? { nsImage }
	}
#else
	typealias DragImage = UIImage
	@available(OSX 13, iOS 16, watchOS 8, tvOS 16, *)
	extension Image {
		init(dragImage: DragImage) { self.init(uiImage: dragImage) }
	}
	@available(OSX 13, iOS 16, tvOS 16, watchOS 9, *)
	extension ImageRenderer {
		@MainActor var dragImage: UIImage? { uiImage }
	}
#endif



@available(OSX 13, iOS 15, watchOS 8, tvOS 15, *)
extension EnvironmentValues {
	@Entry public var currentDragPosition: CGPoint? = nil
	@Entry public var isDragAndDropEnabled: Bool = false
}
