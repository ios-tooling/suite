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
		
		//guard let rgb = usingColorSpace(.sRGB) else { return 0.5 }
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
		
	convenience init?(hex hexString: String?) {
		guard let values = hexString?.extractedHexValues else {
			self.init(white: 0, alpha: 0)
			return nil
		}
		self.init(red: CGFloat(values[0]), green: CGFloat(values[1]), blue: CGFloat(values[2]), alpha: CGFloat(values.count > 3 ? values[3] : 1.0))
	}
	
	convenience init(r: Int, g: Int, b: Int, a: Double = 1.0) {
		self.init(red: CGFloat(r.capped(0...255)) / 255.0, green: CGFloat(g.capped(0...255)) / 255.0, blue: CGFloat(b.capped(0...255)) / 255.0, alpha: CGFloat(a))
	}
	
	convenience init(hex: Int, alpha: Double = 1.0) {
		self.init(r: (hex >> 16) & 0xFF, g: (hex >> 8) & 0xFF, b: hex & 0xFF, a: alpha)
	}
	
	var hexString: String {
		var red: CGFloat = 0
		var green: CGFloat = 0
		var blue: CGFloat = 0
		var alpha: CGFloat = 0
		
		self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
		
		let r = Int(255.0 * red)
		let g = Int(255.0 * green)
		let b = Int(255.0 * blue)
		
		return String(format: "%02x%02x%02x", arguments: [r, g, b])
	}
	
	func alpha(_ alpha: CGFloat) -> UIColor {
		self.withAlphaComponent(alpha)
	}

	var hex: Int {
		var red: CGFloat = 0
		var green: CGFloat = 0
		var blue: CGFloat = 0
		var alpha: CGFloat = 0
		
		self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
		
		let r = Int(255.0 * red)
		let g = Int(255.0 * green)
		let b = Int(255.0 * blue)
		
		return r << 16 + g << 8 + b
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
#else
#if canImport(Cocoa)
	import Cocoa
#endif
#endif

public extension Int {
	
}

public extension String {
	var extractedHexValues: [Double]? {
		var rgbValue: UInt32 = 0
		var hex = self
		
		if hex.hasPrefix("#") { hex = String(hex.dropFirst()) }
		
		if #available(macOS 10.15, iOS 13.0, watchOS 6.0, visionOS 1.0, *) {
			let rgbInt = Scanner(string: hex).scanInt(representation: .hexadecimal) ?? 0
			rgbValue = UInt32(rgbInt)
		} else {
			Scanner(string: hex).scanHexInt32(&rgbValue)
		}
		
		if hex.count == 3 {
			return [
				Double((rgbValue & 0x000F00) >> 8) / 15,
				Double((rgbValue & 0x0000F0) >> 4) / 15,
				Double(rgbValue & 0x00000F) / 15,
			]
		}
		
		if hex.count == 4 {
			return [
				Double((rgbValue & 0x000F00) >> 12) / 15,
				Double((rgbValue & 0x000F00) >> 8) / 15,
				Double((rgbValue & 0x0000F0) >> 4) / 15,
				Double(rgbValue & 0x00000F),
			]
		}
		
		if hex.count == 6 {
			return [
				Double((rgbValue & 0xFF0000) >> 16) / 255,
				Double((rgbValue & 0x00FF00) >> 8) / 255,
				Double(rgbValue & 0x0000FF) / 255
			]
		}

		if hex.count == 8 {
			return [
				Double((rgbValue & 0xFF0000) >> 24) / 255,
				Double((rgbValue & 0xFF0000) >> 16) / 255,
				Double((rgbValue & 0x00FF00) >> 8) / 255,
				Double(rgbValue & 0x0000FF) / 255
			]
		}
		return nil
	}
}

#if os(iOS) || os(watchOS) || os(visionOS)
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
#endif
