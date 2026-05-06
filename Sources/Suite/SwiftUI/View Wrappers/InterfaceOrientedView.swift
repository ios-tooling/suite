//
//  ScreenOrientedView.swift
//
//  Created by ben on 4/6/20.
//  Copyright © 2020 Ben Gottlieb. All rights reserved.
//

#if canImport(UIKit) && !os(watchOS) && !os(visionOS) && !os(tvOS)
import SwiftUI
import UIKit

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
@available(iOSApplicationExtension, unavailable)
@MainActor public class OrientationWatcher: NSObject, ObservableObject {
	public static var instance = OrientationWatcher()

	public static func setup(windowScene: UIWindowScene) {
		self.instance = OrientationWatcher(initialOrientation: windowScene.interfaceOrientation)
	}

	init(initialOrientation: UIInterfaceOrientation = .unknown) {
		self.orientation = initialOrientation
		super.init()
		NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
	}

	@objc private func orientationDidChange() {
		if let newOrientation = UIApplication.shared.currentScene?.interfaceOrientation, newOrientation != self.orientation {
			self.orientation = newOrientation
		}
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	nonisolated(unsafe) public private(set) var orientation: UIInterfaceOrientation { didSet {
		objectWillChange.sendOnMain()
	}}

	nonisolated public var isLandscape: Bool { return self.orientation.isLandscape }
	public override var description: String { return self.isLandscape ? "Landscape" : "Portrait" }
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
@available(iOSApplicationExtension, unavailable)
public struct InterfaceOrientedView<Contents: View>: View {
	@ObservedObject var orientationWatcher = OrientationWatcher.instance

	let contents: () -> Contents
	public init(contents: @escaping () -> Contents) {
		self.contents = contents
	}

	public var body: some View {
		contents()
			.id(orientationWatcher.isLandscape)
	}
}

#endif
