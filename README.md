# Suite

A comprehensive Swift utility framework for iOS 13+, macOS 10.15+, watchOS 6+, tvOS 13+.

`import Suite` re-exports SwiftUI and Combine — no separate imports needed.

## Quick Reference

- [Building & Testing](#building--testing)
- [Source Layout](#source-layout)
- [Macros](#macros)
- [State Management](#state-management)
- [Storage](#storage)
- [Dependency Injection](#dependency-injection)
- [Change Tracking](#change-tracking)
- [Platform Detection](#platform-detection)
- [JSON](#json)
- [Keychain](#keychain)
- [Combine & Async Utilities](#combine--async-utilities)
- [SwiftUI Components](#swiftui-components)
- [Logging](#logging)
- [Foundation Extensions](#foundation-extensions)

---

## Source Layout

```
Sources/
  Suite/
    ExportedModules.swift          # @_exported re-exports of SwiftUI and Combine
    SuiteMacros.swift              # Public macro declarations
    AppKit/                        # NSApplication, NSAlert, NSButton, NSColor, NSEvent, NSView
    Cocoa/                         # ErrorHandling, NSImage, NSTextFieldAndView
    Combine & Async/               # Publishers, Loadable, Observables, Debouncer, AsyncFlag, AsyncSemaphore
    Foundation/                    # ~60 files: Array, String, Date, URL, FileManager, Codable, etc.
    Geometry/                      # CGRect, CGPoint, CGSize, CGAngle, CGPath, Vector2, UnitPoint
    Logging/                       # Logger, Slog, SlogView, SlogScreen, SlogButton
    Property Wrappers/             # CodableAppStorage, CodableFileStorage, NonIsolatedWrapper, ReadyFlag
    SwiftData/                     # ModelContext extensions
    SwiftUI/
      Component Views/             # AsyncButton, LoadingView, HostingWindow, LabeledView, TitleBar, …
      View Extensions/             # asyncOnChangeOf, sizeReporting, printing, URL opening, …
      View Wrappers/               # AsyncContainerView, PublisherView, BottomSheetView, EqualSizes, …
      View Modifiers/
      Drag and Drop/
      Extensions/                  # Color+Codable, Font, Gradient, NavigationLink, NavigationPath
      Observers/
      Shapes/
    Types/                         # ChangeTracker, Gestalt, LoadingState, SharedDependencyManager,
                                   # Keychain, VersionString, DefaultsBasedPreferences, OnDemandFetcher, …
    UIKit/                         # ~20 UIKit extensions: UIImage, UIViewController, UIApplication, …
    Utilities/                     # ObservableValue, Reachability, URLSession, SeededRandomNumberGenerator, …
    Utilities/JSON/                # JSON type system, Codable integration, encoders/decoders
    Widgets/                       # WidgetFamily
  SuiteMacrosImpl/                 # SwiftSyntax macro implementations (compiler plugin)
Tests/
  SuiteTests/                      # MacroTests, GeometryTests, Foundation, SwiftUI, JSON, Type tests
```

---

## Macros

**File:** `Sources/Suite/SuiteMacros.swift`
**Implementations:** `Sources/SuiteMacrosImpl/`

### `@GeneratedPreferenceKey`
Generates a complete SwiftUI `PreferenceKey` type including a `reduce` function.

```swift
@GeneratedPreferenceKey(name: "ItemHeight", type: CGFloat.self, defaultValue: 0)
```

### `@NonisolatedContainer`
Generates thread-safe `nonisolated` accessors using `ThreadsafeMutex`. Set `observing: true` to also call `objectWillChange`.

```swift
@NonisolatedContainer(observing: true)
var count: Int = 0
```

**Runtime dependency:** `Sources/Suite/Property Wrappers/NonIsolatedWrapper.swift`

---

## State Management

### `LoadingState<Value: Sendable>`

**File:** `Sources/Suite/Types/LoadingState.swift`

```swift
enum LoadingState<Value: Sendable> {
    case idle
    case loading
    case empty
    case failed(Error)
    case loaded(Value)
}
```

Properties: `isLoaded: Bool`, `error: Error?`

### `Loadable` protocol

**File:** `Sources/Suite/Combine & Async/Loadable.swift` — iOS 13+, macOS 10.15+

```swift
protocol Loadable: ObservableObject {
    associatedtype Output: Sendable
    var state: LoadingState<Output> { get }
    func load()
}
```

---

## Storage

### `CodableAppStorage<T: Codable & Equatable & Sendable>`

**File:** `Sources/Suite/Property Wrappers/CodableAppStorage.swift` — iOS 13+, macOS 10.15+

JSON-encodes any `Codable` type into `UserDefaults`. Drop-in replacement for `@AppStorage` when the value type isn't natively supported.

```swift
@CodableAppStorage("my-key") var items: [Item] = []
@CodableAppStorage("my-key") var item: Item?           // optional variant
```

`projectedValue` is a `Binding<T>`. Supports custom `UserDefaults` store.

### `CodableFileStorage<T: Codable & Sendable>`

**File:** `Sources/Suite/Property Wrappers/CodableFileStorage.swift` — iOS 14+, macOS 11+

JSON-encodes a `Codable` value to a file URL.

```swift
@CodableFileStorage(url: myFileURL) var config: Config = Config()
@CodableFileStorage(url: myFileURL) var config: Config?  // optional variant
```

`projectedValue` is a `Binding<T>`.

---

## Dependency Injection

### `SharedDependencyManager`

**File:** `Sources/Suite/Types/SharedDependencyManager.swift`

Thread-safe service locator. `@unchecked Sendable` — uses internal locking.

```swift
// Register
SharedDependencyManager.instance.register(MyService(), .replaceable)

// Resolve
let service: MyService? = SharedDependencyManager.instance.resolve(MyService.self)

// Property wrapper auto-resolution
@SharedDependency var service: MyService?
```

**Replacement rules:**
- `.single` — register once; subsequent calls are no-ops
- `.default` — alias for `.single`
- `.replaceable` — always replaces
- `.ignoreLater` — first registration wins

---

## Change Tracking

**File:** `Sources/Suite/Types/ChangeTracker.swift` — iOS 17+, macOS 14+, watchOS 10+

Targeted SwiftUI view invalidation by ID. Only views registered for a specific ID rebuild when that ID changes. Tokens are kept alive by the observing view and deallocated when the view disappears.

```swift
// Create (inject via @Environment or pass directly)
let tracker = ChangeTracker<UUID>()

// Signal a change
tracker.didChange(id: item.id)

// View: rebuild this view when item.id changes
.observe(item.id, in: tracker)

// View: run async callback when item.id changes
.onTrackedChange(item.id, in: tracker) {
    await refresh()
}
```

**Convenience API for `String` IDs** — uses a shared `ChangeTracker<String>.instance`:

```swift
tracker.didChange(id: "my-key")   // tracker is ChangeTracker<String>.instance

.observe("my-key")
.onTrackedChange("my-key") { await refresh() }
```

---

## Platform Detection

### `Gestalt`

**File:** `Sources/Suite/Types/Gestalt.swift`

All properties are static. No instantiation needed.

```swift
Gestalt.distribution          // .development | .testflight | .appStore
Gestalt.debugLevel            // .none | .testFlight | .internalTesting | .debugging
Gestalt.isOnSimulator         // Bool
Gestalt.isAttachedToDebugger  // Bool
Gestalt.isInPreview           // Bool — true inside Xcode Previews
Gestalt.isRunningUITests      // Bool
Gestalt.isRunningUnitTests    // Bool
Gestalt.isOnMac               // Bool
Gestalt.isOnIPad              // Bool
Gestalt.isOnIPhone            // Bool
Gestalt.isOnVision            // Bool
Gestalt.isOnWatch             // Bool
Gestalt.deviceName            // String
Gestalt.buildDate             // Date?
Gestalt.sleepDisabled         // Bool (get/set) — macOS only
Gestalt.serialNumber          // String? — macOS only
Gestalt.deviceID              // String? — async
```

---

## JSON

**Directory:** `Sources/Suite/Utilities/JSON/`

Type-safe JSON handling built around `JSONDictionary = [String: JSONRequirements]`.

```swift
// Codable → JSON dictionary
let dict = try JSONEncoder().encodeAsDictionary(myObject)

// JSON dictionary → Codable
let obj = try JSONDecoder().decode(MyType.self, from: dict)

// CodableJSONDictionary / CodableJSONArray — Codable wrappers for [String:Any] / [Any]
```

---

## Keychain

**File:** `Sources/Suite/Types/Keychain.swift`

`actor Keychain` — all methods are static.

```swift
Keychain.set("value", forKey: "key")
Keychain.set(data, forKey: "key", withAccess: .accessibleAfterFirstUnlock)
Keychain.string(forKey: "key")         // String?
Keychain.data(forKey: "key")           // Data?
Keychain.getBool("key")                // Bool?
Keychain.double(forKey: "key")         // Double?
Keychain.delete("key")                 // Bool
Keychain.clear()                       // Bool
```

Configure `Keychain.accessGroup`, `Keychain.keyPrefix`, `Keychain.synchronizable` before use.

**Access options:** `accessibleWhenUnlocked`, `accessibleWhenUnlockedThisDeviceOnly`, `accessibleAfterFirstUnlock`, `accessibleAfterFirstUnlockThisDeviceOnly`, `accessibleWhenPasscodeSetThisDeviceOnly`, `accessibleAlwaysThisDeviceOnly`

---

## Combine & Async Utilities

**Directory:** `Sources/Suite/Combine & Async/`

### Publisher extensions (`Publishers.swift`) — iOS 13+, macOS 10.15+

```swift
publisher.logFailures(fallback)
publisher.sink("label") { value in … }
publisher.asResult()                    // AnyPublisher<Result<Output, Failure>, Never>
publisher.onSuccess { value in … }
publisher.onFailure { error in … }
publisher.withPreviousValue()           // AnyPublisher<(previous: Output?, new: Output), Failure>
publishers.serialize()                  // sequences a collection of publishers

AnyPublisher<T, E>.just(value)
AnyPublisher<T, E>.fail(with: error)
```

### `PokeableObject` — manual `ObservableObject` invalidation

```swift
let obj = PokeableObject()
obj.poke()   // fires objectWillChange
```

### `NotificationWatcher` — observe a notification as `ObservableObject`

### `AsyncFlag` / `AsyncSemaphore` — async coordination primitives

### `Debouncer` — debounce async work

### `asyncOnChangeOf` view modifier — iOS 17+, macOS 14+

```swift
.asyncOnChangeOf(of: value) {
    try await doWork()
}
```

---

## SwiftUI Components

### `AsyncButton` — `Sources/Suite/SwiftUI/Component Views/AsyncButton.swift` — iOS 13+

Button that executes an `async` action, showing a busy state while running.

```swift
AsyncButton("Save") { await save() }
AsyncButton(systemImage: "arrow.up") { await upload() }
AsyncButton(role: .destructive) { await delete() } label: { Text("Delete") }
```

Options: `shouldCancelOnDisappear: Bool`, `useDetachedTask: Bool`

### `LoadingView` — `Sources/Suite/SwiftUI/Component Views/LoadingView.swift` — iOS 15+

Renders different views for each `LoadingState`.

```swift
LoadingView(loader: myLoadable) { items in
    List(items) { … }
}
```

### `AsyncContainerView` — `Sources/Suite/SwiftUI/View Wrappers/AsyncContainerView.swift`

Wraps async content loading with configurable loading/error/empty states.

### `PublisherView` — `Sources/Suite/SwiftUI/View Wrappers/PublisherView.swift`

Renders a view from a Combine publisher's latest value.

### `HostingWindow` — `Sources/Suite/SwiftUI/Component Views/HostingWindow.swift` — macOS

`NSWindow` subclass that hosts a SwiftUI root view. Supports `onClose` callback.

### `ObservableValue` — `Sources/Suite/Utilities/ObservableValue.swift`

Bridges a Combine publisher to SwiftUI's `@Published`/`ObservableObject` system.

---

## Logging

**Directory:** `Sources/Suite/Logging/`

- `Slog` — structured logger with levels, file/line tagging, and filtering
- `SlogView` / `SlogScreen` / `SlogButton` — SwiftUI log viewer components
- `SuiteLogger` — framework-internal logger instance

---

## Foundation Extensions

Notable additions across `Sources/Suite/Foundation/`:

| File | Key additions |
|------|--------------|
| `Array.swift` | Safe subscript, grouping, deduplication |
| `Date.swift` + subtypes | `Date.Day`, `Date.Month`, `Date.DayOfWeek`, `Date.Time`, `DateTag` |
| `URL+Files.swift` | `~`-expansion, file URL helpers |
| `String.swift` | Crypto hashing, inflection, interpolation |
| `String+Crypto.swift` | MD5, SHA hashing |
| `VersionString.swift` | `struct VersionString: Comparable` — semantic version parsing with subscript access |
| `AnyEquatable.swift` | Type-erased `Equatable` |
| `UserDefaultsBackedDictionary.swift` | `UserDefaults`-persisted dictionary |
| `Operators.swift` | Custom operators |

### `VersionString`

```swift
let v = VersionString("2.3.1")
v[0]  // 2
v[1]  // 3
v < VersionString("3.0.0")  // true
```
