//
//  AppLifecycleEvent.swift
//  Suite
//
//  Created by Ben Gottlieb on 6/15/26.
//

import Foundation

#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

/// One or more system-defined points in the app's lifecycle that ``AppLifecycleMonitor`` can run code at.
public struct AppLifecycleEvent: OptionSet, Sendable {
	public let rawValue: Int
	public init(rawValue: Int) { self.rawValue = rawValue }

	/// The app has launched. The launch notification is posted during startup, before any
	/// observer can register, so ``AppLifecycleMonitor`` runs `.launch` handlers immediately
	/// on registration instead of observing a notification.
	public static let launch = AppLifecycleEvent(rawValue: 1 << 0)
	/// The app became active (returned to the foreground).
	public static let resume = AppLifecycleEvent(rawValue: 1 << 1)
	/// The app entered the background (resigned active on macOS).
	public static let background = AppLifecycleEvent(rawValue: 1 << 2)
	/// The app is about to terminate.
	public static let terminate = AppLifecycleEvent(rawValue: 1 << 3)

	/// The platform notifications corresponding to the events in this set. `.launch` is
	/// excluded — it has no usable notification and is fired immediately on registration.
	var notificationNames: [Notification.Name] {
		var names: [Notification.Name] = []
		#if os(iOS) || os(tvOS) || os(visionOS)
		if contains(.resume) { names.append(UIApplication.didBecomeActiveNotification) }
		if contains(.background) { names.append(UIApplication.didEnterBackgroundNotification) }
		if contains(.terminate) { names.append(UIApplication.willTerminateNotification) }
		#elseif os(macOS)
		if contains(.resume) { names.append(NSApplication.didBecomeActiveNotification) }
		if contains(.background) { names.append(NSApplication.willResignActiveNotification) }
		if contains(.terminate) { names.append(NSApplication.willTerminateNotification) }
		#elseif os(watchOS)
		if #available(watchOS 7.0, *) {
			if contains(.resume) { names.append(WKApplication.didBecomeActiveNotification) }
			if contains(.background) { names.append(WKApplication.didEnterBackgroundNotification) }
		}
		#endif
		return names
	}
}
