//
//  NonIsolatedWrapper.swift
//  Suite
//
//  Created by Ben Gottlieb on 7/28/24.
//

import Foundation

@available(iOS 16.0, watchOS 9, macOS 14, *)
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

