//
//  WrappedView.swift
//
//
//  Created by Ben Gottlieb on 2/4/24.
//

import SwiftUI

#if os(iOS) || os(visionOS)
public struct WrappedView<Content: UIView>: UIViewRepresentable {
	let view: Content
	
	public init(view: Content) {
		self.view = view
	}
	
	public func updateUIView(_ uiView: Content, context: Context) { }
	
	public func makeUIView(context: Context) -> Content {
		view
	}
}
#endif

#if os(macOS)
public struct WrappedView<Content: NSView>: NSViewRepresentable {
	let view: Content
	
	public init(view: Content) {
		self.view = view
	}
	
	public func updateNSView(_ nsView: Content, context: Context) { }
	
	public func makeNSView(context: Context) -> Content {
		view
	}
}

#endif
