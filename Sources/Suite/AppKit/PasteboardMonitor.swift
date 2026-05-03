//
//  PasteboardMonitor.swift
//  Suite
//
//  Created by Ben Gottlieb on 3/27/26.
//

#if os(macOS)
import AppKit
import Observation

@available(macOS 14, *)
@Observable @MainActor public final class PasteboardMonitor {
	public static let instance = PasteboardMonitor()

	public private(set) var string: String?
	public private(set) var url: URL?

	private var lastChangeCount: Int
	private var timer: Timer?

	public init(pollInterval: TimeInterval = 1) {
		let pb = NSPasteboard.general
		lastChangeCount = pb.changeCount
		string = pb.string(forType: .string)
		url = pb.string(forType: .string).flatMap { $0.mayBeURL ? URL(string: $0) : nil }
		startPolling(interval: pollInterval)
		observeAppActivation()
	}

	private func startPolling(interval: TimeInterval) {
		timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
			guard let self else {
				timer.invalidate()
				return
			}
			Task { @MainActor in self.checkForChanges() }
		}
	}

	private func observeAppActivation() {
		NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
			Task { @MainActor in self?.checkForChanges() }
		}
	}

	private func checkForChanges() {
		let pb = NSPasteboard.general
		guard pb.changeCount != lastChangeCount else { return }
		lastChangeCount = pb.changeCount

		let newString = pb.string(forType: .string)
		string = newString
		url = newString.flatMap { $0.mayBeURL ? URL(string: $0) : nil }
	}
}
#endif
