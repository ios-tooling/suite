//
//  AsyncButton.swift
//  
//
//  Created by Ben Gottlieb on 1/5/22.
//

#if canImport(Combine)
import SwiftUI

public struct ButtonIsPerformingActionKey: PreferenceKey {
	public static var defaultValue = false
	public static func reduce(value: inout Bool, nextValue: () -> Bool) {
		value = value || nextValue()
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
public struct AsyncButton<Label: View, Busy: View>: View {
	var action: () async throws -> Void
	@ViewBuilder var label: () -> Label
	@ViewBuilder var  busy: () -> Busy
	
	@State private var isPerformingAction = false
	var role: Any?
	
	public init(action: @escaping () async throws -> Void, @ViewBuilder label: @escaping () -> Label, @ViewBuilder busy: @escaping () -> Busy) {
		self.action = action
		self.label = label
		self.busy = busy
	}
	
	@available(macOS 12.0, iOS 15.0, watchOS 8.0, *)
	public init(role: ButtonRole?, action: @escaping () async throws -> Void, @ViewBuilder label: @escaping () -> Label, @ViewBuilder busy: @escaping () -> Busy) {
		self.action = action
		self.label = label
		self.role = role
		self.busy = busy
	}
	
	public var body: some View {
		if #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) {
			Button(role: role as? ButtonRole, action: { performAction() }) { buttonLabel }
				.disabled(isPerformingAction)
				.preference(key: ButtonIsPerformingActionKey.self, value: isPerformingAction)
		} else {
			Button(action: { performAction() }) { buttonLabel }
				.disabled(isPerformingAction)
				.preference(key: ButtonIsPerformingActionKey.self, value: isPerformingAction)
		}
	}
	
	func performAction() {
		isPerformingAction = true
		Task.detached {
			do {
				try await action()
			} catch {
				SuiteLogger.instance.log(error: error, "AsyncButton action failed", level: .loud)
			}
			await MainActor.run { isPerformingAction = false }
		}
	}
	
	var buttonLabel: some View {
		ZStack {
			label()
				.opacity(isPerformingAction ? 0.2 : 1)
			busy()
				.opacity(isPerformingAction ? 1 : 0)
		}
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 8, *)
extension AsyncButton where Label == AsyncButtonLabel, Busy == AsyncButtonBusyLabel {
	public init(_ title: LocalizedStringKey? = nil, systemImage: String? = nil, spinnerScale: Double = 1.0, action: @escaping () async throws -> Void) {
		self.action = action
		self.label = { AsyncButtonLabel(title: title, systemImage: systemImage) }
		self.busy = { AsyncButtonBusyLabel(spinnerScale: spinnerScale) }
	}
}

@available(macOS 12, iOS 15.0, tvOS 13, watchOS 8, *)
extension AsyncButton where Label == AsyncButtonLabel, Busy == AsyncButtonBusyLabel {
	public init(_ title: LocalizedStringKey? = nil, systemImage: String? = nil, role: ButtonRole, spinnerScale: Double = 1.0, action: @escaping () async throws -> Void) {
		self.action = action
		self.role = role
		self.label = { AsyncButtonLabel(title: title, systemImage: systemImage) }
		self.busy = { AsyncButtonBusyLabel(spinnerScale: spinnerScale) }
	}
}

@available(macOS 12, iOS 15.0, tvOS 13, watchOS 8, *)
extension AsyncButton where Busy == AsyncButtonBusyLabel {
	public init(role: ButtonRole? = nil, action: @escaping () async throws -> Void, spinnerScale: Double = 1.0, @ViewBuilder label: @escaping () -> Label) {
		self.action = action
		self.role = role
		self.label = label
		self.busy = { AsyncButtonBusyLabel(spinnerScale: spinnerScale) }
	}
}

public struct AsyncButtonLabel: View {
	let title: LocalizedStringKey?
	let systemImage: String?
	
	public var body: some View {
		HStack {
			if let title { Text(title) }
			if let systemImage { 
				if #available(macOS 11.0, *) {
					Image(systemName: systemImage)
				}
			}
		}
	}
}

public struct AsyncButtonBusyLabel: View {
	var spinnerColor = Color.white
	var spinnerScale: Double

	public var body: some View {
		spinner
	}
	
	@ViewBuilder var spinner: some View {
		if #available(OSX 13, iOS 16, watchOS 9, *) {
			ProgressView()
				.scaleEffect(spinnerScale)
				.tint(spinnerColor)
		} else if #available(OSX 11, iOS 14.0, watchOS 7, *) {
			ProgressView()
				.scaleEffect(spinnerScale)
				.colorInvert()
		}
	}

}
#endif
