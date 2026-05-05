# Agents.md

Catalog of every public type and extension in `Sources/Suite/`. For architecture see `CLAUDE.md`; for per-file dispositions see `Misc/CODE_REVIEW_RESOLVED.md`.

## Root

- **`@GeneratedPreferenceKey`** (`SuiteMacros.swift`) — macro that synthesises a SwiftUI `PreferenceKey` from a struct.
- **`@NonisolatedContainer`** (`SuiteMacros.swift`) — macro that wraps stored properties in a thread-safe lock-backed container.
- `ExportedModules.swift` — re-exports `SwiftUI` and `Combine` so clients can `import Suite` alone.

## AppKit

- extension **`NSColor`** (`AppKit/NSColor.swift`) — hex-string parsing/formatting and convenience initialisers.
- extension **`NSEvent`** (`AppKit/NSEvent.swift`) — modifier-flag and key helpers.

## Cocoa

- extension **`NSTextField`** / **`NSTextView`** (`Cocoa/NSTextFieldAndView.swift`) — editability and text-update helpers.
- extension **`NSView`** (`Cocoa/NSView+Helpers.swift`) — Auto Layout pinning and add/remove helpers.

## Combine & Async

- **`AsyncFlag`** — async-coordination flag (waiters resume when set).
- **`AsyncSemaphore`** — counting semaphore for async/await.
- **`Loadable`** — protocol for objects exposing a loading state.
- **`OptionalType`** (`Combine & Async/Binding.swift`) — protocol used to bridge `Optional` through `Binding` extensions.
- **`PokeableObject`** (`Combine & Async/Observables.swift`) — `ObservableObject` with a manual `objectWillChange` poke.
- extension **`AnyCancellable`** (`Combine & Async/Subscription.swift`) — set-based storage helper.
- extension **`AnyPublisher`** / **`Publisher`** (multiple) — async-bridging (`asynchronize`), `withPreviousValue`, sink-leak helpers.
- extension **`Binding`** (multiple) — Optional-handling, default-value, transform helpers.
- extension **`Collection`** (`Combine & Async/Publishers.swift`) — collection-of-publishers combining.
- extension **`CurrentValueSubject`** — value-mutation conveniences.
- extension **`ObservableObjectPublisher`** — publisher conveniences.

## Foundation

- **`Box<Contents>`** / **`IDBox<Contents>`** (`Foundation/Box.swift`) — reference wrappers for value types (the latter adds a hashable id).
- **`Condensable`** / **`CondensableCondensate`** / **`Reconstitutable`** (`Foundation/Condensable.swift`) — protocols for value compression / reconstitution.
- **`DecimalFormattable`** (`Foundation/NumberFormatting.swift`) — protocol for decimal-place-aware string formatting.
- **`DiskBackedArray<Value>`** / **`DiskBackedDictionary<Key, Value>`** — collections persisted to disk.
- **`DisplayableError`** (`Foundation/Error.swift`) — error with a user-facing message.
- **`ExtendedAttributeError`** (`Foundation/URL+ExtendedAttributes.swift`) — error type for xattr operations.
- **`FunctionBox`** — boxed closure for storage in `Sendable` containers.
- **`KeyDifferences`** (`Foundation/Dictionary.swift`) — added/removed/changed key sets.
- **`KeyValueContainer`** / **`StringConvertible`** / **`UserDefaultStorable`** (`Foundation/UserDefaultsBackedDictionary.swift`) — protocols underlying the UserDefaults dictionary.
- **`MD5able`** (`Foundation/MD5.swift`) — protocol for types that produce a stable MD5.
- **`Pluralizer`** — English pluralisation rules.
- **`PropertyListDataType`** (`Foundation/PropertyList.swift`) — protocol for plist-storable types.
- **`SafeDecodable<Base>`** / **`SafeResult<Kind>`** (`Foundation/Decoding.swift`) — wrappers that capture decode failures without throwing.
- **`StringIdentifiable`** — `Identifiable` with a `String` id.
- **`Throwable`** — protocol for closures that may throw.
- **`UserDefaultsBackedDictionary<Key, Value>`** — Dictionary persisted to `UserDefaults`.
- extension **`AVAudioPlayer`** (`Foundation/AVPlayer.swift`) — failable URL initialiser, play helpers.
- extension **`Array`** (multiple) — chunking, safe subscripting, set ops, removal.
- extension **`Bundle`** — version, build, info-dictionary helpers.
- extension **`Calendar`** / **`TimeZone`** (`Foundation/Calendar.swift`) — convenience instances and component math.
- extension **`CaseIterable`** (multiple) — index/next/previous helpers.
- extension **`Collection`** (multiple) — pair iteration, safe subscripting.
- extension **`CollectionDifference`** (`Foundation/Collection.swift`) — diff inspection helpers.
- extension **`CommandLine`** — argument parsing helpers.
- extension **`Data`** (multiple) — hex/base64/string conversion, hashing, slicing.
- extension **`Date`** (multiple, in `Foundation/Date/`) — components, arithmetic, comparison, formatting (`iso8601String`, `ageString`).
- extension **`DateFormatter`** — common-format static instances.
- extension **`Dictionary`** (multiple) — merge, transform, `KeyDifferences`.
- extension **`Encodable`** / **`Decodable`** / **`JSONDecoder`** / **`KeyedDecodingContainer`** — see `Foundation/Codable/`.
- extension **`Equatable`** (`Foundation/Enums.swift`) — `~=` helpers for switch matching.
- extension **`Error`** — display-string and bridging helpers.
- extension **`FileManager`** — temp-file URLs, unique-name generation, directory helpers.
- extension **`FixedWidthInteger`** / **`Numeric`** / **`UInt32`** / **`Int`** / **`Int64`** — byte access, capping, formatting.
- extension **`NSObject`** (multiple) — KVO and selector helpers.
- extension **`Notification`** / **`Notification.Name`** (`Foundation/Notification.swift`) — post helpers, main-thread variants.
- extension **`OptionSet`** — set-style introspection helpers.
- extension **`Optional`** (multiple) — unwrap-or-throw, comparison, default-value helpers.
- extension **`ProcessInfo`** — environment / argument helpers.
- extension **`Range`** — clamping and intersection helpers.
- extension **`String`** (multiple, in `Foundation/String/`) — substring, validation, random, array conversion.
- extension **`String.StringInterpolation`** — formatted-number interpolation.
- extension **`TimeInterval`** — duration formatting, day/hour/minute breakdown.
- extension **`Timer`** — closure-based scheduling.
- extension **`URL`** (multiple, in `Foundation/URL/`) — path, file, query, bookmark, extended-attribute helpers.
- extension **`URLRequest`** — header / body conveniences.
- extension **`URLResponse`** — status-code helpers.
- extension **`UUID`** — short-form and deterministic generation.

### Foundation/Codable

- **`JSONExpandedDecoder`** / **`JSONExportable`** / **`PostDecodeAwakable`** (`Foundation/Codable/Codable.swift`) — extended-decoder protocol set with post-decode hooks.
- extension **`Data`** / **`Decodable`** / **`Encodable`** / **`Dictionary`** / **`JSONDecoder`** / **`JSONDictionary`** — JSON encoding/decoding utilities and stable hashing.

## Geometry

- **`CGAngle`** — degree/radian wrapper.
- **`CGLine`** — 2D line (`Codable`, `Hashable`, `RawRepresentable`).
- **`Vector2`** — protocol unifying `CGPoint` / `CGSize` arithmetic.
- extension **`CGContext`** / **`CGImage`** / **`UIImage`** (`Geometry/CGContext.swift`) — pixel access, alpha sampling.
- extension **`CGFloat`** — rounding, formatting helpers.
- extension **`CGPath`** — element iteration helpers.
- extension **`CGPoint`** — distance, line projection, geometry.
- extension **`CGSize`** — aspect-fit/scale helpers.
- extension **`CGRect`** (multiple, in `Geometry/CGRect/`) — `Placement` enum, math, slicing, within-limit fitting.
- extension **`UnitPoint`** — coordinate helpers.
- extension **`Vector2`** (multiple) — `+`, `-`, `*`, `/`, `≈≈`, hashing, raw-value round-trip.

## Logging

- **`OldSuiteLogger`** (`Logging/SuiteLogger.swift`) — legacy logging entry point.
- **`Slog`** — actor-isolated structured logger; backing for `SlogButton`/`SlogScreen`.
- **`SlogButton`** — SwiftUI button that opens the log viewer.
- **`SlogScreen`** — SwiftUI log viewer.
- extension **`NSManagedObject`** (`Logging/SuiteLogger.swift`) — debug-description helpers.
- extension **`String`** (`Logging/Logger.swift`) — log-level prefixing.

## Property Wrappers

- **`@CodableAppStorage`** — `UserDefaults` storage with JSON encoding for complex types.
- **`@CodableFileStorage`** — file-backed storage with JSON encoding.
- **`@NonIsolatedWrapper`** — `@State`-friendly wrapper backed by `ThreadsafeMutex`.
- **`@ObservedValue`** — bridges an `ObservableObject` keypath into a `Binding`.
- **`ReadyFlag`** — async coordination flag (`waitForReady` / `makeReady`).

## SwiftData

- **`PresavablePersistentModel`** (`SwiftData/ModelContext.swift`) — protocol with a presave hook.
- extension **`ModelContext`** — `countModels` and convenience fetches.

## SwiftUI

- **`EnvironmentEchoingView<Content>`** — exposes selected environment values into the view body.

### SwiftUI/Button Styles

- **`FullWidthButtonStyle`** — full-width filled-or-bordered button.
- extension **`View`** (`SwiftUI/Button Styles/SafeGlassButtonStyle.swift`) — `.glassEffectIfAvailable` modifier.

### SwiftUI/Compatibility

- extension **`View`** (multiple) — backports of newer SwiftUI modifiers under `iOS14Shims.swift` etc.

### SwiftUI/Component Views

- **`AsyncButton`** family — `AsyncButtonLabel`, `AsyncButtonBusyLabel`, `ButtonIsPerformingActionKey`.
- **`ErrorDisplayingView`** — surfaces an `Error` to the UI.
- **`FixedSpacer`** / **`HSpacer`** / **`VSpacer`** — fixed-dimension spacers.
- **`FullScreenCoverLink<Label, Destination>`** — declarative full-screen cover link.
- **`HostingWindow<Root>`** — `UIHostingController` wrapper for cross-platform hosting.
- **`LongPressButton<Label>`** — button with long-press gesture.
- **`OffsetReportingScrollView<Content>`** / **`PositionReportingView<Content>`** — scroll-position reporting.
- **`ShowViewLabelsEnvironmentKey`** — toggles debug labels for child views.
- **`SimpleErrorMessageView`** / **`SimpleProgressView`** — minimal error/progress UI.
- **`TitleBar<Leading, Trailing, Title>`** + **`TitleBarFontKey`** — custom title bar component.
- extension **`EnvironmentValues`** / **`LoadingView`** / **`View`** (multiple) — supporting modifiers.

### SwiftUI/Drag and Drop

- **`DragContainer<Content>`** — root container for in-app drag-and-drop.
- **`DragPhase`** (`SwiftUI/Drag and Drop/View+makeDraggable.swift`) — drag-state enum.
- extension **`View`** (multiple) — `makeDraggable`, `makeDropTarget` modifiers.

### SwiftUI/Extensions

- **`AppRunMode`** (`SwiftUI/Extensions/App+Extensions.swift`) — run-mode classification.
- **`Closure`** (`SwiftUI/Extensions/Closure.swift`) — view that runs a closure during body computation.
- **`DismissParentEnvironmentKey`** / **`IsEditingEnvironmentKey`** / **`IsScrollingEnvironmentKey`** / **`NavigationPathEnvironmentKey`** (`SwiftUI/Extensions/Environment.swift`) — environment keys.
- **`OptionalNavigationLink<CheckedValue, Label, Destination>`** (`SwiftUI/Extensions/NavigationView.swift`) — pre-iOS 16 navigation link layer (kept as back-compat).
- **`StateChange`** (`SwiftUI/Extensions/SceneState.swift`) — scene-state transition value.
- extension **`Binding`** (`SwiftUI/Extensions/NavigationPath.swift`) — `NavigationPath` binding helpers.
- extension **`Color`** (multiple) — hex parsing, system-colour bridges, `randomGray`.
- extension **`EnvironmentValues`** (multiple) — typed accessors for the environment keys above.
- extension **`Font`** (`SwiftUI/Extensions/Font.swift`) — `buttonImage` constant.
- extension **`LinearGradient`** (`SwiftUI/Extensions/Gradient.swift`) — convenience initialisers.
- extension **`NavigationPath`** — append/pop helpers.
- extension **`ToolbarItemPlacement`** — cross-platform placement constants.
- extension **`View`** (multiple) — `onAppearAsync`, `onForeground`, `onSceneStateChange`, `addTextContentType`, etc.

### SwiftUI/Gestures

- extension **`View`** (`SwiftUI/Gestures/View.gesture.swift`) — gesture composition helpers.

### SwiftUI/Navigation

- **`HiddenNavigationLink<Label, Destination>`** — programmatic navigation without a visible link.

### SwiftUI/Observers

- **`ScrollCanary`** — reports when an enclosing scroll view scrolls.
- **`SignificantTimeChangeObserver`** — observes `.NSCalendarDayChanged`-class notifications.
- extension **`Notification.Name`** (`SwiftUI/Observers/NotificationObserver.swift`) — `.publisher(object:)` helper (deliberate Combine bridge).
- extension **`View`** — `.onReceive(_ name:perform:)` overload.

### SwiftUI/Other Views

- **`DictionaryView<Key, Value>`** — list view for key/value pairs.
- extension **`View`** (`SwiftUI/Other Views/ScreenOverlay.swift`) — full-screen overlay modifier.

### SwiftUI/Other Views/CalendarMonthView

- **`CalendarMonthView<DayView>`** + **`CalendarMonthViewOptions`** — month-grid calendar.
- **`CalendarSingleDayView`** — single day cell.
- **`CalendarWeekDayLabel`** — weekday header.
- **`MonthDayOptions`** — per-day display flags.
- extension **`EnvironmentValues`** / **`View`** — calendar-styling modifiers.

### SwiftUI/Shapes

- **`Line`** — line shape.
- **`PartlyRoundedRectangle`** — rectangle with selective corner rounding.
- extension **`Angle`** (multiple) — quadrant, comparison, arithmetic.
- extension **`CGPoint`** / **`CGRect`** (`SwiftUI/Shapes/Trig.swift`) — angle/quadrant helpers.
- extension **`Path`** — common-path builders.
- extension **`Shape`** — fill/stroke helpers.

### SwiftUI/Utilities

- **`UnitRect`** / **`UnitSize`** — normalised-coordinate rect/size.
- extension **`UnitPoint`** — additional anchor points.
- extension **`View`** (multiple) — `.scaledFrame(width:height:)` and other utility modifiers.

### SwiftUI/View Extensions

- **`ContainedInViewController`** / **`EnclosingViewControllerContainer`** / **`EnclosingViewControllerKey`** — UIViewController access from SwiftUI.
- **`Log`** (`SwiftUI/View Extensions/View+Debug.swift`) — body-side debug logger.
- **`PreferenceValues`** (`SwiftUI/View Extensions/View+PreferenceValues.swift`) — preference-key bag.
- **`SizeViewModifier`** (`SwiftUI/View Extensions/View+sizeReporting.swift`) — view-size reporting modifier.
- **`StatefulPreview<Value>`** — `@State`-bearing preview helper.
- **`UIKeyboardType`** (`SwiftUI/View Extensions/View+macOS.swift`) — cross-platform keyboard-type stub for macOS.
- extension **`GeometryProxy`** — frame/safe-area helpers.
- extension **`Image`** (multiple) — system-symbol and resource conveniences.
- extension **`View`** (multiple) — debug, preference, size-reporting, macOS-stub modifiers.

### SwiftUI/View Modifiers

- **`NotYetImplementedModifier`** — strikes through and dims a placeholder view.
- **`Spinning<Thing>`** + **`SpinningModifier`** — continuous-rotation animation.
- extension **`View`** (multiple) — `.notYetImplemented()`, `.spinning(period:)`, etc.

### SwiftUI/View Wrappers

- **`AsyncContainerView<Content>`** — renders a placeholder until an async value resolves.
- **`BottomSheet<Content, Background>`** + **`OverlayModifier<Overlay>`** + **`SimpleOverlayModifier<Overlay>`** — bottom-sheet presentation.
- **`DebuggingIDView`** — overlays a debug id.
- **`Deferred<Content>`** — defers rendering until a condition is met.
- **`GuideLines`** + **`GuideLinesShape`** — debug grid overlay.
- **`InterfaceOrientedView<Contents>`** — picks a child variant per interface orientation.
- **`PublisherView<Definition>`** — view driven by a Combine `Publisher` (deliberate Combine bridge).
- **`SideDrawerContainer<Content>`** — leading/trailing drawer container.
- **`SlideUpSheet<Content>`** — slide-up sheet with drag handle.
- extension **`View`** (multiple) — sheet/overlay/drawer modifiers.

## Types

- **`AsyncBlocker<Result>`** / **`ThrowingAsyncBlocker<Result>`** — barriers that suspend callers until `release(...)` is called.
- **`ChangeTracker<ID, Value>`** — diffs successive snapshots of identifiable values.
- **`CrashPad`** — crash logging.
- **`DeviceFilter`** — option set for cross-platform device filtering.
- **`Gestalt`** — platform / distribution / device introspection.
- **`IdentifiableEnum`** — protocol for `Identifiable` `CaseIterable` enums.
- **`IntPoint`** / **`IntSize`** — integer-coordinate point/size.
- **`Keychain`** — secure keychain access (public `CurrentValueSubject` observation surface — deliberate Combine bridge).
- **`LoadingState<Value>`** — async-state enum (`idle`/`loading`/`empty`/`failed`/`loaded`).
- **`NetworkInterface`** — `getifaddrs`-based interface enumeration.
- **`OnDemandFetcher<Value>`** — lazy on-demand value fetcher.
- **`Point`** — generic 2D coordinate type.
- **`PreferencesKeyProvider`** (`Types/DefaultsBasedPreferences.swift`) — protocol for typed preference keys.
- **`RawCodable`** — protocol for `Codable` `RawRepresentable` types.
- **`SFSymbol`** — exhaustive `enum` of SF Symbol names.
- **`SharedDependency<T>`** + **`SharedDependencyManager`** — typed-key DI container.
- **`StringInitializable`** (`Types/RawCollection.swift`) — protocol for types initialisable from a `String`.
- **`Titleable`** — protocol exposing a display title.
- **`VersionString`** — parses and compares dot-separated version strings.
- extension **`DeviceFilter`** — option-set member helpers.
- extension **`Gestalt`** (multiple) — device-type and distribution helpers.
- extension **`UserDefaults`** (`Types/DefaultsBasedPreferences.swift`) — typed preference accessors.
- extension **`View`** (`Types/ChangeTracker.swift`) — change-tracker installation modifier.

## UIKit

- **`ImageFormat`** (`UIKit/UIImage.swift`) — image-format enum.
- **`SA_BlockingView`** — full-screen interaction blocker.
- **`SelfContainedRefreshControl`** — drop-in `UIRefreshControl` replacement.
- extension **`CGSize`** / **`IntSize`** (`UIKit/ScreenSize.swift`) — known-device screen-size lookup.
- extension **`UIButton`** — background-image-per-state helpers.
- extension **`UIImage`** (multiple, in `UIKit/`) — clipping, resizing, tinting, overlay (uses `UIGraphicsImageRenderer`).
- extension **`UIScrollView`** — `SelfContainedRefreshControl` integration.
- extension **`UITraitCollection`** — appearance helpers.
- extension **`UIColor`** (multiple, in `UIKit/UIColor/`) — hex parsing/formatting, ARGB packing, palette.

## Utilities

- **`BlockWrapper`** — type-erased closure wrapper.
- **`CommunalFetcher<Value>`** — task-deduping shared fetcher (concurrent callers await the same in-flight task).
- **`ObservableValue<Value>`** — Combine→SwiftUI bridge (deliberate Combine bridge).
- **`SeededRandomNumberGenerator`** — reproducible RNG.
- **`WebConsoleView`** — in-app web console for log inspection.
- extension **`Array`** (`Utilities/Identifiable.swift`) — identifier-based lookup.
- extension **`Publisher`** (`Utilities/DeSync.swift`) — `asynchronize()` Combine→async bridge.
- extension **`Reachability`** — `setupAndCheckForOnline()` async helper.
- extension **`String`** (`Utilities/String+Crypto.swift`) — SHA-1/MD5 helpers.
- extension **`WKWebView`** — script and message-handler conveniences.

### Utilities/JSON

- **`CodableJSONArray`** / **`CodableJSONDictionary`** — `Codable` wrappers around heterogeneous JSON.
- **`JSONDataType`** (`Utilities/JSON/JSON Types.swift`) — protocol marking JSON-representable values.
- extension **`Data`** / **`Dictionary`** / **`String`** (`Utilities/JSON/JSON+PrettyPrinted.swift`) — pretty printing.
- extension **`JSONDecoder`** / **`JSONEncoder`** (multiple) — date-strategy support, dictionary round-trip.

### Utilities/Views

- **`FlowedHStack<Element>`** + **`FlowedHStackElement`** + **`FlowedHStackImage`** + **`FlowedHStackImageElement`** — wrapping/flowing horizontal layout.
- **`SimpleWebView`** — minimal `WKWebView` wrapper.
- **`WrappedView<Content>`** — wraps a UIView for SwiftUI.
- **`WrappingHStack`** — alternative wrapping HStack.
- extension **`EnvironmentValues`** / **`FlowedHStack`** / **`View`** (`SwiftUI/Other Views/...`) — supporting helpers.

## Widgets

- extension **`WidgetFamily`** (`Widgets/WidgetFamily.swift`) — per-device widget point sizes (iOS / macOS / watchOS branches).
