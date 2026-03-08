//
//  CrashPad.swift
//  Suite
//
//  Created by Ben Gottlieb on 3/8/26.
//

import Foundation

/// CrashPad will let us determine if our app crashed on launch last time you ran, in case we don't want to restore some state.
/// CrashPad.didLaunchSafely should be called just before restoring state. If it returns false, don't restore the state
/// Optionally, launchedSafely(interval:) can be called with a different interval if launches take more or less time


public struct CrashPad {
	static let settingsKey = "CrashPad-didFailToLaunch"
	
	static public var didLaunchSafely: Bool { launchedSafely(interval: 3.0) }
	
	static public func launchedSafely(interval: TimeInterval) -> Bool {
		if UserDefaults.standard.bool(forKey: settingsKey) {
			UserDefaults.standard.set(false, forKey: settingsKey)
			return false
		}
		
		UserDefaults.standard.set(true, forKey: settingsKey)
		Task {
			try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
			UserDefaults.standard.set(false, forKey: settingsKey)
		}
		return true
	}
}
