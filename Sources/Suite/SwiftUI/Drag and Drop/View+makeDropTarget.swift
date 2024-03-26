//
//  View+makeDropTarget.swift
//  Internal
//
//  Created by Ben Gottlieb on 3/14/23.
//

import SwiftUI

extension CoordinateSpace {
	static var dragAndDropSpaceName: String { "dragAndDropSpace" }
	static var dragAndDropSpace = CoordinateSpace.named(Self.dragAndDropSpaceName)
	static var dragAndDropSpaceCreatedNotification: Notification.Name { Notification.Name("dragAndDropSpaceCreatedNotification") }
}

@available(OSX 13, iOS 15, tvOS 13, watchOS 8, *)
public typealias DragHoverCallback = (String, Any, CGPoint?, CGPoint) -> DragCoordinator.DragAcceptance

@available(OSX 13, iOS 15, tvOS 13, watchOS 8, *)
public typealias DragDroppedCallback = (String, Any, CGPoint, CGPoint) -> Bool

@available(OSX 13, iOS 15, tvOS 13, watchOS 8, *)
public extension View {
	func makeDropTarget(types: [String], showDropPoint: DeviceFilter = .debug, hover: @escaping DragHoverCallback = { _, _, _, _ in .accepted }, dropped: @escaping DragDroppedCallback) -> some View {
		DropTargetView(content: self, types: types, showDropPoint: showDropPoint.matches, hover: hover, dropped: dropped)
	}
	
	func dragAndDropCoordinateSpace() -> some View {
		self
			.coordinateSpace(name: CoordinateSpace.dragAndDropSpaceName)
			.onAppear { CoordinateSpace.dragAndDropSpaceCreatedNotification.notify() }
	}
}

@available(OSX 13, iOS 15, tvOS 13, watchOS 8, *)
struct DropTargetView<Content: View>: View {
	let content: Content
	let types: [String]
	let showDropPoint: Bool
	let hover: DragHoverCallback
	let dropped: DragDroppedCallback

	@EnvironmentObject var dragCoordinator: DragCoordinator
	@Environment(\.isDragAndDropEnabled) var isDragAndDropEnabled
	@State var frame: CGRect?
	@State var isDropTarget = false
	@State var dropPoint: CGPoint?

	func convert(point: CGPoint?, using geo: GeometryProxy) -> CGPoint? {
		guard let point, let frame else { return point }
		
		let newX = point.x - (geo.frame(in: .dragAndDropSpace).minX - frame.minX)
		let newY = point.y - (geo.frame(in: .dragAndDropSpace).minY - frame.minY)
		return CGPoint(x: newX, y: newY)
	}
	
	let dropIndicatorSize = 30.0
	
	var body: some View {
		if isDragAndDropEnabled {
			ZStack(alignment: .topLeading) {
				content
				if showDropPoint, let dropPoint {
					Circle()
						.fill(Color(white: 0.5).opacity(0.5))
						.frame(width: dropIndicatorSize, height: dropIndicatorSize)
						.offset(x: dropPoint.x - dropIndicatorSize / 2, y: dropPoint.y - dropIndicatorSize / 2)
				}
			}
				.background {
					GeometryReader { geo in
						Color.clear
							.onAppear { frame = geo.frame(in: .dragAndDropSpace) }
						#if os(visionOS)
							.onChange(of: dragCoordinator.currentPosition) { currentPositionChanged(to: dragCoordinator.currentPosition, using: geo) }
							.onChange(of: dragCoordinator.dropPosition) { dropPositionChanged(to: dragCoordinator.dropPosition, using: geo) }
						#else
							.onChange(of: dragCoordinator.currentPosition) { newPosition in currentPositionChanged(to: newPosition, using: geo) }
							.onChange(of: dragCoordinator.dropPosition) { dropPoint in dropPositionChanged(to: dropPoint, using: geo) }
						#endif
					}
					.border(Color.red, width: dragCoordinator.dragAcceptance.showAccepted ? 4 : 0)
				}
		} else {
			content
		}
	}
	
	func dropPositionChanged(to dropPoint: CGPoint?, using geo: GeometryProxy) {
		guard let dropPoint = convert(point: dropPoint, using: geo) else { return }
		if let point = dropPosition(at: dropPoint), let type = dragCoordinator.dragType, let object = dragCoordinator.draggedObject {
			if dropped(type, object, point, dragCoordinator.sourcePoint) {
				dragCoordinator.acceptedDrop = true
			}
		}
	}
	
	func currentPositionChanged(to newPosition: CGPoint?, using geo: GeometryProxy) {
		guard let dragPosition = convert(point: newPosition, using: geo), let type = dragCoordinator.dragType, let object = dragCoordinator.draggedObject else {
			dropPoint = nil
			return
		}

		if dragCoordinator.cancelledDrop {
			_ = hover(type, object, nil, dragCoordinator.sourcePoint)
		} else if let point = dropPosition(at: dragPosition) {
			if showDropPoint { dropPoint = point }
			isDropTarget = true
			dragCoordinator.dragAcceptance = hover(type, object, point, dragCoordinator.sourcePoint)
		} else if isDropTarget || dropPoint != nil {
			_ = hover(type, object, nil, dragCoordinator.sourcePoint)
			isDropTarget = false
			dragCoordinator.dragAcceptance = .rejected
			dropPoint = nil
		}
	}

	func dropPosition(at point: CGPoint?) -> CGPoint? {
		guard let newPosition = point, let frame else { return nil }
		let relativePoint = CGPoint(x: newPosition.x - frame.minX, y: newPosition.y - frame.minY)
		
		if
			let type = dragCoordinator.dragType,
			types.contains(type),
			frame.contains(newPosition) {
			return relativePoint
		} else {
			return nil
		}
	}

	@ViewBuilder func dragContent() -> some View {
		content
	}
}
