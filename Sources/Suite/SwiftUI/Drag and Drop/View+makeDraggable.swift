//
//  View+DragContainer.swift
//  Internal
//
//  Created by Ben Gottlieb on 3/14/23.
//

import SwiftUI

@available(OSX 13, iOS 16, tvOS 13, watchOS 8, *)
public extension View {
	func makeDraggable(type: String, object: Any, hideWhenDragging: Bool = true, draggedOpacity: Double = 1.0) -> some View {
		DraggableView(content: self, type: type, object: object, hideWhenDragging: hideWhenDragging, draggedOpacity: draggedOpacity)
	}
}

@available(OSX 13, iOS 16, tvOS 13, watchOS 8, *)
struct DraggableView<Content: View>: View {
	let content: Content
	let type: String
	let object: Any
	let hideWhenDragging: Bool
	let draggedOpacity: Double
	
	@EnvironmentObject var dragCoordinator: DragCoordinator
	@Environment(\.isDragAndDropEnabled) var isDragAndDropEnabled
	@State var frame: CGRect?
	@State var isDragging = false
	@GestureState private var dragGestureActive: Bool = false
	
	var dragAlpha: CGFloat { hideWhenDragging ? 0 : 0.25 }
	
	var body: some View {
		if isDragAndDropEnabled {
			content
				.highPriorityGesture(dragGesture)
				.opacity(isDragging ? dragAlpha : 1)
				.reportGeometry(frame: $frame, in: .dragAndDropSpace)
				.onChange(of: dragGestureActive) { active in
					print("Dragging active: \(active)")
				}
				.onChange(of: frame) { newValue in
					print("Frame changed")
				}
		} else {
			content
		}
	}
	
	@ViewBuilder func dragContent() -> some View {
		content
			.frame(width: frame?.width ?? 200, height: frame?.height ?? 100)
			.opacity(draggedOpacity)
	}
	
	private var dragGesture: some Gesture {
		DragGesture(coordinateSpace: .dragAndDropSpace)
			.updating($dragGestureActive) { value, state, transaction in
				state = true
				print("value: \(value)")
			}
			.onChanged { action in
				if !isDragging {
					isDragging = true
					let renderer = ImageRenderer(content: dragContent())
					dragCoordinator.startDragging(at: action.location, source: frame, type: type, object: object, image: renderer.dragImage)
				}
				dragCoordinator.currentPosition = action.location
			}
			.onEnded { action in
				isDragging = false
				dragCoordinator.drop(at: action.location)
			}
	}
}
