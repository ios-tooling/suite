//
//  View+DragContainer.swift
//  Internal
//
//  Created by Ben Gottlieb on 3/14/23.
//

import SwiftUI

public enum DragPhase: Equatable {
	case idle, starting, dropped(Any?), cancelled
		
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		switch (lhs, rhs) {
		case (.idle, .idle): true
		case (.starting, .starting): true
		case (.cancelled, .cancelled): true
		case (.dropped, .dropped): true
		default: false
		}
	}
}
public typealias DropPhaseChangedCallback = (@Sendable (DragPhase) -> Void)

@available(OSX 13, iOS 15, tvOS 13, watchOS 9, *)
public extension View {
	@ViewBuilder func makeDraggable(type: String, object: Any, hideWhenDragging: Bool = true, draggedOpacity: Double = 1.0, phaseChanged:  DropPhaseChangedCallback? = nil) -> some View {
		if #available(iOS 16, *) {
			DraggableView(content: self, type: type, object: object, hideWhenDragging: hideWhenDragging, draggedOpacity: draggedOpacity, phaseChanged: phaseChanged)
		} else {
			self
		}
	}
}

@available(OSX 13, iOS 16, tvOS 13, watchOS 9, *)
struct DraggableView<Content: View>: View {
	let content: Content
	let type: String
	let object: Any
	let hideWhenDragging: Bool
	let draggedOpacity: Double
	let phaseChanged: DropPhaseChangedCallback?
	
	@EnvironmentObject var dragCoordinator: DragCoordinator
	@Environment(\.isDragAndDropEnabled) var isDragAndDropEnabled
	@Environment(\.isScrolling) var isScrolling
	@State var frame: CGRect?
	@State var isDragging = false
	@Environment(\.dragCoordinatorSnapbackDuration) var snapbackDuration
	
	var dragAlpha: CGFloat { hideWhenDragging ? 0 : 0.25 }
	
	var body: some View {
		if isDragAndDropEnabled {
			content
				.highPriorityGesture(dragGesture)
				.opacity(isDragging ? dragAlpha : 1)
				.reportGeometry(frame: $frame, in: .dragAndDropSpace)
			#if os(visionOS)
				.onChange(of: isScrolling) {
					if isScrolling, isDragging {
						isDragging = false
						dragCoordinator.currentPosition = nil
						dragCoordinator.cancelledDrop = true
						dragCoordinator.drop(at: nil)
						phaseChanged?(.cancelled)
					}
				}
			#else
				.onChange(of: isScrolling) { isScrolling in
					if isScrolling, isDragging {
						isDragging = false
						dragCoordinator.currentPosition = nil
						dragCoordinator.cancelledDrop = true
						dragCoordinator.drop(at: nil)
						phaseChanged?(.cancelled)
					}
				}
			#endif
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
			.onChanged { action in
				if !isDragging {
					phaseChanged?(.starting)
					isDragging = true
					let renderer = ImageRenderer(content: dragContent())
					var sourcePoint: CGPoint = .zero
					if let frame {
						sourcePoint = CGPoint(x: action.location.x - frame.minX, y: action.location.y - frame.minY)
					} else {
						sourcePoint = .zero
					}
					dragCoordinator.startDragging(at: action.location, source: frame, sourcePoint: sourcePoint, type: type, object: object, image: renderer.dragImage)
				}
				dragCoordinator.currentPosition = action.location
			}
			.onEnded { action in
				Task {
					try? await Task.sleep(for: .seconds(snapbackDuration))
					isDragging = false
					phaseChanged?(dragCoordinator.acceptedDrop ? .dropped(dragCoordinator.currentDropTarget) : .cancelled)
				}
				dragCoordinator.drop(at: action.location)
			}
	}
}
