//
//  WrappingHStack.swift
//  Suite
//
//  Created by Ben Gottlieb on 5/9/25.
//

import SwiftUI


@available(iOS 16.0, macOS 13, watchOS 10, tvOS 16.0, *)
public struct WrappingHStack: Layout {
	public struct CacheStorage {
		
		struct CalculatedElement {
			let element: Subviews.Element
			let size: CGSize
		}
		
		struct Line {
			var width: CGFloat = 0
			var height: CGFloat = 0
			
			var elements: [CalculatedElement] = []
		}
		
		var lines: [Line] = []
		
		func calculateSize(verticalSpacing: CGFloat) -> CGSize {
			let maxWidth = lines.max(by: { $0.width < $1.width })?.width ?? 0
			let totalHeight: CGFloat = lines.reduce(0) { partialResult, line in
				partialResult + line.height
			}
			let verticalSpacing: CGFloat = (CGFloat(max(0, (lines.count - 1))) * verticalSpacing)
			
			return .init(width: maxWidth, height: totalHeight + verticalSpacing)
			
		}
	}
	
	public let horizontalSpacing: CGFloat
	public let verticalSpacing: CGFloat
	
	public init(horizontalSpacing: CGFloat = 4, verticalSpacing: CGFloat = 4) {
		self.horizontalSpacing = horizontalSpacing
		self.verticalSpacing = verticalSpacing
	}
	
	public func makeCache(subviews: Subviews) -> CacheStorage {
		return .init()
	}
	
	public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheStorage) -> CGSize {
		let bounds = CGRect(origin: .zero, size: .init(width: proposal.width ?? .infinity, height: proposal.height ?? .infinity))
		
		cache.lines = []
		
		var offsetX = 0.0
		var currentLine = CacheStorage.Line()
		
		for (_, view) in subviews.enumerated() {
			let calculatedSize = view.sizeThatFits(
				.init(width: bounds.width, height: bounds.height)
			)
			
			if (offsetX + calculatedSize.width) >= bounds.width {					// line break
				currentLine.width = offsetX
				
				offsetX = 0
				cache.lines.append(currentLine)
				currentLine = .init()
			}
			
			let calculatedElement = CacheStorage.CalculatedElement(element: view, size: calculatedSize)
			
			currentLine.elements.append(calculatedElement)
			
			offsetX += calculatedSize.width + horizontalSpacing
			
			if currentLine.height < calculatedElement.size.height {
				currentLine.height = calculatedElement.size.height
			}
		}
		
		currentLine.width = offsetX
		cache.lines.append(currentLine)
		
		let size = cache.calculateSize(verticalSpacing: verticalSpacing)
		
		return size
	}
	
	public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheStorage) {
		var cursorY: CGFloat = 0
		var cursorX: CGFloat = 0
		
		for line in cache.lines {
			for element in line.elements {
				let point = CGPoint(x: bounds.minX + cursorX, y: bounds.minY + cursorY)
				
				element.element.place(at: point, anchor: .topLeading, proposal: .init(width: element.size.width, height: element.size.height))
				cursorX += element.size.width + horizontalSpacing
			}
			
			cursorX = 0
			cursorY += line.height + verticalSpacing
		}
	}
}
