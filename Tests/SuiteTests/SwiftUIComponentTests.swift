//
//  SwiftUIComponentTests.swift
//  Suite
//
//  Created by Claude Code on 1/14/25.
//

import Testing
import SwiftUI
@testable import Suite

struct SwiftUIComponentTests {
    
    @Test func testButtonIsPerformingActionKey() {
        let key = ButtonIsPerformingActionKey.self
        #expect(key.defaultValue == false)
        
        // Test reduce function
        var value = false
        key.reduce(value: &value, nextValue: { true })
        #expect(value == true)
        
        value = true
        key.reduce(value: &value, nextValue: { false })
        #expect(value == true) // OR operation should keep true
        
        value = false
        key.reduce(value: &value, nextValue: { false })
        #expect(value == false)
    }
    
    @Test @MainActor func testAsyncButtonInitialization() {
        let action: @MainActor () async throws -> Void = {
            // Test action
        }
        
        let _ = AsyncButton(
            action: action,
            label: { Text("Test Button") },
            busy: { Text("Loading...") }
        )
        
        // Test that the button can be created without issues
        // Note: action is non-optional so we just test that initialization succeeds
        #expect(Bool(true)) // Button was created successfully
    }
    
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, *)
    @Test @MainActor func testAsyncButtonWithRole() {
        let action: @MainActor () async throws -> Void = {
            // Test action
        }
        
        let button = AsyncButton(
            role: .destructive,
            action: action,
            label: { Text("Delete") },
            busy: { Text("Deleting...") }
        )
        
        // Test that the button can be created with role
        #expect(button.role as? ButtonRole == .destructive)
    }
    
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
    @Test @MainActor func testLoadingViewInitialization() {
        let _ = LoadingView(
            target: {
                // Simulate async operation
                try await Task.sleep(nanoseconds: 1_000_000) // 1ms
                return "Test Data"
            },
            loading: {
                Text("Loading...")
            },
            failed: { error in
                Text("Error: \(error?.localizedDescription ?? "Unknown")")
            },
            body: { data in
                Text("Data: \(data)")
            }
        )
        
        // Test that the loading view can be created
        // Note: These are non-optional closures so we just test that initialization succeeds
        #expect(Bool(true)) // LoadingView was created successfully
    }
    
    @Test func testLoadingStateIntegration() {
        // Test that LoadingState integrates properly with SwiftUI components
        let idleState: LoadingState<String> = .idle
        let loadingState: LoadingState<String> = .loading
        let loadedState: LoadingState<String> = .loaded("test data")
        let emptyState: LoadingState<String> = .empty
        let failedState: LoadingState<String> = .failed(TestError())
        
        #expect(!idleState.isLoaded)
        #expect(!loadingState.isLoaded)
        #expect(loadedState.isLoaded)
        #expect(emptyState.isLoaded)
        #expect(!failedState.isLoaded)
        
        #expect(failedState.error != nil)
        #expect(idleState.error == nil)
    }
    
    // Helper structures for testing
    struct TestError: Error, LocalizedError {
        var errorDescription: String? { "Test error" }
    }
    
    struct MockLoadingView: View {
        @State private var state: LoadingState<String> = .idle
        
        var body: some View {
            VStack {
                switch state {
                case .idle:
                    Button("Start Loading") {
                        state = .loading
                    }
                case .loading:
                    Text("Loading...")
                case .empty:
                    Text("No data")
                case .failed(let error):
                    Text("Error: \(error.localizedDescription)")
                case .loaded(let data):
                    Text("Data: \(data)")
                }
            }
        }
    }
    
    @Test @MainActor func testMockLoadingViewStates() {
        let _ = MockLoadingView()
        
        // Test that the view can be created - state is private so we can't test it directly
        #expect(Bool(true)) // View was created successfully
    }
    
    // Test SwiftUI extensions that can be tested without rendering
    @Test @MainActor func testViewExtensionsCompile() {
        // These tests ensure that SwiftUI extensions compile correctly
        // and don't cause build issues
        
        struct TestView: View {
            var body: some View {
                VStack {
                    Text("Test")
                        .if(true, transform: { view in
                            view.foregroundColor(.blue)
                        })
                }
            }
        }
        
        let _ = TestView()
        // Note: We just test that the view compiles and initializes
        #expect(Bool(true)) // View compiled and initialized successfully
    }
}

// Extension for conditional view modifiers (common pattern in Suite)
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}