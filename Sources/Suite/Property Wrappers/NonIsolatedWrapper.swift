//
//  NonIsolatedWrapper.swift
//  Suite
//
//  Created by Ben Gottlieb on 7/28/24.
//

import Foundation

public typealias os_unfair_lock_pointer = UnsafeMutablePointer<os_unfair_lock_s>

@MainActor @propertyWrapper public struct NonIsolatedValue<Value: Sendable>: DynamicProperty {
    public init(_ wrappedValue: Value) {
        _value = State(wrappedValue: ThreadsafeMutex(wrappedValue))
    }
    
    @State private var value: ThreadsafeMutex<Value>
    
    public var wrappedValue: Value {
        get {
            value.value
        }
        
        set {
            value.value = newValue
        }
    }
}

