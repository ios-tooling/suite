//
//  ScreenOverlay.swift
//  Suite
//
//  Created by Ben Gottlieb on 10/10/24.
//

import SwiftUI
#if os(iOS)

public extension View {
	func screenOverlay<Content: View>(alignment: VerticalAlignment = .bottom, shown: Bool = true, @ViewBuilder content: () -> Content) -> some View {
		ZStack {
			self
			OverlayWrapper(content: content(), isVisible: shown, alignment: alignment)
		}
	}
}

struct OverlayWrapper<Content: View>: View {
	let content: Content
	let isVisible: Bool
	let alignment: VerticalAlignment
	@State var overlayWindow: ScreenOverlay<Content>?
	
	var body: some View {
		if isVisible {
			HStack { }
				.onAppear {
					if overlayWindow == nil {
						overlayWindow = ScreenOverlay(contentView: content, alignment: alignment)
					}
				}
				.onDisappear {
					overlayWindow?.close()
					overlayWindow = nil
				}
		}
	}
}

@MainActor public class ScreenOverlay<Content: View> {
	let controller: UIHostingController<Content>
	let window: HostWindow!
	let alignment: VerticalAlignment
	
	func close() {
		window.removeFromSuperview()
	}
	
	public init(contentView: Content, alignment: VerticalAlignment) {
		controller = UIHostingController(rootView: contentView)
		self.alignment = alignment
		
		if let focus = UIWindowScene.focused {
			self.window = HostWindow(windowScene: focus)
		} else {
			self.window = .init()
		}
		
		controller.disableSafeArea()
		window.rootViewController = controller
		window.windowLevel = .statusBar
		window.isHidden = false
		window.backgroundColor = UIColor.clear
		window.isUserInteractionEnabled = true
		window.rootViewController?.view.isUserInteractionEnabled = true
		window.rootViewController?.view.backgroundColor = UIColor.clear
		window.makeKeyAndVisible()
		
		updateFrames()
	}
	
	func updateFrames() {
		controller.view.sizeToFit()
		let size = controller.view.frame.size
		let container = window.bounds.size
		
		switch alignment {
		case .top:
			controller.view.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
			
		case .bottom:
			controller.view.frame = CGRect(x: 0, y: container.height - size.height, width: size.width, height: size.height)
			
		default:
			controller.view.frame = CGRect(x: 0, y: (container.height - size.height) / 2, width: size.width, height: size.height)
		}
		
		window.contentFrame = controller.view.frame
	}
	
	class HostWindow: UIWindow {
		var contentFrame: CGRect = .zero
		
		public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
			guard let hitView = super.hitTest(point, with: event) else { return nil }
			if contentFrame.contains(point) { return hitView }
			return nil
		}
	}
}

extension UIHostingController {
	func disableSafeArea() {
		guard let viewClass = object_getClass(view) else { return }
		
		let viewSubclassName = String(cString: class_getName(viewClass)).appending("_IgnoreSafeArea")
		
		if let viewSubclass = NSClassFromString(viewSubclassName) {
			object_setClass(view, viewSubclass)
		} else {
			guard
				let viewClassNameUtf8 = (viewSubclassName as NSString).utf8String,
				let viewSubclass = objc_allocateClassPair(viewClass, viewClassNameUtf8, 0)
			else { return }
			
			if let method = class_getInstanceMethod(UIView.self, #selector(getter: UIView.safeAreaInsets)) {
				let safeAreaInsets: @convention(block) (AnyObject) -> UIEdgeInsets = { _ in return .zero }
				let imp = imp_implementationWithBlock(safeAreaInsets)
				
				class_addMethod(viewSubclass, #selector(getter: UIView.safeAreaInsets), imp, method_getTypeEncoding(method))
			}
			
			objc_registerClassPair(viewSubclass)
			object_setClass(view, viewSubclass)
		}
	}
}

extension UIWindowScene {
	 static var focused: UIWindowScene? {
		  return UIApplication.shared.connectedScenes
				.first { $0.activationState == .foregroundActive && $0 is UIWindowScene } as? UIWindowScene
	 }
}
#endif
