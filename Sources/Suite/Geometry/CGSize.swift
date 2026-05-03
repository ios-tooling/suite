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
		guard width > 0, height > 0 else { return self }

		let widthRatio = maxWidth.map { $0 / width } ?? .infinity
		let heightRatio = maxHeight.map { $0 / height } ?? .infinity
		let scale = min(1, widthRatio, heightRatio)

		return CGSize(width: width * scale, height: height * scale)
	}
}

extension CGSize: @retroactive Hashable {}
extension CGSize: StringInitializable, @retroactive RawRepresentable { }
