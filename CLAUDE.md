# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Testing
```bash
# Build the entire package
swift build

# Run all tests
swift test

# Run tests with verbose output
swift test --verbose

# Run specific test target
swift test --filter SuiteTests

# Run a specific test method
swift test --filter SuiteTests.MacroTests/testPreferenceKey

# Build in release mode
swift build -c release
```

### Code Quality
The package has minimal external dependencies (only swift-syntax for macros). Lint and format using your IDE's Swift formatting tools.

## Architecture Overview

### Multi-Platform Framework Structure
Suite is a comprehensive utility framework targeting iOS 13+, macOS 10.15+, and watchOS 6+. The codebase uses extensive conditional compilation for platform-specific implementations while providing unified APIs.

### Core Architectural Patterns

#### 1. Extension-First Design
The framework extends Apple's core frameworks systematically:
- `Sources/Suite/Foundation/` - Core Swift and Foundation extensions
- `Sources/Suite/SwiftUI/` - SwiftUI components and extensions  
- `Sources/Suite/UIKit/` - UIKit utilities for iOS
- `Sources/Suite/AppKit/` - macOS-specific AppKit extensions
- `Sources/Suite/Core Graphics/` - Graphics and drawing utilities

#### 2. Macro System (`Sources/SuiteMacrosImpl/`)
Five Swift macros eliminate boilerplate code:
- `@GeneratedEnvironmentKey` - Auto-generates SwiftUI EnvironmentKey types
- `@GeneratedPreferenceKey` - Creates SwiftUI PreferenceKey with reduce functions
- `@AppSettings` - UserDefaults-backed settings with ObservableObject support
- `@AppSettingsProperty` - Individual UserDefaults properties with change notifications
- `@NonisolatedContainer` - Thread-safe property access using locks

The macro implementations depend on the runtime infrastructure in `Sources/Suite/Types/UserDefaultsContainer.swift` and `Sources/Suite/Property Wrappers/NonIsolatedWrapper.swift`.

#### 3. State Management Patterns
- **LoadingState<Value>** - Type-safe async operation states (idle, loading, empty, failed, loaded)
- **ObservableValue<Value>** - Bridges Combine publishers to SwiftUI's reactive system
- **Loadable protocol** - Standardized interface for async data sources

#### 4. Platform Abstraction
**Gestalt** (`Sources/Suite/Types/Gestalt.swift`) provides unified platform detection:
- Distribution detection (development, TestFlight, App Store)
- Device type identification across platforms
- Debug level management for different build configurations

### Key Design Principles

#### Conditional Compilation Strategy
Extensive use of `#if os()`, `#if canImport()`, and `@available()` to:
- Provide platform-specific implementations
- Gracefully degrade features based on platform capabilities
- Maintain single codebase across all Apple platforms

#### Swift Concurrency Integration
- All async components use modern async/await patterns
- Sendable conformance throughout for thread safety
- MainActor integration for UI components
- nonisolated access patterns for cross-actor communication

#### Module Export Pattern
`Sources/Suite/ExportedModules.swift` re-exports SwiftUI and Combine, allowing clients to import Suite instead of individual frameworks.

### Component Architecture

#### SwiftUI Components (`Sources/Suite/SwiftUI/`)
- **Component Views/**: Reusable UI components (AsyncButton, LoadingView, etc.)
- **View Wrappers/**: Higher-order views that wrap content (AsyncContainerView, PublisherView)
- **Extensions/**: Extensions to existing SwiftUI types for enhanced functionality
- **Observers/**: Reactive components that observe system state changes

#### Property Wrappers (`Sources/Suite/Property Wrappers/`)
- **CodableAppStorage**: UserDefaults storage with JSON encoding for complex types
- **CodableFileStorage**: File-based storage with JSON encoding  
- **ReadyFlag**: Async coordination primitives

#### JSON System (`Sources/Suite/Utilities/JSON/`)
Unified JSON handling with type-safe APIs:
- `JSON` enum with associated values for different JSON types
- Codable integration for seamless encoding/decoding
- Extensions for pretty printing and manipulation

### Testing Structure

Tests are minimal but focused:
- `Tests/SuiteTests/MacroTests.swift` - Macro expansion testing using SwiftSyntaxMacrosTestSupport
- `Tests/SuiteTests/` - Unit tests for core functionality (JSON, CoreGraphics, Dictionary extensions)

When adding tests, use the existing XCTest structure and follow the pattern of testing public APIs rather than internal implementation details.

### Working with Macros

When modifying macro implementations:
1. Update the implementation in `Sources/SuiteMacrosImpl/`
2. Update the macro declaration in `Sources/Suite/SuiteMacros.swift` if needed
3. Add or update tests in `Tests/SuiteTests/MacroTests.swift`
4. Test macro expansion using `swift test --filter MacroTests`

The macro system uses SwiftSyntax for AST manipulation and follows Apple's macro development patterns.