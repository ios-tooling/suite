//
//  CGSize.swift
//
//
//  Created by Ben Gottlieb on 3/20/21.
//

import Foundation
import CoreGraphics

#if os(iOS)
import UIKit
#endif

public extension CGSize {
	var dimString: String { "\(Int(width)) x \(Int(height))" }
	
	enum AspectRatioType: Int, Sendable { case portrait, landscape, square }
	func scaled(within limit: CGSize) -> CGSize {
		let myAspectRatio = self.width / self.height
		let theirAspectRatio = limit.width / limit.height
		var computed = limit
		
		if myAspectRatio < theirAspectRatio {
			computed.width = limit.height * myAspectRatio
		} else {
			computed.height = limit.width / myAspectRatio
		}
		return computed
	}
	
	var isSquare: Bool { return self.width > 0 && self.width == self.height }
	var rect: CGRect { return CGRect(x: 0, y: 0, width: width, height: height) }
	
	func rounded() -> CGSize { return CGSize(width: roundcgf(value: width), height: roundcgf(value: height) )}
	
	var aspectRatio: CGFloat { return self.width / self.height }
	var aspectRatioType: AspectRatioType {
		switch self.aspectRatio {
		case ..<1: return .portrait
		case 1: return .square
		default: return .landscape
		}
	}
	
	var point: CGPoint { CGPoint(x: width, y: height )}
	
	func scaleDown(toWidth maxWidth: CGFloat?, height maxHeight: CGFloat?) -> CGSize {
		var heightGood = false, widthGood = false
		
		if let maxH = maxHeight, maxH < self.height {
			heightGood = true
		}
		
		if let maxW = maxWidth, maxW < self.width {
			heightGood = true
		}
		
		if heightGood && widthGood { return self }
		
		let aspect = self.aspectRatio
		
		if heightGood && maxWidth != nil {
			return CGSize(width: maxWidth!, height: maxWidth! / aspect)
		}
		
		if widthGood && maxHeight != nil {
			return CGSize(width: maxHeight! * aspect, height: maxHeight!)
		}
		
		if let maxHeight = maxHeight, let maxWidth = maxWidth {
			let calcWidth = min(maxWidth, maxHeight * aspect)
			let calcHeight = min(maxHeight, maxWidth / aspect)
			
			if (calcHeight / maxHeight) > (calcWidth / maxWidth) {        //height is better match
				return CGSize(width: calcHeight * aspect, height: calcHeight)
			} else {
				return CGSize(width: calcWidth, height: calcWidth / aspect)
			}
		}
		return CGSize(width: maxWidth ?? self.width, height: maxHeight ?? self.height)
	}
}

extension CGSize: @retroactive Hashable {}
extension CGSize: StringInitializable, @retroactive RawRepresentable { }
