import Security
import Foundation
import Combine

public actor Keychain {
	public static let lastResultCodeSubject: CurrentValueSubject<OSStatus, Never> = .init(OSStatus(noErr))
	public static var lastResultCode: OSStatus {
		get { lastResultCodeSubject.value }
		set { lastResultCodeSubject.value = newValue }
	}

	
	///Specify an access group that will be used to access keychain items. Access groups can be used to share keychain items between applications. When access group value is nil all application access groups are being accessed. Access group name is used by all functions: set, get, delete and clear.
	
	public static let accessGroupSubject: CurrentValueSubject<String?, Never> = .init(nil)
	public static var accessGroup: String? {
		get { accessGroupSubject.value }
		set { accessGroupSubject.value = newValue }
	}

	public static let keyPrefixSubject: CurrentValueSubject<String?, Never> = .init(nil)
	public static var keyPrefix: String? {
		get { keyPrefixSubject.value }
		set { keyPrefixSubject.value = newValue }
	}

	public static let synchronizableSubject: CurrentValueSubject<Bool, Never> = .init(false)
	public static var synchronizable: Bool {
		get { synchronizableSubject.value }
		set { synchronizableSubject.value = newValue }
	}


	/**
	
	Specifies whether the items can be synchronized with other devices through iCloud. Setting this property to true will add the item to other devices with the `set` method and obtain synchronizable items with the `get` command. Deleting synchronizable items will remove them from all devices. In order for keychain synchronization to work the user must enable "Keychain" in iCloud settings.
	*/
	public var synchronizable: Bool = false
	public var keyPrefix: String?
	
	private static let queue = DispatchQueue(label: "keychain", qos: .userInteractive)
	private init() { }
	
	/**
	
	Stores the text value in the keychain item under the given key.
	
	- parameter key: Key under which the text value is stored in the keychain.
	- parameter value: Text string to be written to the keychain.
	- parameter withAccess: Value that indicates when your app needs access to the text in the keychain item. By default the .AccessibleWhenUnlocked option is used that permits the data to be accessed only while the device is unlocked by the user.
	
	- returns: True if the text was successfully written to the keychain.
	
	*/
	@discardableResult
	static public func set(_ value: String?, forKey key: String, withAccess access: AccessOptions? = nil) -> Bool {
		return set(value?.data(using: String.Encoding.utf8), forKey: key, withAccess: access)
	}
	
	@discardableResult
	static public func set(_ value: Double, forKey key: String, withAccess access: AccessOptions? = nil) -> Bool {
		return set("\(value)", forKey: key, withAccess: access)
	}
	
	/**
	
	Stores the data in the keychain item under the given key.
	
	- parameter key: Key under which the data is stored in the keychain.
	- parameter value: Data to be written to the keychain.
	- parameter withAccess: Value that indicates when your app needs access to the text in the keychain item. By default the .AccessibleWhenUnlocked option is used that permits the data to be accessed only while the device is unlocked by the user.
	
	- returns: True if the text was successfully written to the keychain.
	
	*/
	@discardableResult
	static public func set(_ value: Data?, forKey key: String, withAccess access: AccessOptions? = nil) -> Bool {
		guard let value = value else {
			delete(key)
			return false
		}
		
		self.delete(key) // Delete any existing key before saving it
		
		let accessible = access?.value ?? AccessOptions.defaultOption.value
		
		let prefixedKey = keyWithPrefix(key)
		
		var query: [String: Any] = [
			Constants.keychainClass: kSecClassGenericPassword,
			Constants.attrAccount: prefixedKey,
			Constants.valueData: value,
			Constants.accessible: accessible
		]
		
		query = self.addAccessGroupWhenPresent(query)
		query = self.addSynchronizableIfRequired(query, addingItems: true)
		lastQueryParameters = query
		
		lastResultCode = SecItemAdd(query as CFDictionary, nil)
		
		if lastResultCode == noErr { return true }
		if #available(iOS 14.0, macOS 12, watchOS 9, *) {
			SuiteLogger.error("Failed to store keychain data \(lastResultCode, privacy: .public)")
		}
		return false
	}
	
	/**
	
	Stores the boolean value in the keychain item under the given key.
	
	- parameter key: Key under which the value is stored in the keychain.
	- parameter value: Boolean to be written to the keychain.
	- parameter withAccess: Value that indicates when your app needs access to the value in the keychain item. By default the .AccessibleWhenUnlocked option is used that permits the data to be accessed only while the device is unlocked by the user.
	
	- returns: True if the value was successfully written to the keychain.
	
	*/
	@discardableResult static public func set(_ value: Bool, forKey key: String, withAccess access: AccessOptions? = nil) -> Bool {
		let bytes: [UInt8] = value ? [1] : [0]
		let data = Data(bytes)
		
		return set(data, forKey: key, withAccess: access)
	}
	
	/**
	
	Retrieves the text value from the keychain that corresponds to the given key.
	
	- parameter key: The key that is used to read the keychain item.
	- returns: The text value from the keychain. Returns nil if unable to read the item.
	
	*/
	static public func string(forKey key: String) -> String? {
		if let data = getData(key) {
			
			if let currentString = String(data: data, encoding: .utf8) {
				return currentString
			}
			
			lastResultCode = -67853 // errSecInvalidEncoding
		}
		
		return nil
	}
	
	static public func data(forKey key: String) -> Data? {
		return getData(key)
	}
	
	static public func double(forKey key: String) -> Double? {
		if let data = getData(key) {
			
			if let currentString = String(data: data, encoding: .utf8) {
				return Double(string: currentString)
			}
			
			lastResultCode = -67853 // errSecInvalidEncoding
		}
		
		return nil
	}
	
	/**
	
	Retrieves the data from the keychain that corresponds to the given key.
	
	- parameter key: The key that is used to read the keychain item.
	- returns: The text value from the keychain. Returns nil if unable to read the item.
	
	*/
	static public func getData(_ key: String) -> Data? {
		// The lock prevents the code to be run simlultaneously
		// from multiple threads which may result in crashing
		return queue.sync {
			let prefixedKey = keyWithPrefix(key)
			
			var query: [String: Any] = [
				Constants.keychainClass: kSecClassGenericPassword,
				Constants.attrAccount: prefixedKey,
				Constants.returnData: true,
				Constants.matchLimit: kSecMatchLimitOne
			]
			
			query = self.addAccessGroupWhenPresent(query)
			query = self.addSynchronizableIfRequired(query, addingItems: false)
			lastQueryParameters = query
			
			var result: AnyObject?
			
			lastResultCode = withUnsafeMutablePointer(to: &result) {
				SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
			}
			
			if lastResultCode == noErr { return result as? Data }
			
			return nil
		}
	}
	
	/**
	
	Retrieves the boolean value from the keychain that corresponds to the given key.
	
	- parameter key: The key that is used to read the keychain item.
	- returns: The boolean value from the keychain. Returns nil if unable to read the item.
	
	*/
	static public func getBool(_ key: String) -> Bool? {
		guard let data = getData(key) else { return nil }
		guard let firstBit = data.first else { return nil }
		return firstBit == 1
	}
	
	/**
	
	Deletes the single keychain item specified by the key.
	
	- parameter key: The key that is used to delete the keychain item.
	- returns: True if the item was successfully deleted.
	
	*/
	@discardableResult static public func delete(_ key: String) -> Bool {
		let prefixedKey = keyWithPrefix(key)
		
		var query: [String: Any] = [
			Constants.keychainClass: kSecClassGenericPassword,
			Constants.attrAccount: prefixedKey
		]
		
		query = self.addAccessGroupWhenPresent(query)
		query = self.addSynchronizableIfRequired(query, addingItems: false)
		lastQueryParameters = query
		
		lastResultCode = SecItemDelete(query as CFDictionary)
		
		return lastResultCode == noErr
	}
	
	/**
	
	Deletes all Keychain items used by the app. Note that this method deletes all items regardless of the prefix settings used for initializing the class.
	
	- returns: True if the keychain items were successfully deleted.
	
	*/
	@discardableResult static public func clear() -> Bool {
		var query: [String: Any] = [ kSecClass as String: kSecClassGenericPassword ]
		query = self.addAccessGroupWhenPresent(query)
		query = self.addSynchronizableIfRequired(query, addingItems: false)
		lastQueryParameters = query
		
		lastResultCode = SecItemDelete(query as CFDictionary)
		
		return lastResultCode == noErr
	}
	
	/// Returns the key with currently set prefix.
	static func keyWithPrefix(_ key: String) -> String {
		return "\(keyPrefix ?? "")\(key)"
	}
	
	static func addAccessGroupWhenPresent(_ items: [String: Any]) -> [String: Any] {
		guard let accessGroup else { return items }
		
		var result: [String: Any] = items
		result[Constants.accessGroup] = accessGroup
		return result
	}
	
	/**
	
	Adds kSecAttrSynchronizable: kSecAttrSynchronizableAny` item to the dictionary when the `synchronizable` property is true.
	
	- parameter items: The dictionary where the kSecAttrSynchronizable items will be added when requested.
	- parameter addingItems: Use `true` when the dictionary will be used with `SecItemAdd` method (adding a keychain item). For getting and deleting items, use `false`.
	
	- returns: the dictionary with kSecAttrSynchronizable item added if it was requested. Otherwise, it returns the original dictionary.
	
	*/
	static func addSynchronizableIfRequired(_ items: [String: Any], addingItems: Bool) -> [String: Any] {
		if !synchronizable { return items }
		var result = items
		result[Constants.attrSynchronizable] = addingItems == true ? true : kSecAttrSynchronizableAny
		return result
	}
	
	static var lastQueryParameters: [String: Any]? // Used by tests
}

extension Keychain {
	public struct Constants {
		/// Specifies a Keychain access group. Used for sharing Keychain items between apps.
		public static var accessGroup: String { return toString(kSecAttrAccessGroup) }
		
		/**
		
		A value that indicates when your app needs access to the data in a keychain item. The default value is AccessibleWhenUnlocked. For a list of possible values, see AccessOptions.
		
		*/
		public static var accessible: String { return toString(kSecAttrAccessible) }
		
		/// Used for specifying a String key when setting/getting a Keychain value.
		public static var attrAccount: String { return toString(kSecAttrAccount) }
		
		/// Used for specifying synchronization of keychain items between devices.
		public static var attrSynchronizable: String { return toString(kSecAttrSynchronizable) }
		
		/// An item class key used to construct a Keychain search dictionary.
		public static var keychainClass: String { return toString(kSecClass) }
		
		/// Specifies the number of values returned from the keychain. The library only supports single values.
		public static var matchLimit: String { return toString(kSecMatchLimit) }
		
		/// A return data type used to get the data from the Keychain.
		public static var returnData: String { return toString(kSecReturnData) }
		
		/// Used for specifying a value when setting a Keychain value.
		public static var valueData: String { return toString(kSecValueData) }
		
		static func toString(_ value: CFString) -> String {
			return value as String
		}
	}
	
	public enum AccessOptions {
		
		/**
		
		The data in the keychain item can be accessed only while the device is unlocked by the user.
		
		This is recommended for items that need to be accessible only while the application is in the foreground. Items with this attribute migrate to a new device when using encrypted backups.
		
		This is the default value for keychain items added without explicitly setting an accessibility constant.
		
		*/
		case accessibleWhenUnlocked
		
		/**
		
		The data in the keychain item can be accessed only while the device is unlocked by the user.
		
		This is recommended for items that need to be accessible only while the application is in the foreground. Items with this attribute do not migrate to a new device. Thus, after restoring from a backup of a different device, these items will not be present.
		
		*/
		case accessibleWhenUnlockedThisDeviceOnly
		
		/**
		
		The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by the user.
		
		After the first unlock, the data remains accessible until the next restart. This is recommended for items that need to be accessed by background applications. Items with this attribute migrate to a new device when using encrypted backups.
		
		*/
		case accessibleAfterFirstUnlock
		
		/**
		
		The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by the user.
		
		After the first unlock, the data remains accessible until the next restart. This is recommended for items that need to be accessed by background applications. Items with this attribute do not migrate to a new device. Thus, after restoring from a backup of a different device, these items will not be present.
		
		*/
		case accessibleAfterFirstUnlockThisDeviceOnly
		
		/**
		
		The data in the keychain item can always be accessed regardless of whether the device is locked.
		
		This is not recommended for application use. Items with this attribute migrate to a new device when using encrypted backups.
		
		*/
		case accessibleAlways
		
		/**
		
		The data in the keychain can only be accessed when the device is unlocked. Only available if a passcode is set on the device.
		
		This is recommended for items that only need to be accessible while the application is in the foreground. Items with this attribute never migrate to a new device. After a backup is restored to a new device, these items are missing. No items can be stored in this class on devices without a passcode. Disabling the device passcode causes all items in this class to be deleted.
		
		*/
		case accessibleWhenPasscodeSetThisDeviceOnly
		
		/**
		
		The data in the keychain item can always be accessed regardless of whether the device is locked.
		
		This is not recommended for application use. Items with this attribute do not migrate to a new device. Thus, after restoring from a backup of a different device, these items will not be present.
		
		*/
		case accessibleAlwaysThisDeviceOnly
		
		static var defaultOption: AccessOptions {
			return .accessibleAlways
		}
		
		var value: String {
			switch self {
			case .accessibleWhenUnlocked: return self.toString(kSecAttrAccessibleWhenUnlocked)
			case .accessibleWhenUnlockedThisDeviceOnly: return self.toString(kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
			case .accessibleAfterFirstUnlock: return self.toString(kSecAttrAccessibleAfterFirstUnlock)
			case .accessibleAfterFirstUnlockThisDeviceOnly: return self.toString(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
			case .accessibleAlways: return self.toString(kSecAttrAccessibleAfterFirstUnlock)
			case .accessibleWhenPasscodeSetThisDeviceOnly: return self.toString(kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly)
			case .accessibleAlwaysThisDeviceOnly: return self.toString(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
			}
		}
		
		func toString(_ value: CFString) -> String {
			return Constants.toString(value)
		}
	}
}


