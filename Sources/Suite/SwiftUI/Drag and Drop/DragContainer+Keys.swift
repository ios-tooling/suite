//
//  DragContainer+Environment.swift
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
struct CurrentDragPositionEnvironmentKey: EnvironmentKey {
	static let defaultValue: CGPoint? = nil
}

@available(OSX 13, iOS 15, watchOS 8, tvOS 15, *)
struct DragAndDropEnabledEnvironmentKey: EnvironmentKey {
	static let defaultValue = false
}

@available(OSX 13, iOS 15, watchOS 8, tvOS 15, *)
extension EnvironmentValues {
	public var currentDragPosition: CGPoint? {
		get { self[CurrentDragPositionEnvironmentKey.self] }
		set { self[CurrentDragPositionEnvironmentKey.self] = newValue }
	}

	public var isDragAndDropEnabled: Bool {
		get { self[DragAndDropEnabledEnvironmentKey.self] }
		set { self[DragAndDropEnabledEnvironmentKey.self] = newValue }
	}

	
}
