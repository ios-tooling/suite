import Foundation
import SwiftUI

public final class SharedDependencyManager: @unchecked Sendable {
	public static let instance = SharedDependencyManager()
	
	private var dependencies: [String: Any] = [:]
	private var lock = os_unfair_lock_s()
	
	private init() {}
	
	public func register<T>(_ dependency: T, allowReplacement: Bool = false) {
		let key = String(describing: T.self)
		os_unfair_lock_lock(&lock)
		defer { os_unfair_lock_unlock(&lock) }
		if !allowReplacement, dependencies[key] != nil {
			fatalError("Trying to re-register a dependency")
		}
		dependencies[key] = dependency
	}
	
	public func resolve<T>(_ type: T.Type) -> T? {
		let key = String(describing: type)
		os_unfair_lock_lock(&lock)
		defer { os_unfair_lock_unlock(&lock) }
		return dependencies[key] as? T
	}
	
	public func unregister<T>(_ type: T.Type) {
		let key = String(describing: type)
		os_unfair_lock_lock(&lock)
		defer { os_unfair_lock_unlock(&lock) }
		dependencies.removeValue(forKey: key)
	}
	
	public func clear() {
		os_unfair_lock_lock(&lock)
		defer { os_unfair_lock_unlock(&lock) }
		dependencies.removeAll()
	}
}

@propertyWrapper
public struct SharedDependency<T> {
	private let type: T.Type
	
	public init() {
		self.type = T.self
	}
	
	public init(_ type: T.Type) {
		self.type = type
	}
	
	public var wrappedValue: T {
		guard let dependency = SharedDependencyManager.instance.resolve(type) else {
			fatalError("Dependency of type \(type) not registered. Please register it using SharedDependencyManager.instance.register()")
		}
		return dependency
	}
}
