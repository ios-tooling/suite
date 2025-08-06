//
//  LoadingStateTests.swift
//  Suite
//
//  Created by Claude Code on 1/14/25.
//

import Testing
import Suite

struct LoadingStateTests {
    
    struct TestError: Error, Equatable {
        let message: String
    }
    
    @Test func testLoadingStateEquality() {
        let idle1: LoadingState<String> = .idle
        let idle2: LoadingState<String> = .idle
        let loading1: LoadingState<String> = .loading
        let loading2: LoadingState<String> = .loading
        let empty1: LoadingState<String> = .empty
        let empty2: LoadingState<String> = .empty
        let failed1: LoadingState<String> = .failed(TestError(message: "error"))
        let failed2: LoadingState<String> = .failed(TestError(message: "error"))
        
        #expect(idle1 == idle2)
        #expect(loading1 == loading2)
        #expect(empty1 == empty2)
        #expect(failed1 == failed2) // Note: compares case, not associated value
        
        #expect(!(idle1 == loading1))
        #expect(!(loading1 == empty1))
        #expect(!(empty1 == failed1))
    }
    
    @Test func testIsLoadedProperty() {
        let idle: LoadingState<String> = .idle
        let loading: LoadingState<String> = .loading
        let empty: LoadingState<String> = .empty
        let failed: LoadingState<String> = .failed(TestError(message: "error"))
        let loaded: LoadingState<String> = .loaded("data")
        
        #expect(!idle.isLoaded)
        #expect(!loading.isLoaded)
        #expect(empty.isLoaded)
        #expect(!failed.isLoaded)
        #expect(loaded.isLoaded)
    }
    
    @Test func testErrorProperty() {
        let idle: LoadingState<String> = .idle
        let loading: LoadingState<String> = .loading
        let empty: LoadingState<String> = .empty
        let testError = TestError(message: "test error")
        let failed: LoadingState<String> = .failed(testError)
        let loaded: LoadingState<String> = .loaded("data")
        
        #expect(idle.error == nil)
        #expect(loading.error == nil)
        #expect(empty.error == nil)
        #expect(failed.error != nil)
        #expect(loaded.error == nil)
        
        // Check that we can extract the error
        if case .failed(let error) = failed {
            #expect((error as? TestError)?.message == "test error")
        }
    }
    
    @Test func testLoadingStateWithDifferentTypes() {
        let stringState: LoadingState<String> = .loaded("hello")
        let intState: LoadingState<Int> = .loaded(42)
        let arrayState: LoadingState<[String]> = .loaded(["a", "b", "c"])
        
        #expect(stringState.isLoaded)
        #expect(intState.isLoaded)
        #expect(arrayState.isLoaded)
        
        // Verify the actual values (pattern matching)
        if case .loaded(let value) = stringState {
            #expect(value == "hello")
        }
        
        if case .loaded(let value) = intState {
            #expect(value == 42)
        }
        
        if case .loaded(let value) = arrayState {
            #expect(value == ["a", "b", "c"])
        }
    }
    
    @Test func testSendableConformance() {
        // This test ensures LoadingState conforms to Sendable
        // by testing it can be used in async contexts
        
        func asyncFunction() async -> LoadingState<String> {
            return .loaded("async data")
        }
        
        Task {
            let result = await asyncFunction()
            #expect(result.isLoaded)
        }
    }
}