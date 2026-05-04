//
//  Error+UIKit.swift
//  
//
//  Created by Ben Gottlieb on 2/7/20.
//

#if canImport(UIKit) && !os(watchOS) && !os(visionOS)
import UIKit

@MainActor public extension Error {
	func display(in controller: UIViewController?, title: String? = NSLocalizedString("An Error Occurred", comment: "An Error Occurred")) {
		guard let controller = controller else { return }
		let alert = UIAlertController(title: title, message: self.localizedDescription, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: .OK, style: .default, handler: nil))
		controller.present(alert, animated: true, completion: nil)
	}
}
#endif
