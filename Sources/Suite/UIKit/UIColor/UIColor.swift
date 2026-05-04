//
//  UIColor.swift
//
//
//  Created by Ben Gottlieb on 12/2/19.
//

import Foundation

#if canImport(UIKit)
import UIKit

public extension UIColor {
	static func random() -> UIColor {
		let h = CGFloat.random(in: 0...1)
		let s = CGFloat.random(in: 0...1)
		let v = CGFloat.random(in: 0...1)

		return UIColor(hue: h, saturation: s, brightness: v, alpha: 1)
	}

	var brightness: Double {
		var r: CGFloat = 0.0
		var g: CGFloat = 0.0
		var b: CGFloat = 0.0
		var a: CGFloat = 0.0
		var brightness: CGFloat = 0.0

		self.getRed(&r, green: &g, blue: &b, alpha: &a)

		// algorithm from: http://www.w3.org/WAI/ER/WD-AERT/#color-contrast
		brightness = ((r * 299) + (g * 587) + (b * 114)) / 1000;
		return brightness
	}

	var luminosity: Double {
		var r: CGFloat = 0.0
		var g: CGFloat = 0.0
		var b: CGFloat = 0.0
		var a: CGFloat = 0.0
		self.getRed(&r, green: &g, blue: &b, alpha: &a)
		return 0.2126 * r + g * 0.7152 + 0.0722 * b
	}

	func alpha(_ alpha: CGFloat) -> UIColor {
		self.withAlphaComponent(alpha)
	}

	static let defaultText: UIColor = {
		#if os(watchOS)
			return .darkGray
		#else
			UIColor.label
		#endif
	}()

	static let secondaryText: UIColor = {
		#if os(watchOS)
			return .white
		#else
			UIColor.secondaryLabel
		#endif
	}()

	static let tertiaryText: UIColor = {
		#if os(watchOS)
			return .lightGray
		#else
			UIColor.tertiaryLabel
		#endif
	}()

	static let defaultBackground: UIColor = {
		#if os(watchOS)
			return .white
		#elseif os(tvOS)
			return .black
		#else
			UIColor.systemBackground
		#endif
	}()

	#if os(iOS)
		@available(iOS 10.0, *)
		func swatch(of size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
			UIGraphicsImageRenderer(size: size).image { ctx in
				self.setFill()
				UIRectFill(size.rect)
			}
		}
	#endif
}
#endif
