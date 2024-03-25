//
//  DragCoordinator.swift
//  Internal
//
//  Created by Ben Gottlieb on 3/14/23.
//

import SwiftUI

extension EnvironmentValues {
	@GeneratedEnvironmentKey var dragCoordinatorSnapbackDuration = 0.2
}

@available(OSX 13, iOS 15, tvOS 13, watchOS 8, *)
public class DragCoordinator: ObservableObject {
	var containerFrame: CGRect?
	
	@Published var draggedImage: DragImage?
	@Published var currentPosition: CGPoint?
	@Published var startPosition: CGPoint?
	@Published var dropPosition: CGPoint?
	@Published var sourceFrame: CGRect?
	@Published var isDragging = false
	@Published var dragType: String?
	@Published var draggedObject: Any?
	@Published var acceptedDrop = false
	@Published var cancelledDrop = false
	@Published var dropScale = 1.0
	@Published var snapbackDuration = 0.2
	
	func startDragging(at point: CGPoint, source: CGRect?, type: String, object: Any, image: DragImage?) {
		dropPosition = nil
		draggedImage = image
		startPosition = point
		sourceFrame = source
		draggedObject = object
		dragType = type
		isDragging = true
		acceptedDrop = false
		dropScale = 1.0
		cancelledDrop = false
	}
	
	func drop(at point: CGPoint?) {
		if let point, !cancelledDrop {
			dropPosition = point
			Task { @MainActor in
				try? await Task.sleep(nanoseconds: 10_000_000)
				if self.acceptedDrop {
					self.animateDrop()
				} else {
					self.snapback(duration: self.snapbackDuration)
				}
			}
		} else {
			snapback(duration: snapbackDuration)
		}
	}
	
	func animateDrop(duration: TimeInterval = 0.2) {
		withAnimation(.easeOut(duration: duration)) {
			dropScale = 0.001
		}

		DispatchQueue.main.async(after: duration) {
			self.completeDrag()
		}
	}
	
	func snapback(duration: TimeInterval = 0.2) {
		withAnimation(.easeOut(duration: duration)) {
			currentPosition = startPosition
		}

		DispatchQueue.main.async(after: duration) {
			self.completeDrag()
		}
	}
	
	func completeDrag() {
		isDragging = false
		dropPosition = nil
		draggedObject = nil
		dragType = nil
		currentPosition = nil
	}
	
	var currentTranslation: CGSize? {
		guard let startPosition, let currentPosition else { return nil }
		
		return CGSize(width: currentPosition.x - startPosition.x, height: currentPosition.y - startPosition.y)
	}
	
	var dragOffset: CGSize? {
		guard isDragging, let containerFrame, let currentPosition, let sourceFrame, let startPosition else { return nil }

		
		return CGSize(
			width: (currentPosition.x - containerFrame.minX) - (startPosition.x - sourceFrame.minX),
			height: (currentPosition.y - containerFrame.minY) - (startPosition.y - sourceFrame.minY)
		)
	}
}




