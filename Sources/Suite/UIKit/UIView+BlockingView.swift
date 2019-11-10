//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 11/9/19.
//

import UIKit

public extension UIView {
	var blockingView: SA_BlockingView? {
		for view in self.subviews {
			if let blocker = view as? SA_BlockingView { return blocker }
		}
		return nil
	}
	
	func removeBlockingView(duration: TimeInterval, completion: (() -> Void)? = nil) {
		UIView.animate(withDuration: duration, animations: {
			self.blockingView?.alpha = 0
		}, completion: { complete in
			self.blockingView?.removeFromSuperview()
			completion?()
		})
	}

	func blockingView(excluding: [CGRect] = [], tappedClosure closure: (() -> Void)? = nil) -> UIView {
		if let existing = self.blockingView { return existing }
		let view = SA_BlockingView(frame: self.bounds)

		if closure != nil {
			view.tappedClosure = closure
		}
		
		//view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(SA_BlockingView.tapped)))
		view.excludedRects = excluding
		view.isUserInteractionEnabled = true
		view.backgroundColor = UIColor.clear
		
		self.addSubview(view)
		
		view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		
		return view
	}
}

public class SA_BlockingView: UIView {
	var tappedClosure: (() -> Void)?
	var excludedRects: [CGRect] = []
	
	public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		return !self.isPointExcluded(point)
	}

	func isPointExcluded(_ point: CGPoint) -> Bool {
		for excludedRect in self.excludedRects {
			if excludedRect.contains(point) {
				return true
			}
		}
		
		return false
	}
	
	public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let parent = self.superview, let pt = touches.first?.location(in: parent) else { return }

		if let target = parent.hitTest(pt, with: nil) {
			if target != self { return }
		}
		
		self.tappedClosure?()
	}
}

