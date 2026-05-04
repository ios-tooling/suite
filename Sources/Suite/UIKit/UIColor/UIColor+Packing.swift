//
//  UIColor+Packing.swift
//
//
//  Created by Ben Gottlieb on 12/2/19.
//

import Foundation

#if os(iOS) || os(watchOS) || os(visionOS) || os(tvOS)
import UIKit

public extension UIColor {
	typealias PackedColor = UInt32

	convenience init(unpacked: UIColor.PackedColor, withAlphaStyle imageAlphaStyle: CGImageAlphaInfo) {
		let full = CGFloat(255.0)

		if imageAlphaStyle == .premultipliedLast {
			let a = UInt8((unpacked >> 24) & 0x000000FF)
			let b = UInt8((unpacked >> 16) & 0x000000FF)
			let g = UInt8((unpacked >> 8) & 0x000000FF)
			let r = UInt8((unpacked >> 0) & 0x000000FF)

			self.init(red: CGFloat(r) / full, green: CGFloat(g) / full, blue: CGFloat(b) / full, alpha: CGFloat(a) / full)
		} else {
			let r = UInt8((unpacked >> 16) & 0x000000FF)
			let g = UInt8((unpacked >> 8) & 0x000000FF)
			let b = UInt8((unpacked >> 0) & 0x000000FF)
			let a = UInt8((unpacked >> 24) & 0x000000FF)

			self.init(red: CGFloat(r) / full, green: CGFloat(g) / full, blue: CGFloat(b) / full, alpha: CGFloat(a) / full)
		}
	}
}

public extension Array where Element == UIColor {
	var averageColor: UIColor? {
		guard !isEmpty else { return nil }

		var r: CGFloat = 0
		var g: CGFloat = 0
		var b: CGFloat = 0

		for color in self {
			var colorR: CGFloat = 0
			var colorG: CGFloat = 0
			var colorB: CGFloat = 0

			color.getRed(&colorR, green: &colorG, blue: &colorB, alpha: nil)

			r += colorR * colorR
			g += colorG * colorG
			b += colorB * colorB
		}

		return UIColor(red: sqrt(r / CGFloat(count)), green: sqrt(g / CGFloat(count)), blue: sqrt(b / CGFloat(count)), alpha: 1)
	}
}
#endif
