//
//  CGRect+Placement.swift
//
//
//  Created by Ben Gottlieb on 12/2/19.
//

import Foundation
import CoreGraphics

public extension CGRect {
	func within(limit: CGRect, placed: CGRect.Placement) -> CGRect {
		let parent = limit
		let child = self
		var newSize = self.size
		var newRect = (child.width < parent.width && child.height < parent.height) ? child : child.size.scaled(within: parent.size).rect

		newRect.origin = parent.origin

		switch (placed) {
		case .scaleToFill: return parent
		case .scaleAspectFill:
			newRect = parent
			if child.aspectRatio < parent.aspectRatio {
				newSize = CGSize(width: parent.width, height: parent.width / child.aspectRatio)
			} else {
				newSize = CGSize(width: parent.height * child.aspectRatio, height: parent.height)
			}
			newRect = CGRect(x: (parent.width - newSize.width) / 2, y: (parent.height - newSize.height) / 2, width: newSize.width, height: newSize.height)

		case .scaleAspectFit:
			newRect = parent
			if child.aspectRatio < parent.aspectRatio {         // left and right letter boxing
				newSize = CGSize(width: parent.width * (child.aspectRatio / parent.aspectRatio), height: parent.height)
			} else if child.aspectRatio > parent.aspectRatio {  // top and bottom letter boxing
				newSize = CGSize(width: parent.width, height: parent.height * (parent.aspectRatio / child.aspectRatio))
			} else if newSize.width > parent.width {
				newSize = parent.size
			}
			newRect = CGRect(x: (parent.width - newSize.width) / 2, y: (parent.height - newSize.height) / 2, width: newSize.width, height: newSize.height)

		case .center:
			let insetX = (parent.width - newRect.width) / 2
			let insetY = (parent.height - newRect.height) / 2
			newRect.origin.x += insetX
			newRect.origin.y += insetY
			newRect.size.height = min(limit.height - insetY * 2, self.height)
			newRect.size.width = min(limit.width - insetX * 2, self.width)

		case .top:
			newRect.origin.x += (parent.width - newRect.width) / 2
			newRect.origin.y = parent.origin.y

		case .bottom:
			newRect.origin.x += (parent.width - newRect.width) / 2
			newRect.origin.y = (parent.height - newRect.height)

		case .left:
			newRect.origin.x = parent.origin.x
			newRect.origin.y += (parent.height - newRect.height) / 2

		case .right:
			newRect.origin.x += (parent.width - newRect.width)
			newRect.origin.y += (parent.height - newRect.height) / 2

		case .topLeft:
			newRect.origin.x = parent.origin.x
			newRect.origin.y = parent.origin.y

		case .bottomLeft:
			newRect.origin.x = parent.origin.x
			newRect.origin.y += (parent.height - newRect.height)

		case .topRight:
			newRect.origin.x += (parent.width - newRect.width)
			newRect.origin.y = parent.origin.y

		case .bottomRight:
			newRect.origin.x += (parent.width - newRect.width)
			newRect.origin.y += (parent.height - newRect.height)

		default: break
		}
		return newRect
	}
}
