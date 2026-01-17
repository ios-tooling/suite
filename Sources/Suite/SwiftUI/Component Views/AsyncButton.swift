//
//  AsyncButton.swift
//  
//
//  Created by Ben Gottlieb on 1/5/22.
//

#if canImport(Combine)
import SwiftUI

public struct ButtonIsPerformingActionKey: PreferenceKey {
	nonisolated public static let defaultValue = false
	public static func reduce(value: inout Bool, nextValue: () -> Bool) {
		value = value || nextValue()
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
@MainActor public struct AsyncButton<Label: View, Busy: View>: View {
	var action: @MainActor () async throws -> Void
	@ViewBuilder var label: () -> Label
	@ViewBuilder var busy: () -> Busy
	@State var task: Task<Void, Error>?
	var title: LocalizedStringKey?
	var systemImage: String?
	
	@State private var isPerformingAction = false
	var role: Any?
	let shouldCancelOnDisappear: Bool
	
	public init(shouldCancelOnDisappear: Bool = false, _ title: LocalizedStringKey? = nil, systemImage: String? = nil, action: @MainActor @escaping () async throws -> Void, @ViewBuilder label: @escaping () -> Label, @ViewBuilder busy: @escaping () -> Busy) {
		self.action = action
		self.label = label
		self.title = title
		self.systemImage = systemImage
		self.busy = busy
		self.shouldCancelOnDisappear = shouldCancelOnDisappear
	}
	
	@available(macOS 12.0, iOS 15.0, watchOS 8.0, *)
	public init(shouldCancelOnDisappear: Bool = false, role: ButtonRole?, action: @MainActor @escaping () async throws -> Void, @ViewBuilder label: @escaping () -> Label, @ViewBuilder busy: @escaping () -> Busy) {
		self.action = action
		self.label = label
		self.role = role
		self.busy = busy
		self.shouldCancelOnDisappear = shouldCancelOnDisappear
	}
	
	public var body: some View {
		if #available(macOS 12.0, iOS 15.0, watchOS 8.0, *) {
			if let title, let systemImage {
				Button(title, systemImage: systemImage, role: role as? ButtonRole, action: { performAction() })
			} else {
				Button(role: role as? ButtonRole, action: { performAction() }) { buttonLabel }
					.disabled(isPerformingAction)
					.preference(key: ButtonIsPerformingActionKey.self, value: isPerformingAction)
					.onDisappear { cleanUp() }
			}
		} else {
			Button(action: { performAction() }) { buttonLabel }
				.disabled(isPerformingAction)
				.preference(key: ButtonIsPerformingActionKey.self, value: isPerformingAction)
				.onDisappear { cleanUp() }
		}
	}
	
	func cleanUp() {
		if shouldCancelOnDisappear { task?.cancel() }
	}
	
	func performAction() {
		let taskWrapper = $task
		isPerformingAction = true
		let action = action
		let isPerformingAction = $isPerformingAction
		
		taskWrapper.wrappedValue = Task.detached {
			do {
				try await action()
			} catch {
				if #available(iOS 14.0, macOS 12, watchOS 9, *) {
					SuiteLogger.warning("AsyncButton action failed \(error, privacy: .public)")
				}
			}
			await MainActor.run {
				isPerformingAction.wrappedValue = false
				taskWrapper.wrappedValue = nil
			}
		}
	}
	
	var buttonLabel: some View {
		ZStack {
			label()
				.opacity(isPerformingAction ? 0.2 : 1)
			busy()
				.layoutPriority(-1)
				.opacity(isPerformingAction ? 1 : 0)
		}
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13, watchOS 8, *)
extension AsyncButton where Label == AsyncButtonLabel, Busy == AsyncButtonBusyLabel {
	public init(_ title: LocalizedStringKey? = nil, systemImage: String? = nil, shouldCancelOnDisappear: Bool = false, action: @MainActor @escaping () async throws -> Void) {
		self.action = action
		self.title = title
		self.systemImage = systemImage
		self.label = { AsyncButtonLabel(title: title, systemImage: systemImage) }
		self.busy = { AsyncButtonBusyLabel(title: title) }
		self.shouldCancelOnDisappear = shouldCancelOnDisappear
	}
}

@available(macOS 12, iOS 15.0, tvOS 13, watchOS 8, *)
extension AsyncButton where Label == AsyncButtonLabel, Busy == AsyncButtonBusyLabel {
	public init(_ title: LocalizedStringKey? = nil, systemImage: String? = nil, role: ButtonRole, shouldCancelOnDisappear: Bool = false, action: @MainActor @escaping () async throws -> Void) {
		self.action = action
		self.role = role
		self.label = { AsyncButtonLabel(title: title, systemImage: systemImage) }
		self.busy = { AsyncButtonBusyLabel(title: title) }
		self.shouldCancelOnDisappear = shouldCancelOnDisappear
	}
}

@available(macOS 12, iOS 15.0, tvOS 13, watchOS 8, *)
extension AsyncButton where Busy == AsyncButtonBusyLabel {
	public init(role: ButtonRole? = nil, shouldCancelOnDisappear: Bool = false, action: @MainActor @escaping () async throws -> Void, @ViewBuilder label: @MainActor @escaping () -> Label) {
		self.action = action
		self.role = role
		self.label = label
		self.busy = { AsyncButtonBusyLabel(title: nil) }
		self.shouldCancelOnDisappear = shouldCancelOnDisappear
	}
}

public struct AsyncButtonLabel: View {
	let title: LocalizedStringKey?
	let systemImage: String?
	
	public var body: some View {
		HStack {
			if let title { Text(title) }
			if let systemImage { 
				if #available(macOS 11.0, iOS 14.0, watchOS 7.0, *) {
					Image(systemName: systemImage)
				}
			}
		}
	}
}

public struct AsyncButtonBusyLabel: View {
	let title: LocalizedStringKey?
	var spinnerColor = Color.white

	public var body: some View {
		spinner
	}
	
	@ViewBuilder var spinner: some View {
		if #available(OSX 13, iOS 16, watchOS 9, *) {
			ViewThatFits {
				ProgressView().scaleEffect(1.0)
				ProgressView().scaleEffect(0.5)
			}
			.tint(spinnerColor)
		} else if #available(OSX 11, iOS 14.0, watchOS 7, *) {
			ProgressView()
				.colorInvert()
		}
	}

}
#endif
