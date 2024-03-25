//
//  DragContainer.swift
//  Internal
//
//  Created by Ben Gottlieb on 3/14/23.
//

import SwiftUI

@available(OSX 13, iOS 16, tvOS 13, watchOS 8, *)
public struct DragContainer<Content: View>: View {
	@ViewBuilder private var content: () -> Content
	@StateObject private var coordinator: DragCoordinator
	let isDragEnabled: Bool
	
	public init(enabled: Bool = true, snapbackDuration: TimeInterval = 0.2, @ViewBuilder content: @escaping () -> Content) {
		self.content = content
		let coordinator = DragCoordinator()
		coordinator.snapbackDuration = snapbackDuration
		_coordinator = StateObject(wrappedValue: coordinator)
		isDragEnabled = enabled
	}
	
	public var body: some View {
		ZStack(alignment: .topLeading) {
			content()
			
			if coordinator.isDragging, let image = coordinator.draggedImage, let offset = coordinator.dragOffset {
				Image(dragImage: image)
					.scaleEffect(coordinator.dropScale)
					.id("dragged")
					.offset(offset)
			}
		}
		.environment(\.isDragAndDropEnabled, isDragEnabled)
		.environment(\.currentDragPosition, coordinator.currentPosition)
		.environmentObject(coordinator)
		.background {
			GeometryReader { geo in
				Color.clear
					.onAppear {
						coordinator.containerFrame = geo.frame(in: .dragAndDropSpace)
					}
					.onReceive(CoordinateSpace.dragAndDropSpaceCreatedNotification.publisher()) { _ in
						coordinator.containerFrame = geo.frame(in: .dragAndDropSpace)
					}
			}
		}
		.dragAndDropCoordinateSpace()
		.environment(\.dragCoordinatorSnapbackDuration, coordinator.snapbackDuration)
	}
}

@available(OSX 13, iOS 16, tvOS 13, watchOS 8, *)
struct DragContainer_Previews: PreviewProvider {
	static var previews: some View {
		DragContainer() {
			
		}
	}
}
