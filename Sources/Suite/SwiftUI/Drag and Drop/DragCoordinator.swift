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
@MainActor public class DragCoordinator: ObservableObject {
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
	@Published var currentDropTargetID: String?
	@Published var cancelledDrop = false
	@Published var dropScale = 1.0
	@Published var snapbackDuration = 0.2
	@Published var sourcePoint = CGPoint.zero
	@Published var dragAcceptance = DragAcceptance.rejected
	
	func describe() {
		var text = ""
		if let draggedImage { text += "draggedImage: \(draggedImage)\n" }
		if let currentPosition { text += "currentPosition: \(currentPosition)\n"}
		if let startPosition { text += "startPosition: \(startPosition)\n" }
		if let dropPosition { text += "dropPosition: \(dropPosition)\n" }
		if let sourceFrame { text += "sourceFrame: \(sourceFrame)\n" }
		if isDragging { text += "isDragging: true\n" }
		if let dragType { text += "dragType: \(dragType)\n" }
		if let draggedObject { text += "draggedObject: \(draggedObject)\n" }
		if acceptedDrop { text += "acceptedDrop: \(acceptedDrop)\n" }
		if let currentDropTargetID { text += "currentDropTargetID: \(currentDropTargetID)\n" }
		if cancelledDrop { text += "cancelledDrop: true\n" }
		text += "dropScale: \(dropScale)\n"
		text += "sourcePoint: \(sourcePoint)\n"
		text += "dragAcceptance: \(dragAcceptance)\n"
		print(text)
	}
	

	public enum DragAcceptance: Equatable { case rejected, accepted(Int), acceptedHighlight(Int), acceptedHidden(Int), acceptedHiddenHighlight(Int)
		var showAccepted: Bool {
			switch self {
			case .acceptedHighlight, .acceptedHiddenHighlight: true
			default: false
			}
		}

		var isHidden: Bool {
			switch self {
			case .acceptedHidden, .acceptedHiddenHighlight: true
			default: false
			}
		}
		
		var priority: Int {
			switch self {
			case .rejected: 0
			case .accepted(let priority): priority
			case .acceptedHighlight(let priority): priority
			case .acceptedHidden(let priority): priority
			case .acceptedHiddenHighlight(let priority): priority
			}
		}
	}

	func startDragging(at point: CGPoint, source: CGRect?, sourcePoint: CGPoint, type: String, object: Any, image: DragImage?) {
		dropPosition = nil
		draggedImage = image
		startPosition = point
		sourceFrame = source
		draggedObject = object
		dragType = type
		isDragging = true
		acceptedDrop = false
		currentDropTargetID = nil
		dropScale = 1.0
		cancelledDrop = false
		self.sourcePoint = sourcePoint
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
		print("All done")
		isDragging = false
		dropPosition = nil
		draggedObject = nil
		dragType = nil
		currentPosition = nil
		startPosition = nil
		draggedImage = nil
		sourceFrame = nil
		sourcePoint = .zero
		dropScale = 1.0
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




