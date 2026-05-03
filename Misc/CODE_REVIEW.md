# Suite — Detailed Code Review

**Scope:** Every Swift file in `Sources/Suite/`, `Sources/SuiteMacrosImpl/`, `Tests/SuiteTests/`, plus `Package.swift` (310 files).
**Date:** 2026-05-03
**Method:** File-by-file review by 13 parallel review agents, aggregated here.

Each finding is tagged: **[Bug]**, **[Concurrency]**, **[API]**, **[Perf]**, **[Platform]**, **[Convention]**, **[Memory]**, **[Deprecated]**, **[Diagnostics]**, **[Coverage]**, **[Flakiness]**, **[Suggestion]**.

---

## Executive Summary

### Critical bugs (crash, data corruption, security, won't-compile)

1. **`Types/Keychain.swift`** — `AccessOptions.accessibleAlwaysThisDeviceOnly` returns `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. Silent security degradation. (line 396)
2. **`Types/RawCollection.swift`** — Subscript setter is **inverted**: `collection[item] = true` REMOVES the item, `false` INSERTS. Silent data corruption.
3. **`Foundation/String.swift`** — `extractSubstring(start:end:)` references undefined symbol `string`; **won't compile**. Called by `MobileProvisionFile.swift` (which is itself entirely commented out).
4. **`Foundation/Date.Month.swift:20`** — `abbrev` indexes `[self.rawValue]` instead of `[rawValue - 1]`. **Crashes on `.dec`** and is off-by-one for every other month.
5. **`SwiftUI/Extensions/TextField.swift`** — Optional `addTextContentType(_:)` calls itself recursively; **infinite recursion / stack overflow** when called with non-nil.
6. **`Foundation/Optional.swift`** — Custom `<` returns `true` for `nil < nil`, **violating strict weak ordering**. Breaks any `sort` that uses it.
7. **`Foundation/StableMD5.swift`** — `Date` hashed differently in dict path (`timeIntervalSinceReferenceDate`) vs array path (`String(describing:)`, locale-formatted). **Same data → different hashes**; defeats "stable" purpose.
8. **`Combine & Async/AsyncFlag.swift`** — `wait()` is fundamentally broken: spins forever in an `AsyncStream(unfolding:)` that never observes the signal.
9. **`Types/VersionString.swift`** — `==` uses `suffix(from: count - minCount)` (wrong); `"1.2.5.0.0" == "1.2"` returns true.
10. **`Types/SoundEffect.swift:232`** — `pause()` sets `isPlaying = true`.
11. **`Geometry/CGSize.swift`** — `scaleDown(toWidth:height:)` typo: sets `heightGood = true` where it means `widthGood = true`. Function broken in nearly every branch.
12. **`Geometry/Vector2.swift`** — `init?(rawValue:)` parses `components[0]` for both x and y; round-trip loses y.
13. **`SwiftUI/Shapes/Trig.swift`** — `Angle.quadrant` and `CGPoint.quadrant` use the same enum for two different quadrant systems with conflicting mappings.
14. **`SwiftUI/View Modifiers/Spinning.swift`** — `SpinningModifier.period` is stored but dropped at construction; the `period` argument is silently ignored.
15. **`SwiftUI/View Wrappers/Guidelines.swift:49`** — `yMarks` is built from the `x` parameter range; concrete bug when `x != y`.
16. **`SwiftUI/Other Views/CalendarMonthView/CalendarMonthView.WeeksView.swift`** — `options(for:)` ignores month/year; selecting a day in any month highlights the same day-number across all displayed months.
17. **`SwiftUI/Extensions/Color.swift`** — `Color.randomGray` uses `Double.random(in: 0...100.0)` then passes to `Color(white:)` which expects 0...1. Always near-white.
18. **`SwiftUI/Utilities/UnitRect.swift`** — `overlap(with:)` uses `max` where it should use `min`; result is wrong height.
19. **`SwiftUI/Extensions/NavigationLink.swift`** — `BoundNavigationLink`'s binding setter is a no-op; programmatic dismissal is impossible.
20. **`UIKit/UIButton.swift:50`** — `backgroundImage(_:for:)` always passes `.normal`, ignoring the state parameter.
21. **`UIKit/UIColor.swift:172-179`** — 4-char ARGB hex branch: masks/shifts produce 0 for alpha and wrong components.
22. **`AppKit/NSColor.swift:58`** — `hex` getter: `r << 16 + g << 8 + b`. Swift `<<` has **lower** precedence than `+`, so this evaluates as `r << (16 + g) << (8 + b)`. Definite bug.
23. **`Cocoa/NSView+Helpers.swift:116`** — `fullyConstrain(to:)` top constant is `23` instead of `0`.
24. **`Foundation/DateInterval.swift:19`** — `fullRange` returns `.start` of the latest-ending interval; should be `.end`.
25. **`Foundation/AVPlayer.swift:23-38`** — failable convenience init flow is malformed (`self.init(url:)` then `return nil`).
26. **`Foundation/Date.swift:326-336`** — typo `iso8691String` (should be `iso8601String`) on a public API; tests carry the typo through.
27. **`Foundation/Date.swift:480-487`** — `thisWeek(_:)` and `upcoming(_:)` are byte-identical duplicates.
28. **`Foundation/FileManager.swift:64-68`** — `uniqueURL` first-collision loop sets the name back to base; never finds a unique name.
29. **`Foundation/UserDefaultsBackedDictionary.swift`** — URL retrieval via `value(forKey:)` doesn't work; need `defaults.url(forKey:)`.
30. **`Geometry/CGContext.swift`** — `bytes`/`uint32s` capacity is wrong by a factor of 4; pointer escapes the `withMemoryRebound` closure (UB).
31. **`Geometry/CGContext.swift`** — `alphaOfPixelAt` inverts alpha for `.premultipliedFirst`.
32. **`Property Wrappers/ReadyFlag.swift`** — `set(false)` silently no-ops; `waitForReady` race between value check and continuation append; flag can hang waiters forever.
33. **`Property Wrappers/CodableAppStorage.swift`** — Optional handling stores the literal string `"null"` instead of removing the key.
34. **`Logging/Slog.File.swift`** — `save()` rewrites the entire file on every log line (O(n²)) without `.atomic`; `Line` parsing splits on `/` so any URL/path in a message corrupts parsing.
35. **`Combine & Async/Publishers.swift`** — `withPreviousValue()` force-unwraps `$0.new!` while the first scan emits `(nil, nil)`; **crashes on first emission**.
36. **`Utilities/JSON/CodableJSONArray.swift:44`** — `init?(_:[String:Sendable]?)` is a copy-paste stub from the dictionary variant; takes a dict but constructs an array.
37. **`Utilities/JSON/JSONDecoder+JSONDictionary.swift`** — `date(from double:)` and `date(from int:)` always return `nil`; `secondsSince1970`/`millisecondsSince1970` strategies never work for keyed numeric dates.
38. **`Utilities/Reachability.swift`** — `setupAndCheckForOnline()` returns early when a continuation is already installed; second waiter is told the current state but never awaits.
39. **`SwiftData/ModelContext.swift`** — `countModels` accepts a `T` *instance*, fetches all rows then `.count`s; should accept `T.Type` and use `fetchCount`.
40. **`SwiftUI/View Wrappers/SideDrawerContainer.swift:37`** — Trailing-side rendering anchors content to leading; trailing drawer behaves wrong.

### Documentation drift

- **`CLAUDE.md`** documents five macros (`@GeneratedEnvironmentKey`, `@GeneratedPreferenceKey`, `@AppSettings`, `@AppSettingsProperty`, `@NonisolatedContainer`). Only **two** actually exist (`@GeneratedPreferenceKey`, `@NonisolatedContainer`). Also references runtime file `Types/UserDefaultsContainer.swift`, which doesn't exist. The Tests CLAUDE.md description claims XCTest with SwiftSyntaxMacrosTestSupport — but **all current tests use Swift Testing**.

### Public API typos (rename = breaking)

- `Date.iso8691String` → `iso8601String` (Foundation/Date.swift) — typo carried through tests
- `OverlayModifer` → `OverlayModifier` (SwiftUI/View Wrappers/BottomSheetView.swift)
- `EmbdeddedWebView` → `EmbeddedWebView` (Utilities/Views/SimpleWebView.swift) — appears 5+ times
- `EnviromentEchoingView.swift` filename and type name → `Environment…` (SwiftUI/EnviromentEchoingView.swift)
- `editabled(_:)` → `editable(_:)` (Cocoa/NSTextFieldAndView.swift)
- `presentedest` → `topPresentedViewController` (UIKit/UIViewController.swift)

### Recurring patterns

1. **Combine usage despite "use async/await" rule.** `Pluralizer`, `Timer`, `Reachability`, `CommunalFetcher`, `DeSync`, `ObservableValue`, `SignificantTimeChangeObserver`, `InterfaceOrientedView`, `PublisherView`, `SceneStateObserver`, `Keychain`, `onTimer`, `NotificationObserver`, `Debouncer`. Several would be a few-line rewrite as `AsyncStream`/`for await`.
2. **GCD usage despite "no GCD" rule.** `MainActor.run(after:)` (used in SwipeActions, ScrollCanary, AnimationCompletion) appears to be a `DispatchQueue.main.asyncAfter` shim. `SeededRandomNumberGenerator` uses `DispatchSerialQueue.global()` and `.sync`. `Reachability` stores a `DispatchQueue`.
3. **`nonisolated(unsafe) static var`** for `EnvironmentKey.defaultValue` and similar is widespread. Many should be `let` (constants); a few are genuinely shared mutable state with no synchronization (`CodableJSONDictionary.dataKeyNames`, `EnclosingViewControllerKey.defaultValue`, `OrientationWatcher.instance`).
4. **Swift convenience-init failure pattern.** Several `init?` overloads call `self.init(...)` then `return nil`. UIColor, UIImage, NSColor, AVPlayer all have this; semantics are dubious in Swift.
5. **`@MainActor` on pure constants/values.** `DeviceFilter` static lets, `Int64.bytesString`, etc. force callers to MainActor unnecessarily.
6. **Hard-coded dimensions** despite the project rule, especially in: `TitleBar`, `FullWidthButtonStyle`, `SlideUpSheet`, `MultiColumnPicker`, `BottomSheetView`, `Font.swift`, `MonthYearPopover`.
7. **View-returning `some View` computed properties** (rule says prefer subview types): `AsyncButton.buttonLabel`, `AsyncButton.spinner`, `CalendarMonthView+Components.*`, `CalendarMonthView.monthNames`, `MonthYearPopover.monthList`, `MonthYearPopover.yearList`, `FlowedHStack.legacyBody`.
8. **State mutation during view body.** `OffsetReportingScrollView`, `View+sizeReporting`, `ScrollCanary`, `vprint`, `Tooltips`, `AnimationCompletion`, `SwipeActions.buildContent`, `Closure.body`, `LoadingView.task`.
9. **Files vastly exceeding the ~100 line guideline** (top offenders): `Types/SFSymbol.swift` (1804), `Foundation/Date.swift` (553), `Foundation/Date.Time.swift` (349), `Foundation/URL.swift` (330), `Geometry/CGRect.swift` (320), `Foundation/Codable.swift` (241), `UIKit/UIColor.swift` (250), `Foundation/String.swift` (235), `Combine & Async/AsyncSemaphore.swift` (282).
10. **Memory leaks**: `NotificationWatcher`, `Subscribers.Sink` in Publishers.swift, `SceneStateObserver` retain cycle, `WebConsole.urlObservation` strong-self capture, IOKit leaks in `Gestalt` (`takeUnretainedValue` on Create-rule + missing `IOObjectRelease`).
11. **Stale device tables**: `Gestalt+DeviceType.swift`, `UIKit/ScreenSize.swift`, `Widgets/WidgetFamily.swift` — missing iPhone 15/16, recent iPads, Apple Watch Ultra/9/10, Apple TV 4K 3rd gen.
12. **Deprecated APIs in active use**: `NavigationLink(isActive:)`, `NavigationView`, single-arg `onChange`, `UIScreen.main`, `UIApplication.windows`, `UIGraphicsBeginImageContextWithOptions`, `Process.launchPath`/`launch()`, `kIOMasterPortDefault`, `.autocapitalization`, `AnimatableModifier`.
13. **Entirely commented-out files** (delete or restore): `Types/MobileProvisionFile.swift`, `Foundation/TimePost.swift`, `SwiftUI/Component Views/KeyboardSpacer.swift`, `SwiftUI/Utilities/PositionedLongPress.swift`.

---


# Detailed Findings (file-by-file)

## Package

### `Package.swift`
- **[Platform]** Per `CLAUDE.md`, the framework targets iOS 13+, macOS 10.15+, watchOS 6+, tvOS, and visionOS. tvOS is currently set to `.v13`, but recent commits added "tvOS and visionOS support" — confirm `tvOS(.v13)` is intended (vs `.v14`/`.v15` to match SwiftUI features used elsewhere in the framework). visionOS(.v1) is correct.
- **[Convention]** Mixed indentation (a blend of tabs and spaces) makes this file hard to scan. Several lines use leading tabs while `platforms:`/`products:`/`targets:` use spaces. Worth normalizing.
- **[Suggestion]** swift-syntax is pinned `from: "603.0.0"`. That allows any 603.x.x and up to <604, which is the standard approach but ties build to a recent toolchain. Acceptable, but worth double-checking compatibility on older Xcode.
- **[API]** Test target depends on `SuiteMacrosImpl` directly — fine for macro-expansion testing, but be aware that this couples the test target to the macro plugin module's internal symbols. The plugin product is a `.macro` target, so depending on it from a `testTarget` is the right pattern.
- **[Suggestion]** `.target(name: "Suite", dependencies: ["SuiteMacrosImpl"])`: the macro target is correctly listed as a dependency so the macro plugin is built alongside the library. No issue.
- **[Convention]** Trailing blank line at line 43 inside `targets:` array, and the macro target's stanza is indented differently from the others. Cosmetic only.

## Macro Declarations

### `Suite/SuiteMacros.swift`
- **[Bug/Diagnostics]** `CLAUDE.md` documents five macros (`@GeneratedEnvironmentKey`, `@GeneratedPreferenceKey`, `@AppSettings`, `@AppSettingsProperty`, `@NonisolatedContainer`), but only `GeneratedPreferenceKey` and `NonisolatedContainer` are declared here. The other three macros do not exist in the codebase. Either the docs are stale or the macros were removed/never finished — should be reconciled.
- **[API]** `@freestanding(declaration, names: arbitrary)` for `GeneratedPreferenceKey` is required because the generated `GeneratedPreferenceKey_<name>` type and `<name>` accessor are dynamic. Correct.
- **[API]** Module name `"SuiteMacrosImpl"` and type names match `Sources/SuiteMacrosImpl/SuiteMacros.swift` providingMacros list. Correct.
- **[Concurrency]** No `@available` annotations. The generated `PreferenceKey` requires SwiftUI (iOS 13/macOS 10.15) — the package platform minimums cover this, so no per-macro `@available` is needed. OK.
- **[API]** `@NonisolatedContainer(observing: Bool = false)` — parameter name `observing` is a bit ambiguous; "observing what?" The implementation drives `objectWillChange.sendOnMain()`. A clearer name like `publishChanges:` (matches the internal variable) or `observable:` would self-document. Suggestion only.
- **[API]** Peer-name prefix `prefixed(nonIsolatedBackingContainer_)` matches the implementation's `"private nonisolated let nonIsolatedBackingContainer_\(identifier)"`. Correct.
- **[Suggestion]** `GeneratedPreferenceKey<V>` declares a generic but the implementation extracts the type from the `type:` argument string description — the generic parameter `V` exists only for type-checking the `defaultValue:` argument. That is fine, but means callers must double-specify (`type: Int.self, defaultValue: 0`). Could be tightened in a future revision.

## Exported Modules

### `Suite/ExportedModules.swift`
- **[Suggestion]** Re-exports SwiftUI and Combine. Both are guarded by `canImport`. No issues. Note that `@_exported` is an unofficial attribute — Apple discourages public reliance — but the rest of iOS-tooling uses it consistently and it's been stable for years. OK.

## Macro Implementations

### `SuiteMacrosImpl/SuiteMacros.swift`
- **[Bug]** `providingMacros` lists only `NonisolatedContainerGenerator` and `PreferenceKeyGenerator`. Matches `Suite/SuiteMacros.swift`. OK.
- No issues.

### `SuiteMacrosImpl/MacroFeedback.swift`
- **[Diagnostics]** `diagnosticID` uses `id: message` — the human-readable message string. Two diagnostics with identical text would collide. Better to use a stable `id` per case (e.g., `"noDefaultArgument"`, `"missingAnnotation"`). Currently low-impact since each case has unique text, but `.error(...)` and `.message(...)` carry arbitrary strings and could collide.
- **[Convention]** `severity` falls into `default: .error` for `.noDefaultArgument`, `.missingAnnotation`, `.notAnIdentifier`, `.notVariableSyntax`. Explicit cases would read better, but functionally fine.
- **[Convention]** Mixed indentation (tabs + spaces). Cosmetic.

### `SuiteMacrosImpl/PreferenceKeyGenerator.swift`
- **[Bug]** Generated `struct GeneratedPreferenceKey_<name>` is missing `public` — but inside it, `defaultValue` and `reduce(...)` are declared `public`. A non-public struct cannot have public members; Swift allows the syntax but the effective access is internal, which can cause access-mismatch warnings/errors in strict modes. The struct itself should be `public` OR the members should drop `public`. (Current behavior: in macro-expansion contexts the struct is emitted into the caller's scope, so it inherits caller scope — but the explicit `public` on members is misleading and inconsistent.)
- **[Bug]** Missing `Sendable` / `@MainActor` consideration. `PreferenceKey` requires `defaultValue` to be a static constant; under Swift 6 strict concurrency, `static let` of non-Sendable type produces warnings. Generated code does not annotate. Worth adding `nonisolated(unsafe)` or requiring `V: Sendable` where possible.
- **[Bug]** Generated accessor `var <keyName>: <keyType>.Type` is declared at file scope (freestanding declaration). It is unqualified — risk of name collisions if two preference keys share a name across files. Acceptable, but consider documenting the scoping behavior.
- **[Bug]** `name(from:)` returns `segment.description` which still contains the string-literal segment as a `StringSegmentSyntax` description — typically the raw text with surrounding whitespace/quotes stripped, but does NOT validate that the string is a valid Swift identifier. A name like `"my key"` would generate invalid syntax. Add validation and a diagnostic.
- **[Bug]** `type(from:)` indexes via `args[args.index(after: args.startIndex)]` — assumes there are at least 2 arguments. If only `name:` is provided, this will crash with an index-out-of-bounds at compile time of the macro. Should guard `args.count >= 2`.
- **[Bug]** `defaultValue(from:)` requires `args.count == 3` — exactly. If user passes a labeled argument with extra trivia/whitespace causing different child counts, this could miscount. Counting `LabeledExprSyntax` children directly via `node.arguments` (which is `LabeledExprListSyntax`) is more reliable than `.children(viewMode:)`.
- **[Bug]** The `.self` stripping (`String(typeString.prefix(typeString.count - 5))`) does not trim trailing whitespace before the suffix check. `Int .self` (with whitespace) would not be detected. Minor.
- **[Diagnostics]** No diagnostic emitted for empty/whitespace `name`. Recommend validating identifier syntax and emitting a clear error.
- **[Concurrency]** Generated `reduce` is not annotated. SwiftUI's `PreferenceKey.reduce` is implicitly nonisolated/static, so this is fine.
- **[Convention]** Indentation mixes tabs and spaces.
- **[Suggestion]** The macro emits a stored variable `var <keyName>: <keyType>.Type { ... }` that is computed (returns `.self`). The name doesn't read naturally — it's effectively a typealias-shaped accessor. Consider emitting a `typealias` or naming the variable to clarify intent.

### `SuiteMacrosImpl/NonIsolatedActorAccessorGenerator.swift`
- **[Bug]** In the `PeerMacro` `expansion`, after detecting absence of `nonisolated`, the macro emits a diagnostic but continues to generate the backing container (`if !hasNonisolatedKeyword { ... diagnose }` falls through). It should `return []` to fail fast, otherwise the generated peer plus the missing keyword can produce duplicate confusing errors.
- **[Bug]** `let hasDefaultValue = patternBinding.initializer != nil` is computed inside `if let initializer = patternBinding.initializer { ... }` — by definition it is always `true` at that point. The guard `guard isOptional || hasDefaultValue` is therefore tautological. Likely a logic bug; the intent seems to be "if there's no initializer AND not optional, error" — but that branch is handled later by the `if let optionalType` else fall-through (which silently emits nothing). A non-optional, no-initializer var will produce no peer and the accessor will reference an undefined `nonIsolatedBackingContainer_X`. Should diagnose.
- **[Bug]** `patternBinding.pattern = PatternSyntax(IdentifierPatternSyntax(identifier: .identifier("defaultValue")))` mutates a local copy that is never used again. Dead code.
- **[Bug]** Optional handling: `optionalSyntaxType` returns the unwrapped `wrappedType`. The macro then re-wraps it as `ThreadsafeMutex<\(optionalType)?>` — i.e., `String??` for `var x: String?`. That's a double-optional. Should be `ThreadsafeMutex<\(optionalType)?>` only when the *original* type was optional and we want to store an optional — but we already had `optionalType` = `String`, so `\(optionalType)?` is `String?`, not `String??`. OK on inspection, but the variable naming (`optionalType` holding the unwrapped type) is misleading. Verify with a test for `@NonisolatedContainer var x: String?` — it should produce `ThreadsafeMutex<String?>`.
- **[Bug]** When the variable has an optional type and no initializer, the macro emits `.init(nil)`. Good. But when the variable has a non-optional type with an initializer, the `if let optionalType` check passes only if optional — so non-optional types with initializers fall to the `else` branch and emit `\(accessorName) = ThreadsafeMutex(\(trimmedInitializer))` with no explicit type. Type inference will work, but explicit typing would be safer (and matches the optional path).
- **[Bug]** Detection of `nonisolated` keyword iterates `varDecl.children(viewMode: .all)` and grabs the first `DeclModifierListSyntax` modifier. If multiple modifiers appear (e.g., `public nonisolated`), only the first is checked. Should iterate the full modifier list.
- **[Diagnostics]** Many error paths use generic messages (`MacroFeedback.notAnIdentifier`, `.missingAnnotation`) that don't tell the user how to fix the issue. Adding a fix-it would help.
- **[Concurrency]** Generated backing storage is `private nonisolated let ... = ThreadsafeMutex(...)`. `ThreadsafeMutex<T: Sendable>` requires `T: Sendable`. If the wrapped type isn't Sendable, the generated code won't compile. Acceptable but the diagnostic from Swift will point at the macro expansion, which is confusing — consider emitting a clearer diagnostic when the type isn't obviously Sendable, or document the requirement.
- **[Concurrency]** `objectWillChange.sendOnMain()` is called inside `set` of the generated accessor when `observing: true`. That assumes the enclosing type conforms to `ObservableObject` — there is no compile-time check or diagnostic. If the user sets `observing: true` on a non-`ObservableObject` type, error at the call site is misleading.
- **[API]** `expansion` for `AccessorMacro` parses `node.arguments` looking for the first labeled boolean expression. It does not match by label `observing:`, so any boolean literal in the first position would flip behavior. Low risk (only one arg defined) but fragile.
- **[Convention]** `extension IdentifierTypeSyntax { var type: SyntaxProtocol? { ... } }` — declared but never used in this file. Dead code? Worth verifying.
- **[Convention]** Mixed tabs/spaces indentation throughout.

### `SuiteMacrosImpl/Syntax Tree Samples.swift`
- **[Convention]** This file is just commented-out documentation/AST samples and a stub `import Foundation`. It bloats the macro plugin binary trivially. Could be moved to a `.txt` or `Documentation/` resource, but harmless as-is.
- **[Convention]** Filename contains a space (`Syntax Tree Samples.swift`). Some tools (older `swift build` configurations, certain CI systems) handle spaces in filenames poorly. Renaming to `SyntaxTreeSamples.swift` would be safer.
- **[Convention]** Header comment says `File.swift` instead of the actual filename.

## Foundation (A-K)

### `Foundation/AVPlayer.swift`
- **[Bug]** Line 23-38: `convenience init?(assetNamed:extension:)` calls `self.init(url:)` BEFORE `return nil` (line 32-33). In Swift failable initializers must `return nil` before any `self.init` call — calling `self.init(url:)` and then `return nil` is invalid for a `convenience init?` and will not compile cleanly or will leave a half-initialized instance. The early-return path on line 27-28 (success) also calls `self.init` then `return` without an explicit `return self`, which is fine but the `else` path on line 31 is broken.
- **[Convention]** Lines 16-21: Indentation looks like it was inside an outer `extension` that was deleted; the `public extension AVPlayer` block is double-indented. Cosmetic.
- **[Suggestion]** Line 54: Stray `//#endif` comment.
- **[Concurrency]** Line 17: `static let cachedMoviesDirectory` performs filesystem I/O at static init; not isolated, but acceptable.

### `Foundation/AnyEquatable.swift`
- **[Bug]** Lines 21-28: Dictionary equality uses `if let i1 = d1[key], let i2 = d2[key]` — if a value is legitimately `nil` (Optional<Any> wrapped), this falsely returns `false`. Also keys-not-equal case is not detected explicitly: if `d1` and `d2` have different key sets but same count, `d2[key]` may be nil and trigger early `false`, which happens to be correct but for the wrong reason.
- **[API]** No `Sendable` annotations on public free functions taking `Any` — fine since `Any` isn't Sendable, but consumers can't use this from concurrency contexts safely.

### `Foundation/Array.swift`
- **[Bug]** Line 70-79: `removingDuplicates()` seeds `result` with `self.first` and then iterates `for item in self` starting from index 0 — the first item is added twice in the seed but then the `contains` check rejects it, so it works, but it's confusing. More importantly the function preserves order O(n²). Could use `Set` if `Element: Hashable`.
- **[Perf]** Line 70-79: O(n²) `contains` lookups; document or add a hashable overload.
- **[Bug]** Line 47-51: `last(_ number:)` will crash if `number` is negative (`count - number` > count → out of range). Same for `first(_:)` with negative input.
- **[Bug]** Line 119-140: `breakIntoChunks` with `growth != 1.0` can produce a final chunk smaller than expected; also `chunkSize = Int(Double(chunkSize) * growth)` after appending may produce 0 if `growth < 1`, causing infinite loop.
- **[Perf]** Line 144-156: `Collection.split(by:)` returns groups in dictionary iteration order (non-deterministic). Worth documenting.
- **[Convention]** File is 164 lines — slightly over.

### `Foundation/Box.swift`
- No issues.

### `Foundation/Bundle.swift`
- **[API]** Lines 11-16: `Bundle` extensions are missing `public` on the extension itself — properties are `public` but it works. Style inconsistency vs other files.
- **[Bug]** Line 56-60: `Directory.init?` sets `self.urls = []` and then `return nil` — assigning before returning nil from a struct failable init wastes work, but this is not a bug, just ugly. However: `bundle.urls(forResourcesWithExtension:subdirectory:)` returning nil for an empty/missing subdirectory means `Directory(...)` returns `nil`, but the file says `return Directory(bundle:...)` on line 36 — fine.
- **[Convention]** Header comment says "MobileProvisionFile.swift" — copy-paste leftover.

### `Foundation/Calendar.swift`
- **[Bug]** Line 29: `TimeZone.gmt` force-unwraps `TimeZone(secondsFromGMT: 0)!`. While this should never fail, the construction is now redundant given the GMT identifier lookup. iOS 16+ provides `TimeZone.gmt` natively — name collision risk.
- **[API]** `firstDayInMonth` uses `Calendar.current` implicitly via `self`, fine.

### `Foundation/Codable.swift`
- **[Bug]** Line 232: `self.init(rawValue: rawValue)!` force-unwraps inside the extension `RawRepresentable where RawValue == Int, Self: Codable`. Decoding an unknown int raw value crashes. The `do { }` on line 231 is also pointless (no catch).
- **[Convention]** File is 241 lines — over.
- **[API]** Line 52: `JSONExpandedDecoder` is `@unchecked Sendable` — uses inheritance to inject `awakeFromDecoder`. Subclassing JSONDecoder is supported but fragile.
- **[Concurrency]** Line 175 `static let default = JSONDecoder()` is mutable shared state; if any caller mutates `dateDecodingStrategy` etc., that's racy. Should be `let` of an immutable configured instance, but JSONDecoder isn't immutable. Worth documenting "do not mutate".
- **[Suggestion]** Line 86-90: Inconsistent — `iOS 15` for `formatted()` but the `else` branch uses `localTimeString()` with default styles. Min deployment is iOS 13.
- **[Bug]** Line 207-225: Large commented-out block — dead code; should be removed.

### `Foundation/Collection.swift`
- **[Suggestion]** Line 15-17: `compactMap()` with `as? Result` shadows the standard `compactMap`; can confuse type inference. Consider renaming to `compactCast()`.

### `Foundation/CommandLine.swift`
- **[Bug]** Line 28-33: `int(for:)` does `Int(raw.numbersOnly) * -1` on prefix `"-"` but `numbersOnly` strips the minus already, so this works — however zero edge case `"-0"` returns 0 (fine). What about `"-9223372036854775808"` (Int.min)? `* -1` overflows.
- **[Concurrency]** Line 11-18: `threadsafeArguments()` is named "threadsafe" but accesses `CommandLine.unsafeArgv` which is documented as not thread-safe. The name is misleading; the implementation copies into a Swift array, but the read of `unsafeArgv`/`argc` itself is the unsafe part.

### `Foundation/Condensable.swift`
- **[API]** Line 22: Protocol `Reconstitutable: Condensable` requires `init(condensed:)` but Condensable doesn't. Fine.
- **[Suggestion]** Line 47: `if let version = self.condensed?.version, version >= condensed.version { return }` silently no-ops on equal versions — caller can't tell load was skipped. No throw or signal.

### `Foundation/Data.swift`
- **[Bug]** Line 25: `Array<UInt8>(repeating: 0, count: hex.count / 2)` uses `hex.count` (grapheme count), but the loop iterates over `utf16` views. For non-ASCII hex strings, sizes differ — overrun possible (shouldn't happen for valid hex but defensive). Also if hex has odd length, the last byte is silently dropped.
- **[Bug]** Line 73-82: `debug_save` returns `URL!` (implicitly unwrapped) but returns `nil` on failure — caller force-unwraps and crashes. Should return `URL?`.
- **[Bug]** Line 109: `self = self.dropFirst(stride)` returns `Data.SubSequence` (which is `Data`); fine. But `peek` uses `MemoryLayout.size` while `consume` uses `stride`. Inconsistent — fix one or the other.

### `Foundation/Date+String.swift`
- **[Concurrency]** Line 26: `DateFormatter()` is allocated each call — not a concurrency bug but a perf hit, and in old iOS DateFormatter wasn't thread-safe; current is fine but allocation is expensive.
- **[Platform]** Line 25-56: All locale-dependent operations use `DateFormatter` without setting `Locale` — output varies by user. The class doc forbids "locale-dependent code without locale param" — flag.
- **[Bug]** Line 42-49: `:00` substring matching is locale-dependent; in locales using non-Western digits this misses.

### `Foundation/Date.Day.swift`
- **[Concurrency]** Lines 122-124: `var date: Date { Date(calendar: .current, timeZone: .current, ...) }` — uses `.current` which is locale/timezone-dependent. A `Day(2026, 5, 3)` represents two different `Date` values for different users. This may be intended but is a footgun.
- **[Bug]** Line 113: `year < 1000 ? year + 2000 : year` — heuristic for two-digit years; year 999 isn't expanded, year 1000 is. Edge cases poor.
- **[Bug]** Line 174-175: Multi-line ternary inside `init(_ date:_ time:)` is hard to read and may produce wrong nil semantics if `time?.isNever == true`.
- **[Convention]** Line 174-175: Multi-line function declaration — actually a single long line; declaration violates 100-line file convention indirectly.
- **[Convention]** File is 190 lines.

### `Foundation/Date.DayOfWeek.swift`
- **[Bug]** Line 47-54: `days(since:)` uses `abs(lastIndex - firstIndex)` — "days since" should be directional, not absolute. Saturday since Sunday should be 6, not 1.
- **[Concurrency]** Line 21, 23, 27, 29-30: Uses `Calendar.current` — locale-dependent.

### `Foundation/Date.Month.swift`
- **[Bug]** Line 20: `abbrev` returns `Calendar.current.veryShortMonthSymbols[self.rawValue]` — off-by-one. Other accessors use `rawValue - 1`. Will crash for `.dec` (rawValue 12, array has 12 elements at indices 0-11). This is a definite crash bug.
- **[Concurrency]** Lines 20-22: `Calendar.current` for symbols — locale-dependent.

### `Foundation/Date.Time.swift`
- **[Bug]** Line 197: `self.second = min(second, 59)` — should also clamp to >= 0; allows negative.
- **[Bug]** Line 175: `else if second > 60` should be `>= 60` (60 is invalid).
- **[Bug]** Line 141: `let end = end.hour <= hour ? end.hour + 12 : end.hour` — adding 12 for "PM" assumption is wrong; should add 24 for next-day.
- **[Bug]** Line 169: `Int(seconds / 60) % 60` — when `seconds` is 0, `0 / 60 = 0`, OK. But when adding e.g. 90 seconds: `Int(90/60) = 1`, `1 % 60 = 1`. So 90 seconds becomes 1 minute + 30 sec? Actually line 168: `second = self.second + TimeInterval(Int(seconds) % 60)` → 90 % 60 = 30, plus minute 1 from line 169. OK, but the algorithm is dense and untested for edge values.
- **[Bug]** Line 323-325: `meridian` returns `.am` for `hour == 24` (invalid hour). Init clamps with `hour % 24`, so impossible — but defensive.
- **[Concurrency]** Lines 290-298: `Calendar.current` in `date` property.
- **[Convention]** File is 349 lines — well over 100.

### `Foundation/Date.swift`
- **[Convention]** File is 553 lines — far over 100. Should be split (e.g., Date+Formatting, Date+Components, Date+AgeString).
- **[Bug]** Line 326-336: `iso8691String` — typo "8691" should be "8601". Same on line 330.
- **[Bug]** Line 301-305: `midnightUTC` adds GMT offset to local midnight, which gives the wrong direction for any non-GMT zone. To get UTC midnight you'd want `start of day in UTC`. The logic is suspect.
- **[Bug]** Line 480-481, 484-485: `thisWeek` and `upcoming` are duplicates of each other.
- **[Concurrency]** Line 246-249: `isIn24HourTimeMode` uses `Locale.current` — locale-dependent (correctly so), but result is recomputed every call.
- **[Concurrency]** `Calendar.current` used everywhere; no timezone-aware overloads.
- **[Bug]** Line 524: `Meridian.shows` static method — fine but on enum case fall-through.
- **[Suggestion]** Line 545-553: `Date: @retroactive RawRepresentable` with rawValue as `String(format: "%f")` is locale-independent (good), but `init?(rawValue:)` returns Date(timeIntervalSinceReferenceDate: 0.0) on parse failure — should return nil on invalid input.

### `Foundation/DateFormatter.swift`
- **[Concurrency]** Line 10: `extension Formatter: @unchecked @retroactive Sendable` — declaring all Formatter subclasses Sendable is dangerous; DateFormatter is documented as thread-safe on macOS 10.9+/iOS 7+, but NumberFormatter and others may not be. Consider being more targeted.
- **[Suggestion]** Line 25-29: `convenience init(format:)` always sets `en_US_POSIX` locale — good for parsing fixed formats.

### `Foundation/DateInterval.swift`
- **[Bug]** Line 19: `let end = self.sorted(by: { $0.end > $1.end }).last?.start` — uses `.start` of the latest-ending interval, but should be `.end`. This is a clear bug — `fullRange` returns wrong end.
- **[Perf]** Lines 18-19: Two separate `sorted` calls, both O(n log n), to get min/max — should use `.min`/`.max`.
- **[Bug]** Line 39: `self.removeSubrange(firstIndex..<lastIndex)` — non-inclusive of `lastIndex`, then inserts a merged interval. If `firstIndex == lastIndex` (single overlap) this removes nothing and inserts. Bound checking suspect.

### `Foundation/DateTag.swift`
- No issues.

### `Foundation/Decoding.swift`
- **[Suggestion]** Line 53-63: `JSONDecoder.DateDecodingStrategy.encodingStrategy` references `.default` — there is no `JSONEncoder.DateEncodingStrategy.default`. This will fail to compile unless defined elsewhere.
- **[API]** Line 36-39: `SafeResult` struct fields are `let`; init synthesized but not public — `SafeResult` cannot be instantiated outside the module.

### `Foundation/Dictionary.swift`
- **[Bug]** Line 55: `if isEqual(value, otherValue) { continue }` — depends on `isEqual` from AnyEquatable, which has the dictionary nil-value bug noted above.
- No major issues otherwise.

### `Foundation/DiskBackedArray.swift`
- **[Concurrency]** Entire file: This struct is value type but mutates the disk on `set`. Two simultaneous mutations through different copies will overwrite each other; not atomic across instances. The `save()` on line 39 uses `.atomic` for the file write, but the in-memory `cache` is not protected. Two threads writing to the same backing URL race.
- **[API]** No way to remove, append, count, or iterate. Only subscript access — caller must call `cache[index]` but `cache` is internal. Public API is essentially useless beyond replacing existing indices.
- **[Bug]** Line 50-58: `extension DiskBackedArray where Value: Equatable` redefines `subscript`, but Swift will use the more constrained one only when `Value: Equatable`. However, having both `set` blocks call `save()` and the constrained one short-circuit is correct. Note: the un-constrained subscript still exists, so calling `array[0] = newValue` on `DiskBackedArray<Int>` may resolve to either depending on context.
- **[Bug]** Line 16-22: Subscript `set` does NOT check bounds; out-of-range write crashes (Array semantics).
- **[Suggestion]** Line 9: Not Sendable; can't be used in concurrent contexts.
- **[Bug]** Line 36: `save()` is not `mutating`; OK because `cacheURL` etc are `let`. But `cache` on line 14 is `var` — `save()` reads `cache`, so it's a non-mutating method on a value type that triggers I/O — fine.

### `Foundation/DiskBackedDictionary.swift`
- **[Concurrency]** Same as DiskBackedArray — no synchronization, races on the file URL across instances/threads.
- **[Bug]** Line 64-88: The `Equatable` extension redefines both subscripts, but the unconstrained subscripts (lines 16-35) also exist on the same type. Swift dispatches via static type; with `Value: Equatable` the constrained ones win in generic contexts but not always — confusing overlap.
- **[Bug]** Line 31-34: `subscript[_:default:]`'s setter does not check `cache[key] != newValue` (only the Equatable variant does). Inconsistent: writes always trigger save even if unchanged.
- **[API]** Not Sendable; no way to enumerate, remove all, get count.

### `Foundation/Enums.swift`
- **[Bug]** Line 11: `Self.allCases.randomElement()!` crashes on empty enum (no cases).
- **[Suggestion]** Line 19-28: `next()` could use `firstIndex(of:)` instead of manual loop.

### `Foundation/Error.swift`
- **[Suggestion]** Line 21: Hard-coded `code == 260` — would be clearer as `NSCocoaErrorDomain` + `CocoaError.fileNoSuchFile`. Same magic numbers on line 29 (`999`) and line 33 (`-1009`). Use `URLError.Code` constants.
- No bugs.

### `Foundation/FileManager.swift`
- **[Bug]** Line 64-68: `count == 1` after `count += 1`: first iteration `count` is 1, sets `name = base` — same as initial `name`! Caller will then loop again because file exists. The intended logic was probably "for first collision, use 'base 2'". Off-by-one in unique-naming algorithm.
- **[Suggestion]** Line 24-46: `copy(itemsAt:into:)` swallows errors when `ignoringErrors` true; also `try?` on createDirectory unconditionally — if creation fails for non-exists reasons, downstream calls fail.
- **[Convention]** File is 116 lines.

### `Foundation/FunctionBox.swift`
- **[Concurrency]** Line 15: `closure: () -> Void` is non-Sendable; struct is not Sendable. If used across actors, needs `@Sendable` and `Sendable` conformance.
- **[API]** Hash uses `(file, function, line)` only, ignoring closure — two `FunctionBox` from same call site but different closures hash equal. Probably intended (deduplication by call site), but worth documenting.

### `Foundation/Int.swift`
- **[Platform]** Line 42-45: `arc4random_uniform` is fine on Apple platforms but Swift's `Int.random(in:)` is preferred.
- **[Bug]** Line 49-57: `UInt32.fourCharacterCode` builds UTF-16 from individual bytes — but FourCC codes are typically big-endian ASCII; this iterates LSB first, so output may be reversed depending on host endianness. Compare to `FixedWidthInteger.characterCode` which iterates MSB first.

### `Foundation/Int64.swift`
- **[Concurrency]** Line 11: `@MainActor static let byteFormatter` forces all `bytesString` calls to MainActor. ByteCountFormatter is thread-safe per Apple; this restriction is unnecessary and prevents background formatting.
- **[API]** Forcing `@MainActor` on a numeric extension is surprising for callers.

## Foundation (M-Z)

### `Foundation/MD5.swift`
- **[API]** `[MD5able].md5` joins per-element MD5s with `-`, then arrays of `Data`/`String` with the same elements but different sizes can collide if elements are themselves arrays. The `compactMap { try $0.md5 }` swallows `nil` returns silently — but `md5` is non-Optional, so `compactMap` provides no benefit and obscures intent. Use `map`. (line 23)
- **[Suggestion]** `MD5ableError` is internal but extends `LocalizedError`; the type itself isn't `public` so callers in clients can't catch the specific cases. (line 29)
- **[Convention]** Single-line case-with-payload enum decl on line 29 is unusual style.
- **[Perf]** `URL.md5` loads the entire file into memory via `Data(contentsOf:)`. Large files will blow up memory. Should stream via `FileHandle` and `Insecure.MD5` updates. (line 69)

### `Foundation/NSItemProvider.swift`
- **[Platform]** `NSItemProviderImage` typealias is gated on `canImport(UIKit) || canImport(AppKit)`, but other code (e.g., `extractProviderImage`) returns `NSItemProviderImage?` unconditionally. On a platform where neither imports (none on Apple, but defensively) the file won't compile — minor. (line 11-17)
- **[API]** `extractURLFromItem` is `internal`; `extractProviderImage` and `extractImageFromProvider` are `internal`/`private`. Inconsistent visibility; if intended as helpers, mark `private`. (line 47, 66)
- **[Bug]** When iterating image types with priority, the inner `for itemProvider` loop returns the first match for the first matching type. If a provider has a higher-priority type elsewhere in the array, a lower-priority earlier item still wins. Logic looks intentional but worth documenting. (line 70-78)
- **[Convention]** Mixed indentation (tabs vs. spaces) starting around line 82 — file uses spaces in `extractImageFromProvider` body which doesn't match the rest.

### `Foundation/NSObject.swift`
- **[Concurrency]** `addAsObserver` uses target-action `NotificationCenter` API; in Swift 6 strict concurrency, `Selector`-based observer registration on an arbitrary `NSObject` makes Sendable analysis difficult. Acceptable but worth flagging.
- **[API]** `associate(object:forKey:)` uses `key.utf8Start` which is a `UnsafePointer<UInt8>` — fine for `StaticString` but the addresses are not guaranteed stable across optimization levels for short literals. Apple's `objc_setAssociatedObject` documentation expects a unique pointer per key; relying on `StaticString.utf8Start` is fragile. Prefer `& unsafeBitCast` of a unique key constant. (line 45-47)
- **[Memory]** No issue with retain cycles since AssociationPolicy is `RETAIN_NONATOMIC`, but the API offers no `ASSIGN`/`COPY` choice.

### `Foundation/Notification.swift`
- **[Concurrency]** `postOnMainThread` uses `MainActor.run` synchronously without `await`, which only compiles if the call site is already on `@MainActor`; otherwise this is a compile error in Swift 6. Should be `Task { @MainActor in … }` or marked `async`. (line 51)
- **[API]** `userInfo: [String: Sendable]?` then casts to NotificationCenter's `[AnyHashable: Any]?` is fine, but `object: Sendable?` at the call site is not type-checked against actual receiver semantics.
- **[Convention]** Lots of commented-out code (lines 11-24, 36) — should be cleaned up.

### `Foundation/NumberFormatting.swift`
- **[Bug]** `Double.pretty`: `result[0...(decPos + limit)]` uses `String`'s integer subscript which calls `index(_:offsetBy:)` clamped to count. If `decPos + limit >= count`, this just returns the full string (handled by the prior length check). However the slicing returns *inclusive* of `decPos + limit`, which gives `limit + 1` characters after the decimal — looks like an off-by-one. (line 44)
- **[Bug]** `result.hasSuffix("0")` strip loop will remove trailing zeros from integer-formed strings like `"100"` when there's no decimal — but the early return on `decPos == nil` saves it. OK, but `"1.0".pretty()` returns `"1"` then re-adds `".0"` if `includeDecimal` — convoluted. (line 48-52)
- **[Concurrency]** `private let formatter: NumberFormatter` is a global mutable Foundation type; `NumberFormatter` is documented thread-safe on macOS 10.9+/iOS 7+ but not annotated `Sendable`. Will warn under strict concurrency. (line 57)
- **[Bug]** `string(decimalPlaces: padded:)` while loop `while result.hasSuffix("0") || result.decimalPlaces > decimalPlaces` will strip legitimate trailing zeros even when `decimalPlaces` are intended. E.g., `"10.00".string(decimalPlaces: 2)` → strips to `"1"` (then "1.")? Bug. (line 81)
- **[Perf]** `numbersOnly` (used elsewhere) and string ops here construct many intermediate strings.

### `Foundation/Operators.swift`
- **[API]** Custom non-ASCII operators `∆=` and `≈≈`/`!≈` are declared but `≈≈` and `!≈` have no implementations in this file — leaks declarations or relies on definitions elsewhere. (line 12-13)
- **[Suggestion]** `∆=` returning a value while also being assignment is unusual; `@discardableResult` is good, but mixing return semantics with `inout` mutation surprises readers.

### `Foundation/OptionSet.swift`
- No issues.

### `Foundation/Optional.swift`
- **[Bug]** `Optional<Wrapped: Comparable>.<` returns `true` when both operands are nil (`lhs == nil` falls into first guard), violating strict weak ordering (`a < a` should be false). This will break any sort relying on it. (line 11-15)
- **[API]** Defining `<` on `Optional<Wrapped>` shadows/competes with potential `Optional: Comparable` conformance and is surprising; consider a different name.

### `Foundation/Pluralizer.swift`
- **[Concurrency]** Uses `CurrentValueSubject` (Combine) — violates "use async/await, not Combine" project rule. (line 18)
- **[Concurrency]** `Pluralizer` is `final class: Sendable` but mutates `plurals.value` from `nonisolated` setter — `CurrentValueSubject.value` is documented as thread-safe per Apple, but Read-Modify-Write on line 34 (`plurals.value[key] = newValue`) is **not atomic**: read returns a copy, mutate, write — racy. Two writers race. Should use a lock/`ThreadsafeMutex`. (line 34)
- **[API]** `pluralize` returns "1 singular" but no caller-controlled mapping for "1" (irregulars handled via plurals dict only).

### `Foundation/Process.swift`
- **[Platform]** Uses deprecated `launchPath`/`launch()` (deprecated since macOS 10.13 in favor of `executableURL`/`run()`). (line 17, 62, 74)
- **[Bug]** `run(timeout:)` returns `9` on timeout — magic number; not a real exit code. Should be a documented constant. (line 70)
- **[Concurrency]** Uses `RunLoop.current.run(...)` polling loop — synchronous busy wait. Project rule says use async/await. The whole API is sync. (line 67)
- **[Bug]** `stringValue`/`errorValue`/`dataValue` check `self.standardOutput as? Pipe == nil` then call `self.run(...)` — but `run` *unconditionally* assigns `self.standardOutput = Pipe()`, so the guard on having previously set a pipe is meaningless. Also re-running `run` overwrites prior output. (line 21-22, 54)
- **[Bug]** `errorValue` calls `run` which sets `standardOutput`/`standardError` to fresh pipes but checks `standardError` — coherent only if called before `stringValue`. State coupling is fragile.

### `Foundation/ProcessInfo.swift`
- **[Bug]** `int(for:)`: `raw.numbersOnly` strips the leading `-`, then re-applies negation if `raw.hasPrefix("-")` — but `numbersOnly` also strips internal characters; "1-2" yields 12 with no sign handling. Edge case but odd. (line 21-23)

### `Foundation/PropertyList.swift`
- **[Bug]** `PropertyListItem(_:)` uses `(any as Any) as? PropertyListDataType` — the double-cast through `Any` is a no-op but masks the fact that `PropertyListDataType` is a marker protocol with no requirements; *any* type can fail this check arbitrarily. The function is largely useless. (line 42-44)
- **[API]** `Data.propertyList` only returns dict; if plist root is array, returns nil silently. (line 47)
- **[API]** `format` is initialized to `.binary` but `propertyList(from:format:)` overwrites it on success — initial value misleading. (line 48)

### `Foundation/Range.swift`
- No issues.

### `Foundation/Result.swift`
- No issues.

### `Foundation/StableMD5.swift`
- **[Bug]** Hashing for `Date` differs between dictionary path (`timeIntervalSinceReferenceDate`) and array path (`String(describing: date)` → locale-formatted!). Two stable-MD5 results disagree for the same content depending on whether it's an array element vs. dict value. Critical inconsistency. (lines 35 vs 76)
- **[Bug]** `Float`/`Double` hashed via `String(describing:)` — locale/format-sensitive; `Double(0.1+0.2)` etc. produce different strings on different runtimes. Also `1.0` vs `1` hash differently. Use `bitPattern` or canonical form. (lines 31-33)
- **[Bug]** Dictionary path silently *skips* unknown JSON value types (no `else throw`), so adding a new field type changes the hash without warning. Array path *does* throw. Inconsistent. (line 22-43)
- **[Bug]** `KeyHash.hash` is Optional but always populated; the `??` fallback to "" hides bugs. (line 47, 97)
- **[Concurrency]** `JSONDictionary` is unordered; sorting only by key is correct, but if two keys share a hash (impossible with MD5 of different keys' values, but they'd collide via concatenation: `"ab"+"cd"` == `"abc"+"d"`). Not realistic for MD5 hex but worth noting structurally.
- **[Convention]** File header still says "DataModel"/"DetectionTek" — copy-paste leftover. (line 4-6)

### `Foundation/String.swift`
- **[Bug]** `extractSubstring(start:end:)` references undefined `string.endIndex` and `string[…]` — `string` is not declared anywhere. This won't compile (or relies on some shadowed name). Confirmed used by `MobileProvisionFile.swift`. Critical bug. (line 163, 168)
- **[Bug]** `entropicString`: when `random >= charset.count` (count=64, random in 0..255), the byte is discarded but the surrounding `(0..<16).map` still allocates the full batch — minor. More critical: `randoms.forEach` early-returns inside closure but `forEach` doesn't break the outer loop, so `remainingLength` may be decremented past 0 in subsequent batches — actually `if remainingLength == 0 { return }` inside `forEach` returns from the *closure*, not the outer `while`, so the next iteration still runs but immediately exits. OK but inefficient. (line 148-155)
- **[Bug]** `entropicString` charset string `"…UVXYZ…"` is missing `W` between `V` and `X`. Likely a typo. (line 131)
- **[Bug]** `stringByRemovingCharactersInSet`: indexes `self[count]` using `Int` subscript; `count` is the unicode scalar index, but `self[Int]` uses `Character` indexing — these diverge for any string with multi-scalar grapheme clusters (emoji, accented chars). Result is wrong. (line 122)
- **[Bug]** `subscript(range: ClosedRange<Int>)` calls `index(range.upperBound)` for the upper, which clamps to `count` — if `upperBound == count - 1`, `index(_:)` returns the index *at* that position; then `...` includes it, fine. But for `range.upperBound == count`, this would crash on `[…]` operator. Caller-beware. (line 46)
- **[API]** `subscript(i: Int)` crashes when `i >= count` because `index(_:)` clamps to `count` and then `self[endIndex]` traps. (line 44)
- **[Bug]** `pathExtension` returns nil if the extracted extension is `>= 10` chars — arbitrary heuristic that breaks for legitimate long extensions. (line 73)
- **[Bug]** `deletingFileExtension` computes index by `-(ext.count + 2)` but should be `-(ext.count + 1)` for the dot — adds an off-by-one that will clip the previous character. Wait: `ext.count` chars + `.` = `ext.count+1` from end, so offset should be `-(ext.count+1)`. With `+2` it drops one extra char. Bug. (line 81)
- **[Bug]** `isValidPhoneNumber` uses `NSMakeRange(0, self.count)` — `count` is grapheme count, but `NSRange` expects UTF-16 length. Mismatch for emoji/composed chars. Should be `(self as NSString).length`. (line 108)
- **[Convention]** File ~235 lines, exceeds ~100-line guideline. Should be split.
- **[API]** `init(_ lines: String...)` overloads `String(...)` in confusing ways; calling `String("a","b")` joins with newline — surprising.
- **[API]** Custom `==` and `+` between `String` and `String?` masks Optional sites and can hide nil bugs. (lines 182-198)

### `Foundation/StringIdentifiable.swift`
- **[Suggestion]** The `#if canImport(Combine)` gate is unrelated to the protocol — likely meant `canImport(SwiftUI)` since `Identifiable` is in stdlib. Both branches define almost the same protocol; gate is dead. (line 10)

### `Foundation/StringInterpolation.swift`
- **[Bug]** `encoder` is created but never used — the actual `prettyJSON` uses its own encoder (line 13-14). Dead code. (line 12)
- **[Bug]** Falls through silently if `prettyJSON` returns nil — no fallback / no representation. (line 15-17)
- **[Convention]** Imports SwiftUI but only uses Foundation/JSON. (line 8)
- **[Style]** Trailing `}}` on line 18.

### `Foundation/ThreadsafeMutex.swift`
- **[Concurrency]** `value` getter `lock.withLock { value in value }` returns by copy — fine for value types, but if `T` is a reference type, returns the reference under-lock without copy semantics; OK. The pattern is correct.
- **[API]** `set(_:)` is redundant with the setter; not harmful.
- **[API]** `perform(block:)` accepts `(inout T) -> Void` non-throwing; would benefit from a throwing/return-value variant.
- **[Concurrency]** `nonisolated public var value` getter+setter combination: setter does read-modify-write across two `withLock` calls? No — it's a single `withLock { value = newValue }`. OK.
- **[Suggestion]** Class is `@unchecked Sendable`, but with `OSAllocatedUnfairLock<T: Sendable>` it should be safely Sendable already; `@unchecked` is over-broad. (line 12)

### `Foundation/Throwable.swift`
- No issues.

### `Foundation/TimeInterval.swift`
- **[Bug]** `milliseconds` is misnamed — returns the fractional seconds (0..<1), not milliseconds. Used in `durationString` which then formats with `centisecondFormatter` (2 decimals)/`millisecondsFormatter` (3 decimals) to produce ".XX"/".XXX" — works for the formatted output, but the property name lies. (line 104-106)
- **[Bug]** `durationString` for `.deciseconds`/`.centiseconds`/`.milliseconds` uses `hours > 0` (unconditionally treats as Int>0 from absolute), then concatenates a number string with leading "0." — but `decisecondsFormatter` has `maximumIntegerDigits = 0` so the result is `.5` not `0.5`. Then concatenated to "01:23" yields "01:23.5". OK by intent.
- **[Bug]** `init?(string:)`: when `comps.count == 0` (impossible since `components` always returns at least 1) or `default`, sets `self = 0` *then* returns nil — assigning before failing init is fine in Swift but the assignment is wasted. (line 175-203)
- **[Convention]** File ~205 lines; exceeds ~100-line guideline. Could split duration formatting out.
- **[Concurrency]** Static formatters (`durationFormatter`, `centisecondFormatter`, etc.) are mutable Foundation types — `DateComponentsFormatter` is documented thread-safe (uses internal queues) but `NumberFormatter` is, but both are not `Sendable`-marked. Strict concurrency warnings expected. Also `formatter.allowedUnits = …` mutates the shared `durationFormatter` — explicit data race if called from multiple threads. (line 32, 65)

### `Foundation/TimePost.swift`
- **[Convention]** Entire file is commented-out deprecated code. Should be deleted, not kept. (lines 10-59)

### `Foundation/Timer.swift`
- **[Concurrency]** Uses Combine (`Publishers.Autoconnect<Timer.TimerPublisher>`) — violates "use async/await, not Combine" project rule. The whole file is gated on `canImport(Combine)`. (line 12)
- **[Concurrency]** `nonPausingTimer` adds Timer to `RunLoop.main` from arbitrary thread — Timer must be added on the thread it'll fire on, generally main. Potentially racy when called off-main. (line 18)

### `Foundation/URL+ExtendedAttributes.swift`
- **[Bug]** `extendedAttribute(for:)` initial `length` call uses `errno`-less guard `length >= 0` — but `getxattr` returning -1 sets `errno`; the code throws `.noAttributeFound` for any failure (could be `EACCES`, `ERANGE`, etc.), masking real errors. Should differentiate. (line 23)
- **[Bug]** Race condition: between probing `length` and reading with that buffer size, the attribute could grow. `getxattr` will return `-1` with `ERANGE`; second call's guard catches it but throws `.posixError(errno)`. Acceptable but worth a retry loop. (line 22-32)
- **[Bug]** `allExtendedAttributeNames` allocates `namebuf` of `length` from the first probe; same TOCTOU risk. (line 78-83)
- **[API]** Uses `errno` immediately after the call — fine, but the initial-length call doesn't capture `errno` before the next syscall. (line 23 vs 32)

### `Foundation/URL+Files.swift`
- **[Bug]** Force-unwraps in `static let documents`, `applicationSupport`, etc. — if `NSSearchPathForDirectoriesInDomains` is empty (sandboxed weirdness), crash. (line 48-52)
- **[Bug]** `applicationSpecificSupport` falls back to `Bundle.main.name` if no bundle identifier — fragile, may produce localized/spaced paths. (line 52)
- **[Concurrency]** Multiple `static let` initializers call `FileManager.default` on first access — fine, but `Bundle.main` isn't `Sendable`-marked.
- **[Bug]** `audioDuration`: on non-visionOS platforms uses sync `reader.asset.duration` which is deprecated; should use async `load(.duration)` everywhere. (line 22)
- **[API]** `tempFile(named:)` and similar call `_ = url.dropLast().existingDirectory` for side-effect of creating intermediate directories — non-obvious. (lines 57, 63, 69, 75)

### `Foundation/URL+Images.swift`
- **[API]** `resizedContainedImage` is `internal` (no `public`); likely meant to be public given it's a utility. (line 35, 46)
- **[API]** UIKit branch produces `UIImage(cgImage:)` which loses scale/orientation; should accept a scale argument or use `UIImage(cgImage:scale:orientation:)`. (line 47)

### `Foundation/URL.swift`
- **[Bug]** `URL.init(stringLiteral:)` force-unwraps — string literal `"not a url"` will trap at runtime. While this is common, it bypasses the value type's sendable safety for invalid string literals. (line 45)
- **[Bug]** `init(_ string: StaticString)` similarly force-unwraps. (line 96)
- **[Bug]** `containsHomeDirectory`: `path.contains("~")` matches any URL with a tilde *anywhere*, not just at start — false positives. Should check `hasPrefix("~")` or normalize. (line 105)
- **[Bug]** `removingHomeDirectory` returns `URL(string:)` of an abbreviated path — `abbreviatingWithTildeInPath` produces `"~/Foo"` which is **not a valid URL string** (no scheme); `URL(string:)` returns a non-file URL or nil. Bug. (line 110)
- **[Bug]** `addingHomeDirectory`: `replacingOccurrences(of: "~", with: "")` removes *all* tildes, not just leading; then prepends home — produces wrong path if file legitimately contains `~`. Use `expandingTildeInPath`. (line 116)
- **[Bug]** `componentDirectoryURLs` produces `[URL("/")] + [URL("/"), URL("/foo"), …]` — duplicates root, and `components` on a path beginning with `/` includes an empty first element, so first map produces `URL("/")` again. Off by-one duplicate. (line 126-135)
- **[Bug]** `pathRelative(to:)` uses `normalizedString` for comparison — but normalized for HTTP URLs adds default `https://sample.com` if missing; comparing two file URLs is fine but the function is brittle. (line 137-144)
- **[Bug]** `isSubdirectory(of:)` uses `path.hasPrefix(url.path)` — without trailing slash this matches `"/foo"` as subdir of `"/foob"`. Bug. (line 122-124)
- **[Bug]** `contains(fileURL:)` similarly uses string prefix without boundary; same bug. (line 250-257)
- **[Bug]** `init?(_ string: String, _ query: [String: String])`: assigns to `var base = URL(...)`, then `base.queryDictionary = query`. Since `queryDictionary` setter does `self = newURL`, mutating `base` works. OK actually. (line 88-93)
- **[Bug]** `URL.application` is `@MainActor static var` of type `UIApplication?` — global mutable singleton; works but spreads UIApplication coupling.
- **[Concurrency]** `static let documents`, etc. (in URL+Files) and `static let blank: URL` — `URL` is Sendable, OK.
- **[Bug]** `normalizedString` substitutes `"sample.com"` for missing host — surprising silent default that affects equality semantics of the property. (line 235)
- **[Bug]** `normalizedString` percent-encoding: query values aren't re-encoded; `&` inside a value will produce malformed reconstructed URL.
- **[Convention]** File ~330 lines, way over ~100-line guideline. Split into multiple files.
- **[API]** `extension URL: @retroactive ExpressibleByStringLiteral` with force-unwrap is a footgun for clients of the library — retroactive conformance can conflict with other libraries. (line 43)
- **[API]** `extension URLQueryItem: @retroactive Comparable` — same retroactive concern. (line 272)

### `Foundation/URLRequest.swift`
- **[Bug]** `curl`: doesn't escape single quotes inside header values or body — a body containing `'` will break the shell command. Should use shell-escape. (line 35, 39)
- **[API]** Skips Cookie header silently — may surprise users debugging auth. (line 33)

### `Foundation/URLResponse.swift`
- No issues.

### `Foundation/UUID.swift`
- **[Bug]** UUIDv7 timestamp is supposed to be 48 bits of milliseconds since Unix epoch in big-endian order in bytes 0-5. `UInt64(Date().timeIntervalSince1970 * 1000.0)` truncates to UInt64; that's fine, but `* 1000.0` introduces floating-point rounding for current dates (loss is sub-ms but still). Better: `UInt64(Date.now.timeIntervalSince1970.rounded(.down) * 1000) + UInt64(fractionalMs)`. Minor. (line 14)
- **[Bug]** Bytes 7 and 9-15 retain UUIDv4 random material from `UUID()` — correct per spec. Byte 6 mask `0x0F | 0x70` sets version 7 — correct. Byte 8 mask `0x3F | 0x80` sets variant — correct. Looks right.
- **[Suggestion]** Empty trailing line after `return UUID(uuid: uuid)` and the closing brace. Minor. (line 27-28)

### `Foundation/UserDefaultsBackedDictionary.swift`
- **[Concurrency]** `UserDefaultsBackedDictionary` is a struct holding `UserDefaults` (class) and a closure (`@escaping (Key) -> String`). The closure should be `@Sendable` for Sendable conformance under strict concurrency. Type isn't marked `Sendable`. (line 39, 41)
- **[Bug]** `defaults.value(forKey:) as? Value` for `Value == URL` won't work — `UserDefaults` stores URL via `set(_:forKey:)` as bookmark/path under the hood; `value(forKey:)` returns `Data` or `String`, not `URL`. Use `defaults.url(forKey:)`. (line 52)
- **[API]** `UserDefaultStorable` is a marker protocol with no requirements — any type can be `extension X: UserDefaultStorable {}` and crash at runtime when stored. Type-safety theater. (line 10)

### `Foundation/try.swift`
- **[API]** Uses `logg("\(error)")` — relies on global `logg` defined elsewhere. OK if convention.
- No issues.

## Types

### `Types/AsyncBlocker.swift`
- **[Bug]** In both `ThrowingAsyncBlocker.update()` and `AsyncBlocker.update()`, the `defer` block resets `continuations = []` before resuming. Since the for-loop runs *before* the defer, this is fine for resumption, but the `defer` ordering is subtle: `defer { isUpdating = false; continuations = [] }` runs after the loop. Correct as-is, but fragile — a future edit moving the resume into a separate Task could leak.
- **[Bug]** Race window in coalescing: a caller arriving between `isUpdating = false` (in defer) and the *next* call to `update()` will start a fresh action — that's intended. But a caller that arrives after the action returns but BEFORE the defer runs (impossible inside an actor — fine on reflection). No bug, but worth noting the assumption.
- **[Bug]** Continuations appended *after* the action completes but *before* the defer clears them will never resume. Inside an actor with non-reentrant calls this can't happen between the loop and the defer, but the action's `await` points permit reentry. Specifically: if `action` itself awaits and another `update()` re-enters during that await, the new caller sees `isUpdating == true` and appends a continuation. When the original action returns and the loop resumes everyone, the new caller is correctly resumed too — so no leak. OK on closer read, but worth a comment to document the invariant.
- **[Suggestion]** The `action` closure should be `@Sendable` since it's stored across actor boundaries.

### `Types/ChangeTracker.swift`
- **[Memory]** `tokens` dictionary entries are never reaped except in `didChange(id:)` when the token is found nil. If `didChange` is never called for a particular ID after its observer goes away, the `WeakToken` entry stays in the dictionary forever. With many short-lived IDs this grows unbounded.
- **[Bug]** In `OnTrackedChangeModifier`, `task?.cancel()` is on `onDisappear` but the previous task is *also* cancelled in `onChange(of: token?.version)` — fine. However, on first appear, `token` is set in `onAppear`, which sets `token?.version` from `nil` to `0` — this triggers `onChange` and fires `callback()` immediately on appearance. That may or may not be desired; if not, it's a bug.
- **[Suggestion]** `let _ = token?.version` in `ObserveIDModifier.body` is a clever way to subscribe to Observation, but a comment explaining why is warranted.

### `Types/CrashPad.swift`
- **[Concurrency]** `Task { ... UserDefaults.standard.set(false, ...) }` is detached and uncancellable. If the app crashes during the sleep window, the `true` value persists — that's the intended behavior. OK.
- **[Bug]** `launchedSafely` performs side effects (`set`, `Task`) on every call. Calling it twice flips state. The doc says "should be called just before restoring state" — assumes single-call. A guard against repeated calls would be safer.
- **[Concurrency]** `Task.sleep(nanoseconds:)` is deprecated in favor of `Task.sleep(for:)` on iOS 16+; minor.

### `Types/DefaultsBasedPreferences.swift`
- **[Concurrency]** Heavy use of KVO + Mirror reflection + UserDefaults from `observeValue` callback (called on arbitrary threads). No synchronization — `defaults.set(...)` is thread-safe but `Notification.postOnMainThread` mitigates only the notify side. No `Sendable` conformance possible.
- **[Bug]** In `load()`, `addObserver` is added every time `load()` is called (init + `willEnterForeground` + `refresh()`). Each call re-adds observers without removing existing ones, leading to multiple-fire on KVO and crashes when `removeObserver` runs only once in `deinit`.
- **[Convention]** 121 lines — slightly over the ~100 guideline.
- **[API]** Mirror-based reflection for KVO is fragile; the macro-based `@AppSettings` approach is recommended in `CLAUDE.md` and supersedes this. Consider deprecating.
- **[Suggestion]** `saveTimer` property is declared but never used.

### `Types/DeviceFilter.swift`
- **[Concurrency]** All static let constants on `DeviceFilter` are inside a `@MainActor` extension — including `never`, `sim`, `device`, etc. These are pure value constants that don't need MainActor isolation. This forces all callers to MainActor. Move them out, leaving only `matches` MainActor-isolated (since it reads `Gestalt` MainActor state).
- **[Bug]** `matches` for `.iOS` returns false on Mac Catalyst because `isOnIPad`/`isOnIPhone` are likely false — but a Catalyst app *is* iOS-derived. Verify intent.
- **[Bug]** `.sim` check uses `Gestalt.isOnMac` as a proxy ("Mac is sim-equivalent"?) — that conflates running on Mac with running on simulator. Likely a bug.

### `Types/Gestalt+Background.swift`
- **[Platform]** `application?` is a fileprivate `@MainActor` UIApplication holder. The else-branch (non-iOS) provides empty stubs; this is fine for cross-platform compilation. OK.
- **[Suggestion]** `logger` uses `@available(iOS 14.0, ...)`, but the surrounding extension already targets iOS — the availability annotation on a top-level fileprivate is unusual but harmless.

### `Types/Gestalt+DeviceType.swift`
- **[Convention]** 169 lines with a long device map; data-heavy file but acceptable.
- **[Bug]** Device map is significantly out of date: missing iPhone 15, 16, all M-series iPads, recent Apple Watches (Series 8/9/10, Ultra), Apple TV 4K 3rd gen, etc. As of 2026 this is quite stale.
- **[Bug]** Typo: "iPhone Xs max" (line 63) and "iPhone 11 Pro max" (line 67) should be "Max".
- **[Bug]** Typo: "iPad air 4th gen" (line 107) should be "iPad Air 4th gen".
- **[Bug]** "RealityDevice14,1" → "Apple Vision Pro" — that mapping is correct but `os(visionOS)` isn't included in the file's `#if os(iOS) || os(watchOS) || os(visionOS)` rawDeviceType reading on the file scope — it is, OK.
- **[Concurrency]** `static let modelName`, `rawDeviceType`, `simulatedRawDeviceType` are global statics on a `Sendable` struct — they capture `ProcessInfo` and `utsname` at first access. Should be safe.

### `Types/Gestalt+watchOS.swift`
- **[Bug]** `WatchCaseSize` extraction strips trailing "m" but the model strings used are like "Apple Watch Series 7 41mm" → split by space → last is "41mm" → trim "m" → "41" — works. But "larger = 100" sentinel is suspect; if a new size lands (e.g. 50mm), it returns `.larger` silently.
- **[Bug]** No entry for Apple Watch Ultra (49mm is there) or Apple Watch Series 8/9/10. Stale data.
- **[Concurrency]** `WKInterfaceDevice.current()` access in a `static let` initializer is MainActor-isolated in newer SDKs; the `caseSize` is `static let` (not @MainActor), which may now warn under strict concurrency.

### `Types/Gestalt.swift`
- **[Concurrency]** `@MainActor public static var debugLevel` — initialized from `Gestalt.isAttachedToDebugger` which is fine. But it's a mutable static; with `@MainActor` isolation that's OK.
- **[Bug]** `isAttachedToDebugger` uses `isatty(STDERR_FILENO) != 0` — this detects whether stderr is a TTY, which is true for Xcode console attachment but ALSO true in many CI environments and when stderr is redirected to a TTY in production. This is a poor proxy for "debugger attached." A `sysctl`-based `kp_proc.p_flag & P_TRACED` check is the canonical approach.
- **[Bug]** `distribution` on macOS returns `.development` if no `_MASReceipt` — but a TestFlight macOS build uses sandbox receipts under different paths; this misclassifies macOS TestFlight as development.
- **[Concurrency]** `Gestalt.distribution` reads `isOnSimulator` then checks `Bundle.main.appStoreReceiptURL` — fine, all immutable.
- **[Bug]** `serialNumber` uses `kIOMasterPortDefault` (deprecated since macOS 12 in favor of `kIOMainPortDefault`). Same issue in `rawDeviceType` for macOS.
- **[Bug]** `rawDeviceType` on macOS: `IORegistryEntryCreateCFProperty(...).takeUnretainedValue()` — should be `takeRetainedValue()` since `IORegistryEntryCreateCFProperty` returns a +1 retained CFTypeRef per Create rule. This is a leak. Compare with `serialNumber` below which correctly uses `takeRetainedValue()`.
- **[Bug]** `IOServiceGetMatchingService` returns an `io_service_t` that must be released via `IOObjectRelease(service)` after use. Both `serialNumber` and `rawDeviceType` leak the service handle.
- **[Concurrency]** `nonisolated public static var deviceID` is async and reads `UIDevice.current.identifierForVendor` with `await` — but `UIDevice.current` access is MainActor-isolated; the `await` should hop properly. OK in practice but worth verifying with strict concurrency.
- **[Bug]** `deviceName` on macOS is `rawDeviceType` (the model identifier like "MacBookPro18,1") — that's NOT a name, it's a model string. Misleading API.
- **[Convention]** 224 lines — significantly over guideline; logical split between platform variants would help.
- **[Bug]** `getSimulatorHostInfo` does field-arithmetic on `utsname` assuming each field is `structSize / fieldCount` bytes — that's an implementation detail of `utsname` (typically 256 bytes per field on Darwin, but not guaranteed). Fragile.
- **[Suggestion]** Multiple `static let isOnX = false` definitions split across `#if` blocks invite bugs when adding a new platform — consider consolidating with a single computed value.

### `Types/IdentifiableEnum.swift`
- **[Bug]** `id` for an enum case with associated values returns just the case name (not including associated values). Two enum values like `.foo(1)` and `.foo(2)` share the same `id` — violates `Identifiable` semantics. The doc/name suggests this is for enums, but with associated-value enums this breaks ForEach uniqueness.
- **[Suggestion]** Should be documented as "for enums *without* associated values" or use a hash that includes the full description.

### `Types/IntSize.swift`
- **[Bug]** `IntPoint.magnitude` returns `x * y` — that's not magnitude (which would be `sqrt(x*x + y*y)` or at least area). Misleading name.
- **[Bug]** `IntSize(screenW w:_:)` swaps to ensure `width <= height`. Internal-only init so OK, but the doc/name unclear.

### `Types/Keychain.swift`
- **[Concurrency]** Heavy `Combine` usage: `CurrentValueSubject` for `lastResultCodeSubject`, `accessGroupSubject`, etc. Project guidance says "use async/await, not combine, GCD or queues". Consider migrating to `AsyncStream` or `Observable`.
- **[Concurrency]** All static state (`accessGroup`, `keyPrefix`, `synchronizable`, `lastResultCode`) is mutable and read/written without locking; the underlying CurrentValueSubject is thread-safe but the get/set semantics on the static var aren't atomic across compound reads.
- **[Bug]** In `set(_ value: Data?, ...)`: when `value == nil`, calls `delete(key)` and returns `false`. Returning false for a successful nil-deletion is misleading — a caller doing `if Keychain.set(nil, forKey: key)` will get false even though the operation succeeded.
- **[Bug]** `AccessOptions.accessibleAlwaysThisDeviceOnly` returns `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (line 396) — that's a clear copy-paste bug. The "always" semantic is replaced silently with "after first unlock".
- **[Concurrency]** Static `lastQueryParameters` and `lastResultCodeSubject` are not `Sendable`; this enum cannot be used safely from concurrent contexts.

### `Types/KeychainBasePreferences.swift`
- **[Bug]** Same KVO double-add issue as `DefaultsBasedPreferences` if `refresh()` is called after init.
- **[Bug]** `setValue(value, forKey: label)` on KVO change can re-fire `observeValue`, potentially recursing if the observer doesn't recognize the no-op.
- **[Bug]** `observeValue` ignores `Bool`, `Int`, `Double` types — only stores `String` and `Data`. If a subclass has `@objc dynamic var count: Int`, changes are silently dropped on the keychain side.
- **[Concurrency]** Same lack of thread-safety as `DefaultsBasedPreferences`.

### `Types/LoadingState.swift`
- **[Bug]** Custom `==` ignores associated values: `.failed(errorA) == .failed(errorB)` returns true regardless of error identity. Likely intended for state-equality, but it's surprising. Also `.loaded(a) == .loaded(b)` falls into `default` which returns false — so `.loaded` cases are *never* equal to each other, which is also surprising.
- **[Bug]** `Equatable` is not declared on the enum (just an `==` operator). Cannot be used in generic Equatable contexts.
- **[API]** `isLoaded` returns true for both `.loaded` and `.empty` — that's a design choice (data is "ready"), but the name is misleading; consider `isReady` or `hasResolved`.

### `Types/MobileProvisionFile.swift`
- **[Convention]** Entire file is commented out (deprecated). Either remove the file or leave a stub. Currently it consumes a slot but has no compiled code.

### `Types/NetworkInterface.swift`
- **[Concurrency]** `static var allInterfaces` is a computed property doing C calls each time — not `static let`. That's correct (interfaces change), but it's not Sendable-safe across threads (although `getifaddrs` is reentrant per man page). Consider documenting.
- **[Bug]** `String(NSString(cString: hostname, encoding: NSUTF8StringEncoding) ?? "")` is a roundabout conversion and depends on Foundation. The simpler `String(cString: hostname)` (commented out) is safer for null-terminated strings.
- **[Bug]** `addrFamily` filters in callers compare `UInt8(family)` to a `sa_family_t` (`UInt8` on Darwin) — OK on Darwin but fragile if ported.
- **[Suggestion]** No filtering of loopback or link-local — caller sees `lo0`, etc.

### `Types/OnDemandFetcher.swift`
- **[Bug]** `request.endAccessingResources()` is called only on success; if `JSONDecoder` throws, the resources are never released. Use `defer`.
- **[Bug]** Caches the dictionary in Keychain — peculiar choice (Keychain isn't designed for bulk cache data and survives app uninstalls). UserDefaults or Caches dir would be more appropriate.
- **[Suggestion]** Hardcoded `loadingPriority = 1` is the maximum — ensure that's intended.

### `Types/Point.swift`
- **[API]** Just `Equatable` — no `Hashable`, `Codable`, or `Sendable` despite being trivially conformable. Compare with `IntPoint` in `IntSize.swift` which is a duplicate. Two structs serving the same purpose; consolidate.
- **[Convention]** Custom `==` is unnecessary; default synthesized `Equatable` would suffice.

### `Types/RawCodable.swift`
- **[Bug]** `RawCodable` requires `Identifiable` and conforms `id = rawValue`. But if `RawValue` is `String`, two enum cases with the same rawValue (impossible by definition) — fine. But forcing Identifiable is restrictive; some users may want their own `id`.
- **[Suggestion]** `RawCodableError` is internal but the protocol is public — decoding errors thrown to the caller will be opaque.

### `Types/RawCollection.swift`
- **[Bug]** **Subscript setter is inverted**: when `newValue == true`, it calls `elements.remove(item)`; when false it calls `elements.insert(item)`. Setting `collection[item] = true` REMOVES the item. This is a serious copy-paste bug.
- **[API]** No `Codable`, `Sendable`, `Equatable`, `Hashable` despite obviously needing them.

### `Types/SFSymbol.swift`
- **[Convention]** 1804 lines — vastly exceeds guideline. Auto-generated data dictionary, but Apple now provides `Image(systemName:)` with broad coverage and Apple's own SF Symbols framework. Recommend deprecating or splitting by category file.
- **[Bug]** Many entries marked "Usage restricted to ..." (Apple App Store rules) are exposed as public cases — App Store reviewers may reject apps that ship these symbols outside the allowed contexts.
- **[Perf]** Compiling this file is slow (1804 cases). Consider moving to a generated resource bundle.

### `Types/SharedDependencyManager.swift`
- **[Concurrency]** Manual `os_unfair_lock` via `UnsafeMutablePointer` — this is correct but verbose. Modern Swift offers `OSAllocatedUnfairLock` (iOS 16+). Recommend migrating once min target allows.
- **[Bug]** In `register`, `case .default: if replace == .default { fatalError(...) }` — the outer `case .default` already implies `replace == .default`, so the inner check is redundant. The logic is correct but reads as a typo.
- **[Bug]** `ReplacementRule.single` policy: "current.isDefault → allow replace; not default → fatalError". So registering twice as `.single` crashes — that's harsh for a framework-level singleton; consider returning a Bool or throwing.
- **[Concurrency]** `SharedDependency` property wrapper resolves on every access (no caching); each access takes the lock. For hot paths this is contention.
- **[Memory]** `dependencies: [String: Any]` keyed by `String(describing: T.self)` — a generic struct used with two type parameters distinguishes properly, but `String(describing:)` on generic types can produce ambiguous keys for nested types. Consider `ObjectIdentifier` for class types or `_typeName` for stable keys.
- **[API]** `@unchecked Sendable` is justified given the lock, but a comment to that effect would help.

### `Types/SoundEffect.swift`
- **[Concurrency]** Uses `Timer.scheduledTimer(...)` and `MainActor.run(after:)` for delayed work — project policy says async/await preferred. Replace with `Task.sleep(for:)`.
- **[Memory]** `cachedSounds` and `playingSounds` are static unbounded dictionaries/arrays. No eviction; long-running app leaks memory.
- **[Bug]** `pause()` sets `isPlaying = true` (line 232) — should be `false`. Clear bug.
- **[Bug]** `init(named:)`: when fallback `data: nil` is passed at line 136, `self.init(data: nil, ...)` is called but `data: Data?` init returns nil for nil data — yet the outer `convenience init?` calls it then `return nil`. The earlier branches at line 128 set `cachedSounds[name] = self` *after* `self.init(url:)` — but `self` may be nil at that point if `init(url:)` returned nil. Cannot reference `self` in failable init after a failable delegate that returned nil, so... the code actually compiles because `init(url:)` is currently non-failable in code (despite `init?` annotation) — actually it IS `init?(url:)` (line 73) but never returns nil. The `self.init(url:)` call would terminate the init if it failed. Confusing but works.
- **[Bug]** `if !preload` branches for `data:` initializer don't add to `cachedSounds` — inconsistent with `url:` initializer which does cache.
- **[Convention]** 239 lines — over guideline.
- **[Concurrency]** `nonisolated public static func ==` reads `===` — fine since identity comparison doesn't touch isolated state.
- **[Suggestion]** `disableAllSounds = Gestalt.isOnSimulator` makes simulator silent by default — surprising for new users; should be opt-in.

### `Types/Titleable.swift`
- No issues.

### `Types/VersionString.swift`
- **[Bug]** Custom `==` semantics: `"1.2" == "1.2.0"` is true (good), but `"1.2.0.0.0.5" == "1.2"` would compare prefix [1,2] vs [1,2], then check the suffix `[0,0,0,5]` — `allSatisfy { $0 == 0 }` is false → returns false. But `<` would correctly say `1.2 < 1.2.0.0.0.5`. So `==` returns false and `<` returns true and `>` (synthesized) returns false: total ordering holds. OK.
- **[Bug]** In `==`, the suffix check uses `lhComponents.suffix(from: lhComponents.count - minCount)` — that's wrong. If `lhComponents.count == 5` and `minCount == 2`, it suffixes from index 3, returning the LAST 2 elements, not the trailing-after-minCount elements. Should be `suffix(from: minCount)`. **This is a real bug**: `"1.2.3.0" == "1.2"` would return true (since the wrong-suffix-from-2 = `[3, 0]` — wait let me recompute: count=4, minCount=2, `count - minCount = 2`, so suffix from index 2 = `[3, 0]`, allSatisfy zero = false → returns false). Hmm, actually it works out by coincidence because `count - minCount == minCount` when `count == 2*minCount`. With `count=5, minCount=2`: suffix from 3 = last 2 elements; missing index 2. **Bug confirmed**: `"1.2.0.5.0" == "1.2"` would skip checking index 2 (the value 0) and check `[5, 0]` → false → returns false (which is correct here by luck), but `"1.2.5.0.0" == "1.2"` skips index 2 (5) and checks `[0,0]` → all zero → returns TRUE incorrectly.
- **[API]** `Sendable`/`Hashable`/`Codable` not conformed despite trivially possible.
- **[API]** Init takes `String` but provides no validation; non-numeric components are silently filtered by `compactMap`.
- **[API]** No `init(from decoder:)` — cannot round-trip serialize.

---

**Note**: The review prompt mentioned `UserDefaultsContainer`, `ObservableValue`, and `NonIsolatedWrapper` as "key types in this directory", but those files do not live in `Sources/Suite/Types/` — they're in `Sources/Suite/Property Wrappers/` and elsewhere. Reviewed only the actual contents of `Types/`.

## Utilities

### `Utilities/AsyncWebView.swift`
- **[Concurrency]** `setup()` is dispatched in a `Task` from `init()`, so `webView` is `nil` until that task runs. A caller invoking `load(...)` immediately after `init` will hit a force-unwrap crash on `self.webView!` (line 13/34). Either run `setup()` synchronously inside `init` (the class is already `@MainActor`) or make `webView` a private optional and guard.
- **[Concurrency]** `MainActor.run { _ = self.webView.load(request) }` (line 34) is the non-async overload from `MainActor.swift`, fire-and-forget. Since the enclosing function is on `MainActor`, just call `webView.load(request)` directly.
- **[Bug]** `continuation` is non-optional-ified by being set right before `webView.load`, but `setup()` runs asynchronously — if a navigation completes before `setup()` resolves the actor hop, `continuation` is set then `load(request)` is called on a possibly-nil `webView`. (line 13)
- **[API]** Class is force-unwrapped optional (`WKWebView!`) but exposed as `public` — callers can read it before `setup()` finishes. Prefer constructor injection.

### `Utilities/BlockWrapper.swift`
- **[API]** Equality is based purely on source location (file/line/column). Two distinct instances created at the same call site would be considered equal — surprising semantics; document or rename.
- No other issues.

### `Utilities/CommunalFetcher.swift`
- **[Concurrency]** Uses Combine (`CurrentValueSubject` + `sink`) inside an actor; CLAUDE.md says to use async/await, not Combine. This whole class would be cleaner with a single in-flight `Task` that suspended waiters await.
- **[Bug]** When `inProgress` is true and a waiter sinks, the `receiveValue` handler resumes the continuation when a non-nil `value` arrives — but `value.value = value` runs on the actor before `cancellables = []`, so multiple sinks may all fire and resume each waiter exactly once. However, if `clear()` is called externally between the start and end of a fetch, value goes nil and the sink ignores it; but a subsequent `fetcher` failure publishes `.failure` which terminates the subject permanently — subsequent fetches will never be able to publish on the same subject. The subject is created once at init; after `value.send(completion: .failure(...))` the subject can no longer deliver values. (line 51)
- **[Concurrency]** `cancellables` membership and the subject are mutated from inside an actor but the sink closures may execute on Combine's scheduler, capturing `self`. Strong reference plus capturing `&cancellables` from outside the actor isolation context is risky; storing into a Sendable `Set` from a non-isolated closure is technically a violation under strict concurrency.
- **[Memory]** On success, `value.value = value` keeps the cached value alive forever; only `clear()` resets it. Document.

### `Utilities/DeSync.swift`
- **[Convention]** Large commented-out block (lines 28-64). Per "surgical changes", remove dead commented code or move to history.
- **[Bug]** `asynchronize()` (lines 65-92): `hasContinued` is captured by the sink closures — Combine sinks may run concurrently from a non-Sendable Combine scheduler. The variable is also a `var` captured by reference from a `withCheckedThrowingContinuation` closure, which produces a non-Sendable closure-capturing-mutable-state warning under strict concurrency. Race possible if upstream emits value+failure quickly. Also, `cancellable: AnyCancellable!` force-implicit-unwrap is used before being assigned in `receiveValue` is fine, but the IUO is unnecessary.
- **[Concurrency]** Whole file pivots between Combine and async; consider rewriting in pure async.

### `Utilities/Identifiable.swift`
- **[API]** The `subscript(id:)` setter that *appends* when no element exists with that id is surprising (`array[id: x] = y` mutates more than the named slot). Document or split into two methods.
- **[API]** Extending `Int`, `Double`, `Float`, `String` with `Identifiable` retroactively is fragile — duplicate values collide and `ForEach`/diffing will break. Add a doc warning or scope to a wrapper.
- **[Platform]** Whole file gated on `canImport(Combine)` — but it has no Combine dependency. The gate appears wrong; the only SwiftUI usage is the import. Remove the gate or import only Foundation.

### `Utilities/JSON/CodableJSONArray.swift`
- **[Bug]** `init?(_ json: [String: Sendable]?)` (line 44) takes a *dictionary* but constructs an array — almost certainly a copy-paste error from `CodableJSONDictionary`. Looks like a leftover stub that does nothing useful and should be `[Sendable]?` or removed.
- **[Bug]** `hash(into:)` mixes index in regardless of value, so `[1, 2]` and `[2, 1]` hash differently from each other, but two equal arrays of `Sendable` values do hash the same — fine. However, values not `Hashable` are silently skipped; `Equatable` allows them via `compareTwoJSONValues`, so two equal arrays with non-`Hashable` payload still hash identically (good), but a non-Hashable value mismatch can yield equal hash with unequal `==` — which is acceptable, but worth documenting.
- **[API]** `array: [Sendable]` getter exposes a Swift existential array; consumers can downcast freely. Fine, but consider exposing typed accessors.
- **[Convention]** The `subscript` setter does no JSON-validity check (unlike the Dictionary variant) — inconsistent.

### `Utilities/JSON/CodableJSONDictionary.swift`
- **[Concurrency]** `nonisolated(unsafe) public static var dataKeyNames: [String] = []` (line 16) is mutable global shared state with no synchronization. Multiple threads writing/reading is a data race. Consider an actor or a lock-protected wrapper.
- **[Bug]** `JSONCodingKey.intValue` returns `0` when both `int` and `string` are nil-coercible — `Int(string ?? "0") ?? 0`. The fallback returns 0 silently, masking malformed keys (line 79). Should be a real Optional.
- **[API]** `JSONCodingKey` initializers `init?(stringValue:)` always succeed (never returns nil) — should not be failable, or the failable form is a lie.
- **[Bug]** `hash(into:)` iterates `dictionary` (line 30) which is unordered → different runs produce different hash sequences for the same dict because `combine` is order-sensitive. This violates the `Hashable` contract that equal values produce equal hashes. Sort keys before hashing.
- **[API]** `dataKeyNames` static side channel for telling the decoder "this string is base64" is leaky — it's set globally and influences all decode operations.

### `Utilities/JSON/JSON Types.swift`
- **[API]** `JSONDictionary = [String: JSONRequirements]` — `JSONRequirements` is just `Sendable`, so this typealias does not actually constrain values to JSON. It's effectively `[String: any Sendable]`. Misleading name.
- No other issues.

### `Utilities/JSON/JSON+Codable.swift`
- **[Convention]** File is 191 lines — over the ~100 line guideline; could be split.
- **[Bug]** Decode order tries `Int` before `Float`/`Double` (line 27): `1.0` will decode as `Int` (1), losing the float-ness, since `JSONDecoder` happily decodes `1.0` as `Int`. For round-tripping, prefer `Double` first or sniff numeric forms.
- **[Bug]** `Bool` is never tried in either decode-helper (lines 27-49 and 51-77) — booleans will round-trip as `Int(0/1)`. Versus `JSONDecoder+JSONDictionary.swift` which does try `Bool`. Inconsistent.
- **[Bug]** `EncodedDate(date:)` and `EncodedData(data:)` use synthesized `Codable`. `Date` encodes per the encoder's `dateEncodingStrategy` — but the helper expects a single keyed shape `{date: ...}`. Round-trip works only because both ends use the synthesized container. However, decoding then `decode(EncodedDate.self)` will succeed for *any* dictionary that happens to have a `date` key — false-positive routing.
- **[Perf]** `try?` chains repeatedly catch and discard — for large JSON this is slow. Use `singleValueContainer` type sniffing.
- **[Bug]** Encode arm encodes nested arrays via `EncodedArray` wrapper (object form `{array: [...]}`), but `decode([Any].self, ...)` reads from an *unkeyed* container directly — these two paths are not symmetric. Round-tripping `[Any]` containing nested `[Any]` will decode the nested array as a dictionary or fail. (lines 105-107 vs 51-77)
- **[Convention]** `IntCodingKey` is unused.
- **[Bug]** When encoding `[Any?]`, `nil` values are skipped silently in `encode(_:[String:Any?]:forKey:)` (lines 92-107). But the public API entry `decode([String:Any].self, ...)` strips nils; round-trip OK for dictionaries but loses nullable info.

### `Utilities/JSON/JSON+Equatable.swift`
- **[Bug]** `compareTwoJSONValues` checks `Bool` first, but Swift may bridge `Bool` via `NSNumber` so an `Int(1)` coming from JSON could match against `Bool(true)`. The order is OK if values are pure Swift, but Foundation-bridged values cause false equality. Test with `JSONSerialization` outputs.
- **[Bug]** `integer(from:)` floors floats with equality `== floor(double)` — `2.0 == 2` returns true, conflating Int and Double. May or may not be desired (file calls itself a JSON comparator where this is generally tolerated), but document.
- **[Perf]** `sortedKeys` allocates new arrays on every comparison; for deep dicts this multiplies. Use `Set` comparison or count + key-by-key check.

### `Utilities/JSON/JSON+PrettyPrinted.swift`
- **[Bug]** Strings are printed without quoting/escaping (line 41), so a value containing `,`, `\n`, or `:` produces invalid output. Not real JSON.
- **[Bug]** `Bool` is never handled; falls through to nothing (no else clause), producing an empty value after `key: ` for boolean entries. Same for `nil`.
- **[Bug]** Dependency on `Date.localTimeString()` for output is locale-/timezone-dependent — non-stable representation.
- **[API]** Method is named `prettyPrintedJSON` but does not produce JSON — only a debug-friendly representation. Rename to `prettyPrinted` or similar.
- **[Perf]** String concatenation in tight loops over big collections — use a single `String(reserveCapacity:)` or array-join.

### `Utilities/JSON/JSONDecoder+JSONDictionary.swift`
- **[Bug]** Order matters for numeric decoding — `decode(Double.self)` happens before `decode(Int.self)` (line 31), so any integer in source JSON becomes a `Double` in output. The unkeyed sibling reverses the order (Int before Double). Pick one, document, and be consistent.
- **[Bug]** `date(from double:)` and `date(from int:)` always return `nil` (lines 110-117), so `secondsSince1970`/`millisecondsSince1970` strategies never work for numeric date fields when going through the keyed path. Fix the implementation.
- **[Bug]** Catch-all discards thrown errors as "null"; this also silently swallows malformed JSON. (lines 17-19)
- **[Concurrency]** Reading `CodableJSONDictionary.dataKeyNames` (line 27) is racy with the global `nonisolated(unsafe)` mutable state.

### `Utilities/JSON/JSONEncoder+JSONDictionary.swift`
- **[Bug]** `.custom` date strategy is not implemented (line 54 / 103); just logs an error and silently writes nothing for the field. This will produce incomplete encoded output without throwing.
- **[Bug]** `Bool` ordering: `Bool` is checked first (line 20) — good, prevents `true` becoming `1`. But `value as? Int` (line 22) on an `NSNumber` bridge will match for booleans bridged through Foundation; here Bool comes first so OK.
- **[Bug]** `jsonValue(from date:)` returns `nil` for `.custom` and `.deferredToDate`; consumers need to handle nil — flag, since other call sites might assume non-nil.
- **[Convention]** File is 173 lines; split.
- **[Bug]** Top-level `nestedUnkeyedContainer(forKey:)` writes nested arrays without forwarding `dateEncodingStrategy` (line 38-39), so dates inside nested arrays always use the default `.iso8601`.

### `Utilities/JSON/JSONDecoder.swift`
- **[Bug]** File header: "Created by Ben Gottlieb on 3/15/26." — future date typo; also `JSONEncoder.swift` says `6/11/25`. Cosmetic.
- No functional issues.

### `Utilities/JSON/JSONEncoder.swift`
- No issues.

### `Utilities/MainActor.swift`
- **[Concurrency]** `MainActor.run(after:)` (line 11) calls `await MainActor.run` inside a `Task` *after* an unstructured Task already runs — but the inner `await MainActor.run` returns immediately on hop, then the outer Task's body finishes. This is fine, but the `Task { ... }` wrapper escapes context — there's no way to cancel or await completion. Consider returning a `Task<Void, Never>`.
- **[Bug]** `withAnimationOnMain(...)` (line 33) when called off-main fires-and-forgets via `MainActor.run { ... }` (the Task-spawning helper above), so the caller cannot synchronize with completion. Names suggest synchrony.
- **[Bug]** `Thread.isMainThread` check (line 26, 34) is *not* equivalent to "on MainActor" — a non-MainActor function might be running on the main thread without main actor isolation, leading to a strict-concurrency violation when calling main-actor APIs. Use `MainActor.assumeIsolated` (with caveats) or always hop.
- **[Convention]** File is named `MainActor.swift` but the header says `Animation.swift` — stale.
- **[Concurrency]** Modern frameworks should avoid blocking on `Thread.isMainThread`; per CLAUDE.md prefer async/await throughout.

### `Utilities/ObservableValue.swift`
- **[Concurrency]** Uses Combine; per CLAUDE.md prefer async/await. Not a bug per se but at odds with the convention. `assign(to:on:)` retains `self`, and the cancellable is owned by `self`, but `assign` captures `self` strongly inside the publisher graph — fine for class lifetime.
- **[API]** No way to update from outside — usable only as a read-only bridge. Document.

### `Utilities/Reachability.swift`
- **[Concurrency]** `pathMonitor.pathUpdateHandler` (line 41) runs on `queue` (default `.main`), captures `self`, and calls `objectWillChange.sendOnMain()` plus a `Task { @MainActor ... }`. Since `Reachability` is `@MainActor`, calls into `self.callCameOnlineCallbacks()` and `self.isOffline` from the closure are non-isolated — likely a strict-concurrency error / data race on `wasOffline` and `cameOnlineCallbacks`. The closure is also non-Sendable but uses self.
- **[Concurrency]** Stores `queue: DispatchQueue` (line 9) and uses GCD; CLAUDE.md says no GCD.
- **[Bug]** `setupAndCheckForOnline()` (line 27): if `isStartingUp` is false OR `startupContinuation != nil`, returns early. The "OR" is wrong — if the previous call already installed a continuation (`startupContinuation != nil`), the second caller returns immediately with the current state, never awaiting. Should likely allow multiple awaiters via a continuation list.
- **[Bug]** `start()` resumes `startupContinuation` (line 54) but does so unconditionally; the path monitor may not yet have produced any state. The 250ms sleep is a magic number; switch to await first `pathUpdateHandler` callback.
- **[Bug]** `whenOnline(_:)` callbacks accumulate forever; no removal API. (line 35) Memory leak risk.
- **[API]** `connection` returns `.other` while `isStartingUp` is true; `isOffline` then returns false. Misleading during startup.
- **[Convention]** Hard-coded sleep of `250_000_000` ns (line 52).

### `Utilities/SeededRandomNumberGenerator.swift`
- **[Concurrency]** Uses `DispatchSerialQueue.global()` and `queue.sync` for thread-safety (lines 18-49). CLAUDE.md says no GCD. Convert to an actor.
- **[Bug]** `nonisolated(unsafe) private static var sharedGenerator` mutated across threads — synchronized via `queue.sync`, but the access in `anyRNG` getter is *not* serialized against external setters in the get path of `with(_:)` since the getter is called inside `queue.sync`, OK — but the public `static func next()` calls `sharedGenerator.next()` which mutates `mersenne`'s internal state; `GKMersenneTwisterRandomSource` is not thread-safe (you marked it `@unchecked Sendable` retroactively).
- **[Bug]** `seed: Int = Int(Date().timeIntervalSinceReferenceDate)` truncates to Int and loses sub-second resolution; multiple instances created within the same second share a seed. Use `UInt64.random(in:)` or `mach_absolute_time`.
- **[Bug]** `print("Seeding a zero generator")` (lines 59, 64) — unconditional print in production. Use logger or remove.
- **[API]** `anyRNG` setter only accepts `SeededRandomNumberGenerator`; passing any other RNG silently no-ops.
- **[Platform]** Excluded from watchOS — fine since GameKit is unavailable.

### `Utilities/String+Crypto.swift`
- No issues.

### `Utilities/URLSession.swift`
- **[API]** Reimplements `URLSession.data(for:)` async API which is built into iOS 15/macOS 12. Once the package's iOS 13 floor is raised, delete. Currently shadows the system version on iOS 15+ — confusing.
- **[Bug]** Continuation-based wrapper does not propagate cancellation — `Task.cancel()` won't cancel the underlying `URLSessionDataTask`.

### `Utilities/Views/FlowedHStack.swift`
- **[Convention]** File is 217 lines; split legacy fallback into its own file.
- **[SwiftUI]** Legacy `legacyBody` is a view-returning computed property (line 134). CLAUDE.md says to avoid view-returning properties — extract a subview type.
- **[Bug]** `indexOf(size:x:y:rows:bounds:)` (line 92) is O(n²) and matches by floating-point near-equality of position — fragile; if two cells share the same position (unlikely but possible after rounding) the wrong subview is placed. Use `subviews.indices` directly tracked.
- **[Perf]** `sizeThatFits` is recomputed in `placeSubviews` and `sizeThatFits` separately, not cached (no `cache:`).
- **[API]** `FlowedHStackImage` declares `id = UUID()` and conforms to `FlowedHStackImageElement` but the protocol is `Identifiable` only — and `FlowedHStackImageElement` is unused by `FlowedHStack` itself. Dead code.
- **[SwiftUI]** Uses `proxy.width` (line 138) — `GeometryProxy` does not have a `.width` property; only `.size.width`. Compile error unless there's an extension elsewhere — verify.
- **[Convention]** Hardcoded `-0.5` offset (line 33) and `(rowHeight - size.height) / 2` magic adjustments.

### `Utilities/Views/SimpleWebView+Additions.swift`
- **[Concurrency]** `nonisolated(unsafe) static var defaultValue: WebViewErrorCallback?` (line 13) is mutable static for an EnvironmentKey default. Should be `let` and likely `nil`.
- **[Platform]** Branches on `os(visionOS)` for `onChange(of:)` (lines 49-53); iOS 17 introduced the new signature — branch on availability, not OS. macOS 14 will hit the iOS branch incorrectly. (The iOS branch uses the deprecated form; on macOS 14 you might want the new one.)

### `Utilities/Views/SimpleWebView.swift`
- **[Bug]** Type name `EmbdeddedWebView` (typo: "Embdedded" should be "Embedded") — appears 5+ times. Cosmetic but public-ish.
- **[Bug]** `@State var webView: WKWebView = .init()` (line 20) — instantiating a WKWebView in a `@State` initializer means a new WKWebView is created during view construction every time, but `@State` will keep the first. However, since `WKWebView()` is `@MainActor` and `init` of struct may be called off-main, this is fragile under strict concurrency. Use `StateObject` with a wrapper or initialize lazily.
- **[Bug]** `Coordinator` retains `webView` while also being its `navigationDelegate`. The view's `@State webView` is the same instance — single owner OK, but if SwiftUI recreates the view, the coordinator may dangle.
- **[API]** `EmbdeddedWebView` ignores its `webView` property and instead uses `context.coordinator.webView` — passing two webviews invites desync. The constructor stores `webView` but never uses it after handing to coordinator.
- **[Bug]** `Coordinator` has no `@MainActor` annotation but `WKWebView`/`WKNavigationDelegate` calls are main-thread.

### `Utilities/Views/View+PDF.swift`
- **[Bug]** Filename built as `"\(self).pdf"` (line 15) — `self` is a SwiftUI view, whose `description` is implementation-defined and may contain characters illegal in filenames (`<`, `>`, etc.). Use a UUID or caller-provided name.
- **[Bug]** `guard let pdf = CGContext(...)` returns silently from the inner closure (line 23) — caller is told the URL is valid, but no PDF was written. The TODO comment confirms it should throw, but it can't from the renderer closure. Need to surface failure via captured error.
- **[Bug]** `URL.caches.appendingPathComponent(...)` may not exist; `URL` extensions may be defined elsewhere — verify.

### `Utilities/Views/WrappedView.swift`
- **[Platform]** No watchOS or tvOS branch — empty on those platforms; ensure callers gate accordingly.
- **[Memory]** Stores the `view` strongly in the SwiftUI struct; SwiftUI re-instantiates structs frequently — consumer-supplied UIView is retained per re-instantiation. OK if caller is careful.

### `Utilities/Views/WrappingHStack.swift`
- **[Bug]** `sizeThatFits` mutates `cache.lines` (line 56), but Layouts are expected to be deterministic given identical inputs and may be called with different proposals, polluting cache state used later by `placeSubviews`. Use a transient computation or key cache by proposal.
- **[Bug]** First-element overflow: when an element wider than `bounds.width` is the first in a line, `(0 + width) >= bounds.width` triggers a line break before adding any element — produces an empty line, then the wide element. (line 66) Should not break for the first element of a line.
- **[Bug]** `>= bounds.width` should be `>` (line 66) — equality fits exactly.
- **[Bug]** Trailing `horizontalSpacing` is added to every element including the last on a line, so `currentLine.width = offsetX` overcounts width by one trailing spacing. Subtract `horizontalSpacing` after building each line.
- **[Convention]** `cache.lines.append(currentLine)` (line 86) appends the final line even if empty when there are zero subviews — `calculateSize` will then have `lines.count == 1` instead of 0, returning a non-zero size for an empty layout.

### `Utilities/WKWebView.swift`
- No issues.

### `Utilities/WebConsole.swift`
- **[Concurrency]** `urlObservation = webView?.observe(\.url) { webView, change in Task { @MainActor in self.loadedURL = webView.url } }` (line 41) captures `self` strongly inside a KVO closure — leak risk if the observation outlives expected lifetime. Use `[weak self]`.
- **[Concurrency]** `webView?.removeObserver(self, forKeyPath: "url")` (line 34) is leftover from manual KVO and is not paired with `addObserver`. Calling `removeObserver` for a key path that wasn't manually added causes a runtime exception.
- **[Bug]** `setWebView` does not retain `originalNavigationDelegate` strongly (`weak`), so if the original delegate is owned only by the webview it may have already been released. Document.
- **[Memory]** `deinit` warns but cannot do cleanup (it's `nonisolated`); since the class is `@MainActor`, `deinit` cannot touch isolated state. The current code reads `self.webView` from `deinit` — that's a strict-concurrency violation.
- **[API]** `run(script:)` returns empty string on missing webView instead of throwing — surprising.
- **[Convention]** File 197 lines; many delegate forwards could move to a separate file.
- **[Bug]** `originalNavigationDelegate?.webView?(...)` selector forwarding via `responds(to:)` strings — string-based selector "webView:decidePolicyForNavigationAction:decisionHandler:" is fragile vs `#selector` (used elsewhere in same file).

### `Utilities/WebConsoleView.swift`
- **[Bug]** Non-localizable strings ("loaded", "Loaded", "No content", etc.) — note "loaded" vs "Loaded" capitalization mismatch between two cases (lines 34 and 38) suggests a copy-paste typo: the `.loading` case shows "Loaded" which is wrong.
- **[Convention]** Hardcoded font size 16 (line 55). Use `.body` or system font tokens.
- **[SwiftUI]** Several short text labels would benefit from `.monospaced()` etc; minor.

## SwiftUI / Component Views

### `SwiftUI/Component Views/AsyncButton.swift`
- **[Bug]** Line 55: `Button(title, systemImage:role:action:)` overload omits `.disabled(isPerformingAction)`, the preference key, and `onDisappear { cleanUp() }`, so the title+systemImage path silently behaves differently (no disable while running, no cancel on disappear, no preference reporting). The whole branch should funnel into a single modifier chain.
- **[Bug]** Line 145: `init(role:...)` overload (line 43) does NOT set `self.title` or `self.systemImage`, leaving them as default `nil` (OK), but the convenience init with `role:` at line 135 also fails to set `useDetachedTask` properly — wait, it does at line 140. However, the `init(role:...)` at line 43 never sets `title`/`systemImage` properties — fine since defaults are `nil`, but inconsistent: passing those was apparently intended but they're unreachable through that init.
- **[Bug]** Line 87/101: Logger `\(error, privacy: .public)` interpolation is an OSLog-style string format; `SuiteLogger.warning` likely takes a `String`, so `error` interpolated this way yields a literal `"... error privacy: .public ..."` text rather than working privacy redaction. Verify that `SuiteLogger.warning` actually accepts an `OSLogMessage` — if not, this is broken.
- **[Concurrency]** Line 82-94: `Task.detached` captures `taskWrapper`/`isPerformingAction` (SwiftUI bindings) and reads/writes them from a non-MainActor context outside the inner `MainActor.run`. The assignment `taskWrapper.wrappedValue = Task.detached { ... }` happens on MainActor; that's fine, but inside the detached task the closure body (lines 83-89) runs off-main and the `await action()` is `@MainActor` — should work, but `await MainActor.run { ... }` is preferred over manual hop.
- **[API]** Line 32: 7-parameter init with multiple optionals is awkward. Consider builder-style or fewer overloads.
- **[Style]** Line 110: `var buttonLabel: some View` is a view-returning computed property — violates the "avoid properties that return a view, prefer creating new subview types" convention.
- **[Style]** Line 181: `@ViewBuilder var spinner: some View` is also a view-returning property.
- **[Suggestion]** `role: Any?` (line 29) to dodge availability is a code smell; consider extracting role-handling into a helper or using a wrapper type.
- **[Convention]** File is 195 lines — substantially over the ~100-line guidance; split overload extensions and helper labels into separate files.

### `SwiftUI/Component Views/ErrorDisplayingView.swift`
- **[Bug]** Line 8: imports `Foundation` but uses SwiftUI types (`View`, `Text`). Builds only because `View` leaks via another import? Should `import SwiftUI`.

### `SwiftUI/Component Views/FixedSpacer.swift`
- **[Platform]** Line 11: `@available` is missing `tvOS`. Other files in the directory specify it; inconsistent.
- **[API]** `width`/`height` stored as optionals when the init forces exactly one — can simplify by storing axis + dimension or two distinct types.

### `SwiftUI/Component Views/FullScreenCoverLink.swift`
- **[Platform]** Line 27: `@available(iOS 14.0, watchOS 8.0, *)` claims watchOS support, but the type is wrapped in `#if os(iOS)` (line 26) — so the `watchOS` availability is unreachable/misleading.
- **[API]** Line 12-22: macOS `fullScreenCover` shim aliasing to `.sheet` shadows Apple's own `fullScreenCover` API on Catalyst-imported codebases. Naming-collision risk; consider a different name (`compatFullScreenCover`).
- **[Style]** Line 49: `extension FullScreenCoverLink where Label == Text` exposes `String` (not `LocalizedStringKey`) — inconsistent with `AsyncButton` which uses `LocalizedStringKey`.

### `SwiftUI/Component Views/HostingWindow.swift`
- **[Concurrency]** Line 20: `nonisolated(unsafe) static let defaultValue: WindowFetcher = { nil }` — `WindowFetcher` is a closure that's not `@Sendable`, and `EnvironmentKey.defaultValue` is now Sendable-required. Marking `unsafe` papers over the warning.
- **[Memory]** Line 27: setter `set { self[HostingWindowKey.self] = { [weak newValue] in newValue } }` is good (weak), but the env-value getter calls the fetcher on every read — fine, but worth documenting.
- **[Bug]** Line 32-56: `HostingWindow.init` uses hard-coded `width: 480, height: 300` with no parameter — violates "avoid hard-coded dimensions". Should be configurable.
- **[Platform]** File guards `#if canImport(AppKit) && canImport(SwiftUI) && !targetEnvironment(macCatalyst)` — typealias `WindowFetcher` (line 16) is declared at file scope without `@available`, so it's exported even when `EnvironmentKey` (line 19) requires macOS 10.15. Minor.

### `SwiftUI/Component Views/KeyboardSpacer.swift`
- **[Style]** Entire file is commented out. Either delete the file or extract a TODO; leaving 80 lines of dead code in the repo creates noise.

### `SwiftUI/Component Views/LabeledView.swift`
- **[Concurrency]** Line 11: `nonisolated(unsafe) public static var defaultValue = false` — `var` (mutable) static is racy. Should be `let`.
- **[Style]** Line 42: hard-coded font size `9` and padding `2` — violates "avoid hard-coded dimensions" (though for a debug overlay this is borderline acceptable).
- **[API]** `DebugLabeledView` is `internal`; `debugLabel` modifier on `View` is public — fine. `ShowViewLabelsEnvironmentKey` is exposed as `public` but the macro `@GeneratedEnvironmentKey` would do this cleanly per CLAUDE.md.

### `SwiftUI/Component Views/LoadingView.swift`
- **[Bug]** Line 46-58: `.task { state = .loading; ...; showError = true }`. After `state = .loaded(...)`, setting `showError = true` triggers a re-render but `showError` is unused anywhere in the body. Dead state. Also, `task` re-runs whenever the view's identity changes; after success, `showError` flip is meaningless.
- **[Bug]** Line 30: `.idle` case shows `EmptyView()` — but `.task` will run on first appear and set state to `.loading`, so `.idle` is briefly visible (may flash). Fine, but consider showing `loadingBody()` for `.idle` too.
- **[API]** Line 11: `Body` generic parameter shadows SwiftUI's `View.Body` associated type — confusing.
- **[Style]** Long line 20: 6-parameter init declaration on a single line is dense but compliant with rule.

### `SwiftUI/Component Views/LongPressButton.swift`
- **[Bug]** Line 20: `@State private var longPressStartedAt: Date!` — implicitly unwrapped optional `@State`. Force-unwraps don't appear, but the type signature is awkward — should be `Date?`.
- **[Bug]** Line 89: `abs(longPressStartedAt.wrappedValue?.timeIntervalSinceNow ?? 0) > delay` — fires `longPressed()` based on elapsed time during drag updates, which is redundant with the `Task.sleep`-driven trigger at line 84, and can fire `longPressed()` twice in rapid succession (the `longPressInvalidated` guard helps but is not atomic).
- **[Bug]** Line 56: `Task { ... try await longPress() }` is not `@MainActor`-annotated, while line 43 is. Inconsistent — if `longPress` mutates view state it must be on main.
- **[Concurrency]** Line 67-69: capturing `_longPressStartedAt`, `longPressed`, `delay` into locals inside `body` is a workaround for `@State` quirks; usable but obscure. The `longPressed` local function will be re-created every body invocation, potentially causing re-evaluation churn.
- **[Style]** Line 100: `.onEnded{ value in` — missing space; the parameter `value` is unused.
- **[API]** Line 24: 5-parameter init plus default empty `longPress` closure; ok.

### `SwiftUI/Component Views/OffsetReportingScrollView.swift`
- **[Bug]** Line 62: `MainActor.run { position = offset }` inside `clearBackground(using:)` — calling `MainActor.run` synchronously from an unknown context: if already on MainActor it crashes (or produces a warning). Should be `Task { @MainActor in position = offset }` or use `.preference`/`onChange`. Also, mutating a `@Binding` from inside `body` evaluation during `GeometryReader`'s view-builder phase causes "Modifying state during view update" purple warnings — classic SwiftUI bug.
- **[Suggestion]** Replace with `GeometryReader` -> `PreferenceKey` -> `onPreferenceChange` pattern, or use iOS 17 `onScrollGeometryChange` for newer targets.
- **[API]** Line 18: `init` takes `axes` positionally without label — fine; `showsIndicators` deprecated on iOS 16+ in favor of `.scrollIndicators(.hidden)`.

### `SwiftUI/Component Views/SimpleErrorMessageView.swift`
- **[Platform]** Line 11: missing `tvOS` in availability — used by `LoadingView` which targets tvOS 15.
- **[API]** Line 14: `fallbackText` is `var` not `let` — should be `let` (set only at init).
- **[API]** No public init — generated memberwise init is internal, blocking external instantiation despite `public struct`.

### `SwiftUI/Component Views/SimpleProgressView.swift`
- **[Style]** No issues beyond `Spacer()` wrapping that may stretch full height where unwanted.

### `SwiftUI/Component Views/Spacers.swift`
- **[API]** Public types but no `@available`. Minor.

### `SwiftUI/Component Views/TitleBar.swift`
- **[Bug]** Line 58: `.navigationBarHidden(true)` is iOS-only; this code compiles for macOS only because of `#if canImport(SwiftUI)` umbrella from imports — actually `navigationBarHidden` is unavailable on macOS/tvOS/watchOS. Will fail to build on non-iOS platforms.
- **[Deprecated]** Line 58: `navigationBarHidden(_:)` is deprecated in iOS 16; use `.toolbar(.hidden, for: .navigationBar)` with `@available` gating.
- **[Style]** Line 57: `.frame(height: 50)` hard-codes a dimension — violates project rule.
- **[Concurrency]** Line 11: `nonisolated(unsafe) public static var defaultValue = Font.title` — should be `let`.
- **[Style]** File is 108 lines — over guidance; could split overload extensions to a separate file.

## SwiftUI / Button Styles

### `SwiftUI/Button Styles/FullWidthButtonStyle.swift`
- **[Bug]** Line 41: `if !borderOnly { return foregroundColor ?? .white }` — in the `borderOnly = false` watchOS branch, returns *foreground* color as background. Almost certainly a bug; should be `backgroundColor ?? .white` (mirrors line 38 pattern).
- **[Style]** Line 17: `let cornerRadius = 8.0` and line 65: `.frame(height: 50)` — hard-coded dimensions.
- **[Platform]** Line 11: missing `tvOS` from availability.
- **[API]** No way to customize `cornerRadius`.

### `SwiftUI/Button Styles/SafeGlassButtonStyle.swift`
- **[Platform]** Line 13: `#if os(visionOS)` branch returns `.bordered`/`.borderedProminent` regardless of macOS 26 / iOS 26 glass availability — ok intentionally. But note: visionOS 26 may also have glass. Verify that's intended.
- **[Suggestion]** The `if #available(iOS 26.0, ...)` check is forward-looking placeholders for future API. If `.glass` button style isn't yet shipping in any released SDK, this won't compile against current SDK. Confirm against SDK availability.

## SwiftUI / Drag and Drop

### `SwiftUI/Drag and Drop/DragContainer+Keys.swift`
- **[Concurrency]** Line 35, 40: `nonisolated(unsafe) static var defaultValue` should be `let` — mutable static is a data-race liability even with `unsafe`.
- **[Platform]** Line 21: `@available(OSX 13, iOS 16, watchOS 8, tvOS 13, *)` for `Image.init(dragImage:)` on UIKit branch — claims tvOS 13 but `ImageRenderer` (next) requires `tvOS 16`. Mismatched availabilities across the same `#else` block.
- **[Platform]** Line 15-18: `@available(OSX 13, iOS 16, tvOS 13, watchOS 8, *)` on `extension ImageRenderer` for macOS branch — `ImageRenderer` itself requires macOS 13 / iOS 16 / tvOS 16. The `tvOS 13` annotation is wrong.

### `SwiftUI/Drag and Drop/DragContainer.swift`
- **[Concurrency]** Line 13: `@StateObject private var coordinator: DragCoordinator` — `DragCoordinator` is `@MainActor` (good). Line 18-20: `DragCoordinator()` then `coordinator.snapbackDuration = snapbackDuration` happens in `init` which is NOT `@MainActor`. Mutating a `@MainActor` property from a non-MainActor context is a data race.
- **[Bug]** Line 43-46: `coordinator.containerFrame = geo.frame(...)` set inside `onAppear` and `onReceive` — `onAppear` runs synchronously during view rendering and assigns to a non-`@Published` property (line 16) — view will not refresh on container resize.
- **[API]** Line 16: `containerFrame: CGRect?` is `internal`; should likely be `private` or with controlled accessor.

### `SwiftUI/Drag and Drop/DragCoordinator.swift`
- **[Bug]** Line 50: `describe()` builds `text` then never uses it — dead code; should `print` or `SuiteLogger.debug(text)`.
- **[API]** Line 25: `@Published var draggedObject: Any?` — type-erased `Any`. Forces consumers to downcast, and Sendable is impossible. Consider a generic constraint or `AnySendable` wrapper.
- **[API]** Line 24: `dragType: String?` — stringly-typed identifier; an enum or phantom-type approach would be safer.
- **[Style]** Line 53-77: `enum DragAcceptance` declared inline with cases on the same line as `enum` keyword — unusual formatting.
- **[Concurrency]** Line 97: `Task { @MainActor in try? await Task.sleep(nanoseconds: 10_000_000); if self.acceptedDrop { ... } }` — 10ms sleep used as a synchronization primitive (waiting for SwiftUI to propagate state). Fragile. Document or replace with a deterministic mechanism.
- **[Memory]** No explicit cleanup of `draggedObject` (`Any?`) on view tear-down — could retain large user objects until next drag. Minor.
- **[Style]** File is 159 lines — over guidance; consider splitting `DragAcceptance` enum into its own file.

### `SwiftUI/Drag and Drop/View+makeDraggable.swift`
- **[Bug]** Line 14-22: custom `==` for `DragPhase` ignores associated values (`.dropped(String)` matches any other `.dropped`). If consumers rely on the targetID this is a bug; if intentional, document. Synthesized Equatable would be preferable.
- **[Concurrency]** Line 122-130: `Task { try? await Task.sleep(...); isDragging.wrappedValue = false; ... }` — Task is not `@MainActor`; mutates `@State` projected `_isDragging` from a background context. Race condition.
- **[Concurrency]** Line 96-99: capturing `dragCoordinator = dragCoordinator` (an `EnvironmentObject`) into a closure that's evaluated outside body — risky if the coordinator instance changes; usually fine but fragile.
- **[Bug]** Line 109: `let renderer = ImageRenderer(content: dragContent())` — `ImageRenderer` must be created on `MainActor`; gesture `updating` closure runs on main during gesture, but it's not annotated. Verify.
- **[Style]** Line 11: `enum DragPhase` declared with cases on same line as `enum` keyword — unusual.
- **[API]** Line 28: 7-parameter modifier — awkward; consider a config struct.
- **[Convention]** File is 135 lines — slightly over guidance.

### `SwiftUI/Drag and Drop/View+makeDropTarget.swift`
- **[Concurrency]** Line 10: `@MainActor extension CoordinateSpace` for static `let` constants is unusual; statics shouldn't need `@MainActor`. The `CoordinateSpace.named(...)` initializer is `Sendable`-safe; the wrapper isolation is restrictive and unnecessary.
- **[Bug]** Line 31: `CoordinateSpace.dragAndDropSpaceCreatedNotification.notify()` posted on every `onAppear` of every drag-and-drop coordinate-space view. If multiple containers/targets exist, it'll fire repeatedly. Acceptable but worth a comment.
- **[Bug]** Line 91-98: `dropPositionChanged` always sets `acceptedDrop = true` and `currentDropTargetID = dropTargetID` if `dropped(...)` returns `true`, but does not respect `priority` ordering against other targets — earlier `currentPositionChanged` (line 110) does respect priority, but on actual drop the priority check is missing.
- **[API]** Line 24: `makeDropTarget` 8-parameter modifier — awkward.
- **[Style]** Line 60: `let dropIndicatorSize = 30.0` — hard-coded dimension.
- **[Convention]** File is 144 lines — over guidance.

## SwiftUI / Shapes

### `SwiftUI/Shapes/Line.swift`
- **[API]** Line 11: `var horizontal = true` should be `let` (set only at init).
- **[API]** Could expose `axis: Axis` (`.horizontal`/`.vertical`) instead of a Bool for clarity.

### `SwiftUI/Shapes/PartlyRoundedRectangle.swift`
- **[Bug]** Line 25: `let radius = min(self.radius, min(rect.width, rect.height))` — should clamp to half the minimum dimension, not the full minimum, otherwise corners can overlap (e.g., a square with radius == width produces malformed arcs).
- **[Platform]** Line 11: tvOS in availability OK; but Angle extensions at line 64 are public — fine.
- **[Style]** Line 27: `CGPoint(rect.minX, rect.midY)` — uses an unlabeled `CGPoint(_:_:)` initializer; not standard. Verify the project's `CGPoint` extension exists.
- **[API]** Line 13: `Corner` is `Sendable` but stored in an `Array<Corner>` — fine; consider `OptionSet` for ergonomic call sites: `PartlyRoundedRectangle(corners: [.top], ...)`.

### `SwiftUI/Shapes/Path.swift`
- **[Bug]** Line 32: `addEllipse(in: CGRect(x: current.x - radius / 2, y: current.y - radius / 2, width: radius, height: radius))` — width/height should be `radius * 2` if `radius` is a true radius. As written, you're drawing a circle of *diameter* `radius`, half-shifted. Either rename param to `diameter` or fix to `radius * 2`.
- **[Bug]** Line 14-26: `addCurve(...)` only draws the control-point markers when `showingControlPoints == true`. After drawing markers, calls `addCurve(to: end, control1:cp1, control2:cp2)` (line 27) which is the original mutating method on `Path` — recursive call risk? No, because the parameter labels differ (no `showingControlPoints`), Swift selects the standard one. Confirmed OK.

### `SwiftUI/Shapes/Shape.swift`
- **[API]** Line 13: returns `some View`, but caller may want `InsettableShape`-style chaining — hard to extend.
- No major issues.

### `SwiftUI/Shapes/Trig.swift`
- **[Bug]** Line 18-23: `quadrant` getter has incorrect mapping. Standard math quadrants (counter-clockwise from +x axis): I=0-90, II=90-180, III=180-270, IV=270-360. The code returns `.i` for ≤90, then `.iv` for ≤180 (should be `.ii`), then `.iii` for ≤270 (matches), then `.ii` for >270 (should be `.iv`). The label-to-range mapping is wrong; either rename quadrants or fix the ranges.
- **[Bug]** Line 25-43: `adjustedForQuadrant` does inconsistent math:
  - `.i`: returns `degrees` (0-90) — fine
  - `.ii`: subtracts 270 — would yield negative for typical "II" range. Combined with the wrong `quadrant` getter, the math may "work out" but is impossible to reason about.
  - `.iii`: subtracts 180; `.iv`: subtracts 90 — pattern doesn't match standard angular reduction.
- **[Bug]** Line 49-55: `CGPoint.quadrant(in:)` maps top-left to `.ii`, bottom-left to `.iii`, top-right to `.i`, bottom-right to `.iv`. This conflicts with the angular `Angle.quadrant` mapping above — same enum used for two different quadrant systems. Confusing and error-prone.
- **[API]** Line 11: enum cases `i, ii, iii, iv` declared on same line as `enum` keyword.
- **[Suggestion]** Add unit tests; the trig math here looks subtly wrong and untested.

## SwiftUI / View Extensions, Modifiers, Wrappers

### `SwiftUI/View Extensions/GeometryReader.swift`
- No issues.

### `SwiftUI/View Extensions/Image.swift`
- **[Bug]** `Image.random()` (line 28) force-unwraps `SFSymbol.allCases.randomElement()!` — if `allCases` is ever empty (e.g. an error in symbol enumeration), this crashes. Use a safe fallback symbol.
- **[Platform]** `Image(string:)` is iOS-only (line 32-40). The non-iOS counterpart on `UIImage` doesn't exist for tvOS/visionOS — `#if os(iOS)` excludes both Mac Catalyst and visionOS where `UIKit` is available; consider `#if canImport(UIKit) && !os(watchOS)` for parity with the rest of the framework.
- **[API]** `resizeTo(_:_:)` mixes optional-default (`mode`) with non-optional positional `size`; awkward call site (`.resizeTo(.fit, size)` reads weirdly).

### `SwiftUI/View Extensions/TouchUpDown.swift`
- **[Bug]** `TouchRepeatingView.touchDown()` (line 42-60): the `interval` parameter is captured in the struct but unused — the loop uses a hard-coded `200_000_000` ns initial delay. Either remove the param or honor it.
- **[Concurrency]** The unstructured `Task` in `touchDown()` is detached from the view lifecycle except via `onDisappear`. If the modifier re-creates the struct rapidly, multiple repeating tasks may stack despite the `if task != nil` guard (because the new struct gets fresh `@State`).
- **[Convention]** `TouchRepeatingView`'s `body` accesses `touchDown`/`touchUp` (instance methods that mutate `@State`) — the methods themselves are fine, but consider not exposing intermediate methods on a public wrapper struct.

### `SwiftUI/View Extensions/View+Buttons.swift`
- **[Convention]** Hard-coded dimensions `minWidth: 44, minHeight: 44` (line 13) violate the "avoid hard-coded dimensions" rule. 44 is Apple's HIG minimum touch target so it's justifiable, but consider exposing as a constant or using `Layout` metrics.

### `SwiftUI/View Extensions/View+Debug.swift`
- **[Concurrency]** `Suite.logg(...)` is called inside `Log.init` and `View.log` (lines 16, 51) — these are called during view body evaluation, which means logging happens on every render. Consider documenting the perf implication, or moving to `.onAppear`.

### `SwiftUI/View Extensions/View+PreferenceValues.swift`
- **[Bug]** `preferenceReduce<V>(value: inout V, nextValue: () -> V)` (line 14) is a no-op — it neither calls nextValue nor updates value. If this is intentional ("first wins") it's fine but should be documented; otherwise it's a dropped value.
- **[API]** `getPreferenceClosure` two overloads (lines 61, 70) — naming is awkward and second uses `@Sendable` while first uses `@MainActor`; inconsistent isolation.
- **[Convention]** Multi-line function declarations throughout (lines 30, 36, 42, 48, 54, 61, 70) violate "avoid multi-line function declarations".

### `SwiftUI/View Extensions/View+Printing.swift`
- **[Platform]** `@available(... macOS 99.0, watchOS 99.0, *)` (line 14) is a hack to disable on those platforms. Use `#if os(iOS)` (already wrapped) — the bogus version is unnecessary and misleading.
- **[Bug]** `urlForPrintedPage` (line 24) — `imageForPrinting()` is undefined on tvOS/visionOS but the wrapper `#if os(iOS) || os(macOS)` allows iOS/macOS only, so OK. However the iOS-only `imageForPrinting` (line 15) and macOS-only one (line 45) both exist, but on iOS+macOS without `os(iOS) || os(macOS)`, the call resolves correctly. This works but is fragile.
- **[Convention]** Hard-coded `letterPageSize = CGSize(width: 612, height: 792)` (line 10) — letter-size is a real-world constant so acceptable, but should be `public` or at least documented.

### `SwiftUI/View Extensions/View+UIViewController.swift`
- **[Concurrency]** `EnclosingViewControllerKey.defaultValue` is `nonisolated(unsafe) var` (line 40) — a single shared mutable container across the entire app. This is a global singleton masquerading as an environment default; assignments race.
- **[Memory]** `EnclosingViewControllerContainer` holds `weak _viewController` (good), but `defaultValue` being a single shared instance means every view in the process shares one container. Setting it in one view affects all readers.
- **[API]** `enclosingViewController` (line 61) uses `self as? ContainedInViewController` — `View` is a value type and unlikely to conform; this almost always returns nil and is misleading.

### `SwiftUI/View Extensions/View+URL.swift`
- **[Concurrency]** `display(url:inSafari:)` is not `@MainActor` annotated despite calling `UIApplication.shared.open` and presenting view controllers (lines 20, 27). On Swift 6 this will warn/error.
- **[API]** `display(url:)` is unusual on `View` — calling it returns no view modification; it's a side-effect method on `View`. Better as a free function or namespaced helper.

### `SwiftUI/View Extensions/View+macOS.swift`
- **[API]** `public enum UIKeyboardType { case alphabet }` (line 13) shadows UIKit's type and is never used — looks like a stub. The `keyboardType(_ type: UIKeyboardType)` no-op is a cross-platform stub but only declared on macOS; ensure clients don't expect parity.
- **[Convention]** `View` is referenced without `import SwiftUI` (only `import AppKit` is imported; line 11). May break compilation depending on transitive imports.

### `SwiftUI/View Extensions/View+sizeReporting.swift`
- **[Bug]** `SizeViewModifier.body` (line 18-23) and `frameReporting` (lines 64-85) write to a `Binding` from inside `GeometryReader`'s body via `Task { @MainActor in ... }` — this is the classic "modifying state during view update" pattern. The `SizeReporter` (lines 40-56) using `PreferenceKey` is the correct approach and should replace the others.
- **[Concurrency]** `SizePreferenceKey.defaultValue` and `FramePreferenceKey.defaultValue` use `nonisolated(unsafe)` (lines 29, 35) — for `static let` constants this is unnecessarily unsafe; should be `static let defaultValue: CGSize = .zero` (let, not var).
- **[Concurrency]** `frameReporting` and `reportGeometry` capture bindings in `Task { @MainActor }` from non-isolated closures — Sendable check failures likely on Swift 6.
- **[Perf]** `sizeLogging` (line 119) calls `logg` from inside `GeometryReader.body` — runs on every layout. Document this is for debugging only.
- **[Convention]** File is 238 lines — significantly exceeds the ~100 line guideline. Split into `SizeReporting`, `SizeOverlay`, `PositionOverlay`.
- **[Convention]** Multi-line function declarations (line 75, 87) violate convention.

### `SwiftUI/View Extensions/View.asyncOnChangeOf.swift`
- **[Concurrency]** Inside `Task { ... }` (line 14), `action` is captured but the closure isn't marked `@Sendable`/`@MainActor`. The wrapping `onChange` body runs on MainActor; the `Task` it spawns is not. May warn under strict concurrency.
- **[Convention]** Multi-line function declaration (line 12).

### `SwiftUI/View Extensions/View.presentationDetentSizeToFit.swift`
- **[Bug]** Line 37: `presentationDetents([sheetHeight == nil ? .medium : .height(sheetHeight!)])` — force unwrap is safe due to the check, but `if let` with `?? .medium` cleaner.
- **[Convention]** Multi-line/awkward `presentationDetents` chain inside `body` is fine.

### `SwiftUI/View Extensions/View.swift`
- **[Concurrency]** `toImage` (line 16-33) creates `UIHostingController` and renders synchronously — must be `@MainActor`. Currently inherits from extension's availability but no isolation annotation.
- **[Bug]** `toImage` references `UIGraphicsImageRenderer` which is unavailable on visionOS in some contexts; behavior of `drawHierarchy(afterScreenUpdates: true)` warns when called off-screen.
- **[API]** `anyView()` (line 44) — encourages type-erasure, which is a SwiftUI antipattern. Consider deprecating.
- **[Convention]** `if`/`iflet` (lines 63, 71) — common but contributes to view-tree branching that defeats SwiftUI diffing. Document caveat.

### `SwiftUI/View Modifiers/NotYetImplemented.swift`
- No issues.

### `SwiftUI/View Modifiers/Outlined.swift`
- **[Perf]** `Canvas` + `resolveSymbol` rebuilt every body update; the `id = UUID()` (line 19) per-instance is fine but `Canvas` redraws on every layout pass — could be expensive for many outlined items.
- **[Concurrency]** No issues.

### `SwiftUI/View Modifiers/Spinning.swift`
- **[Deprecated]** `.animation(_:value:)` modifier on view (line 26) is the modern call, but applying `repeatForever` animation to `rotationEffect` via `onAppear` setting `rotation` is a long-standing fragile pattern in SwiftUI. Consider `withAnimation` on appear or `.symbolEffect`/phase animator on iOS 17+.
- **[API]** `SpinningModifier.period` is stored but unused (line 33) — `body` constructs `Spinning(content)` without forwarding `period` (line 36). Bug: passing a custom period to `.spinning(period:)` is ignored.
- **[Bug]** Confirmed bug: `period` is dropped (line 36 omits `period: period`).

### `SwiftUI/View Modifiers/onTimer.swift`
- **[Concurrency]** Uses `Timer.publish` + Combine. CLAUDE.md says "use async/await, not Combine, GCD or queues." This whole file violates that — could be replaced with a `.task` that loops over `Timer.sequence`/`AsyncStream` or a `Task.sleep` loop.
- **[API]** `onTimer` is `internal` (no `public`); inconsistent with other public extensions in the framework.

### `SwiftUI/View Wrappers/AcceptsFirstMouse.swift`
- **[Convention]** Imports only `Foundation` (line 8) but extends `View` — relies on transitive SwiftUI import. Should `import SwiftUI`.
- **[Perf]** `updateNSView` calls `setNeedsDisplay(nsView.bounds)` on every update for an invisible click-receiver — unnecessary.

### `SwiftUI/View Wrappers/AsyncContainerView.swift`
- **[Concurrency]** `function: () async throws -> Void` not marked `@Sendable`. The `.task` runs on MainActor implicitly, so OK for now, but Swift 6 may complain.
- **[API]** Naming: this isn't `*Screen` so OK as a wrapper. No issues.

### `SwiftUI/View Wrappers/BottomSheetView.swift`
- **[Deprecated]** `.animation(animation)` without a `value:` parameter (lines 78, 97, 144) is deprecated since iOS 15 in favor of `.animation(_:value:)`.
- **[Bug]** `OverlayModifer` typo in name — should be `OverlayModifier` (lines 14, 34, 53). Public API; renaming would be breaking.
- **[Convention]** File is 161 lines — exceeds guidance. Split `BottomSheet` and `presentDimmedOverlay`/`presentBottomSheet` into separate files.
- **[API]** `Item` type parameter is not constrained to `Sendable`; binding stored in modifier may produce concurrency warnings.
- **[Platform]** `#if os(iOS) || os(macOS)` excludes tvOS/visionOS even though some bottom-sheet behavior is meaningful on those platforms.

### `SwiftUI/View Wrappers/DebuggingIDView.swift`
- **[Concurrency]** `public static var showViewDebuggingIDs = false` (line 25) — global mutable state without isolation. Must be `nonisolated(unsafe)`, `@MainActor`, or `let`.
- **[Convention]** No `@available` on `DebuggingIDView` itself, while extension is gated. Inconsistent.

### `SwiftUI/View Wrappers/Deferred.swift`
- **[Bug]** Wrapping content in an `HStack` (line 23) imposes layout semantics the caller didn't ask for — when the deferred content is e.g. a full-screen view, the HStack adds spacing/alignment behavior. Use a transparent container or `Group`.
- **[Concurrency]** The `.task` runs the sleep then assigns `content`. Cancellation on view disappear works via `.task`'s built-in handling, OK.

### `SwiftUI/View Wrappers/EqualSizes.swift`
- **[Concurrency]** `Task { @MainActor in reportedSubviewSizes = sizes }` (line 61) — wrapping a state assignment in a Task is unnecessary; the `getPreference` closure already runs on MainActor (the helpers in View+PreferenceValues.swift declare `@MainActor`).
- **[Perf]** Each preference change triggers a Task hop and a state write that propagates via `@Environment`, causing potential cascade re-layout. Consider direct assignment.
- **[API]** `maxSize` returns `nil` when the maxSize is `.zero` — this collapses "no entries" and "all-zero entries". For empty arrays it should remain nil; for all-zero it's ambiguous.

### `SwiftUI/View Wrappers/Guidelines.swift`
- **[Bug]** Line 49: `yMarks = (0...x).map { ... yWidth }` — uses the `x` parameter range to build `yMarks`. Should be `(0...y)`. Concrete bug producing wrong y-mark count when `x != y`.
- **[Convention]** Acceptable file size.

### `SwiftUI/View Wrappers/InterfaceOrientedView.swift`
- **[Concurrency]** Uses Combine (`AnyCancellable`, `.publisher().sink`) — violates CLAUDE.md's async/await preference. Switch to `NotificationCenter.default.notifications(named:)` async sequence.
- **[Bug]** `subscription = ...` (line 26) is assigned but `cancellables` is also declared (line 23) and never used — dead code.
- **[Memory]** `subscription` is force-unwrapped `AnyCancellable!` (line 35) for no reason; should be `AnyCancellable?` or non-optional from init.
- **[Bug]** `OrientationWatcher.instance` is mutable (`static var`); reassigned in `setup(windowScene:)` (line 20). Existing `@ObservedObject` references in views point at the old instance after `setup` is called — staleness bug.
- **[Concurrency]** `static var instance` without isolation on a `@MainActor` class — the static property itself isn't actor-isolated.
- **[API]** `description` says only "Landscape" or "Portrait" but `UIInterfaceOrientation` has more states (unknown, portraitUpsideDown). Loses info.

### `SwiftUI/View Wrappers/PublisherView.swift`
- **[Concurrency]** Whole file built on Combine — violates CLAUDE.md async/await preference. Replace with `AsyncStream`/`for await`.
- **[Concurrency]** `pub.receive(on: RunLoop.main)` — RunLoop scheduling instead of MainActor; archaic.

### `SwiftUI/View Wrappers/SideDrawerContainer.swift`
- **[Bug]** Trailing-side offset uses `geo.width` (line 37) for the off-screen position, but trailing drawers should slide from the right; `HStack { content; Spacer() }` always anchors content to the leading edge — for `side == .trailing` the layout is wrong (content starts on leading, slides offscreen to the right). Should swap content/spacer based on side.
- **[Convention]** Acceptable.

### `SwiftUI/View Wrappers/SlideUpSheet.swift`
- **[Convention]** File is 188 lines — exceeds the ~100 line guideline.
- **[Deprecated]** `.animation(.default)` (line 151) without `value:` is deprecated.
- **[Concurrency]** `SlideUpManager.isSheetVisible` uses manual `objectWillChange.send()` in `willSet` (line 23) instead of `@Published` like `currentSheet` (line 29). Inconsistent and easy to miss.
- **[API]** `currentSheet: AnyView?` — type erasure on the manager; same antipattern as `View.anyView()`.
- **[Concurrency]** `Task { @MainActor in withAnimation { ... } }` (line 38-42) is invoked from `show(_:)` which is already on MainActor (the class is `@MainActor`). The Task hop is unnecessary.
- **[Bug]** `screenHeight: CGFloat = 1024` fallback for AppKit is hard-coded (line 83) and non-AppKit fallback also `= 1024` (line 86). Real screen on macOS varies wildly. Use `NSScreen.main?.frame.height`.
- **[Convention]** Hard-coded dimensions: `radius: 10` (line 94), `frame(width: 40, height: 5)` (line 126), `frame(height: 14)` (line 133), `> 100` drag threshold (line 159) — multiple violations of "avoid hard-coded dimensions".
- **[Bug]** `.offset(y: show ? dragOffset.height : screenHeight * 2)` — when `show` is false, sheet jumps off-screen rather than animates; combined with `.transition(.slide)` and `.animation(.default)` produces inconsistent motion.

## SwiftUI / Other Views, Observers, Gestures, Navigation

### `SwiftUI/Gestures/View.gesture.swift`
- **[Suggestion]** Trivially small — fine. The `@ViewBuilder` annotation here is unnecessary since the body is a single `self.gesture(...)` call (line 11).
- **[API]** Function name `gesture(enabled:_:)` shadows SwiftUI's own `View.gesture(_:)`; placing the boolean first is fine, but consider documenting that `nil` is passed when `enabled == false` so callers understand the resulting type is `Optional` semantics.

### `SwiftUI/Navigation/HiddenNavigationLink.swift`
- **[Suggestion]** `NavigationLink(value:)` with an `EmptyView` label set to `opacity(0)` and used in `.background` is functional but fragile — VoiceOver may announce the hidden link, and tap-throughs from the visible label aren't actually wired up (the label itself is not tappable; only the hidden link is). Behavior may surprise consumers (line 19-24).
- **[API]** Naming says "Link" but it provides no tap interaction on the visible label — consider renaming or documenting that this is purely a programmatic-trigger helper for `NavigationStack` value-based routing.

### `SwiftUI/Observers/CurrentDevice.swift`
- **[Bug]** `UIScreen.main` is deprecated on iOS 16+ and behaves incorrectly in multi-scene apps; `screenSize` will not reflect the active scene's size (lines 19, 37).
- **[Concurrency]** `@objc func orientationChanged()` is called on an arbitrary thread by `NotificationCenter`, but the class is `@MainActor`. Calling `MainActor.run { ... }` from a non-isolated `@objc` selector is okay but the selector itself being declared on a `@MainActor` class is an isolation mismatch under strict concurrency (line 33). Better: post to NotificationCenter on `.main` queue via the closure-based observer, or mark the selector `nonisolated`.
- **[Concurrency]** `MainActor.run { ... }` (synchronous) called from non-main thread will trap. Should be `Task { @MainActor in ... }` (line 34).
- **[Platform]** Guarded with `#if os(iOS) && !os(visionOS)` but `os(iOS)` already excludes visionOS unless the deployment target uses iPad-on-Vision; the redundant guard is harmless but noisy (line 9).
- **[API]** `screenSize` is initialized once at construction and only updated on orientation change — does not reflect window resizing on iPad Stage Manager / split view (line 19).
- **[Memory]** `addObserver(self, selector:...)` retains observer until deinit; missing explicit `removeObserver` in deinit. Singleton makes this moot, but pattern is fragile.

### `SwiftUI/Observers/NotificationObserver.swift`
- **[Concurrency]** Closure on `addObserver(forName:queue:.main)` is `@Sendable`; capturing `self` of `@MainActor`-isolated class and calling `objectWillChange.send()` is fine on `.main` queue, but the closure is not formally main-actor-isolated, so under strict concurrency this may warn (line 18).
- **[Memory]** `token` is never used to remove the observer in `deinit`. Modern `NotificationCenter.addObserver(forName:...)` returns an opaque token that must be removed; otherwise the observer outlives weak `self` capture and continues firing closures into space. Fine for app-lifetime instances but leaky as a general pattern (line 16).
- **[Convention]** Uses Combine `NotificationCenter.Publisher` and `onReceive` rather than async/await. The codebase guideline prefers async/await; consider `for await note in NotificationCenter.default.notifications(named:)` (line 26).

### `SwiftUI/Observers/ObservableActor.swift`
- **[Concurrency]** `target: Content!` is force-unwrapped IUO and assigned in `async init`. If anyone reads `target` before `init` completes (impossible in Swift, but `.target?` on line 18 hints at uncertainty) you'd crash — yet `target?` after the assignment is dead code; either it's `Content!` (force) or `Content?` (optional). Inconsistent (lines 12, 18).
- **[Concurrency]** `Content: Sendable & ObservableObject` but `objectWillChange.sink` runs the closure on the publisher's thread; `self?.objectWillChange.send()` on a `@MainActor` class from arbitrary thread is unsafe. Should hop to MainActor explicitly (line 18).
- **[Memory]** `cancellable` retained; `target` retained strongly. If `Content` retains a reference back to the wrapping `ObservableActor`, retain cycle. No `[weak self]` issue here, but lifecycle ownership is not documented.
- **[Convention]** Uses Combine; Suite project guideline prefers async/await over Combine.

### `SwiftUI/Observers/ObservableStub.swift`
- **[Concurrency]** `nudge()` does `Task { await MainActor.run { self.objectWillChange.send() } }` — since the class is already `@MainActor`, `nudge()` is implicitly main-actor; the `Task { await MainActor.run { ... } }` is redundant. Just `objectWillChange.send()` (line 21).
- **[Suggestion]** `nudge()` swallows the actor hop into a detached `Task`; callers won't know send is asynchronous. Consider a synchronous `nudge()` that just sends.

### `SwiftUI/Observers/ScrollCanary.swift`
- **[Bug]** `MainActor.run(after: 0.01) { ... }` (line 40) — synchronous `MainActor.run` does not have a built-in `(after:)` overload; must be a Suite extension. If implemented via `DispatchQueue.main.asyncAfter`, this violates "no GCD" guideline.
- **[Concurrency]** `Task.detached { ... Task { @MainActor in isScrolling = false } }` is a strange pattern: detached task that just hops back to MainActor. Replace with single `Task { @MainActor in try await Task.sleep(...); isScrolling = false }` (lines 44-49).
- **[Bug]** `GeometryReader` returning `Color` from a non-`@ViewBuilder` closure is being used to perform side effects during layout. Mutating `@State` (`initialFrame = newFrame`) inside layout-time geometry callback can trigger update loops and "Modifying state during view update" warnings (line 41).
- **[Bug]** Side effects directly inside `GeometryReader { geo -> Color in ... }`: writing to `scrollOffset` (line 53) on every layout pass causes feedback loops and runtime warnings.
- **[Convention]** `clearScrollingTask` is `@State` — mutating a Task captured in @State during layout is risky.
- **[Convention]** Uses hard-coded `.frame(height: 1)` (line 34) and `0.01` / `300_000_000` magic numbers for delays.
- **[Convention]** Uses two computed properties returning `some View`: `body` is fine, but the `GeometryReader` closures could be split into dedicated subviews to make the side-effect/layout split explicit.
- **[Deprecated]** Should use `.onGeometryChange(for:of:action:)` (iOS 18+) or `PreferenceKey` rather than mutating state inside GeometryReader.

### `SwiftUI/Observers/SignificantTimeChangeObserver.swift`
- **[Bug]** `public actor SignificantTimeChangeObserver: ObservableObject` — `ObservableObject` requires the publisher to be reachable from MainActor for `@ObservedObject` use. Actor isolation will prevent SwiftUI from synchronously accessing `objectWillChange`, breaking observation (line 16).
- **[Concurrency]** `init()` calls `Task { await self.setup() }` — fire-and-forget setup means the observer may not be wired by the time the actor is used.
- **[Concurrency]** Inside `setup()`, the `sink` closure calls `self.objectWillChange.send()` directly on whatever queue Combine routes through — but `self` is an actor, so accessing `objectWillChange` from outside the actor isolation is illegal under strict concurrency (line 28).
- **[Convention]** Uses Combine (`AnyCancellable`, `.sink`) — codebase prefers async/await. Should use `for await _ in NotificationCenter.default.notifications(named: UIApplication.significantTimeChangeNotification)`.
- **[Suggestion]** Singleton actor with `ObservableObject` is a contradiction — pick one paradigm.

### `SwiftUI/Other Views/CalendarMonthView/CalendarMonthView+Components.swift`
- **[Convention]** Multiple view-returning computed `some View` properties (`nextMonthButton`, `previousMonthButton`, `monthYearList`, `showYearMonthListButton`, `showYearMonthListTitle`) — codebase guideline prefers dedicated subview types over view-returning computed properties (lines 12, 22, 32, 42, 55).
- **[Bug]** Hard-coded `.foregroundStyle(.red)` on chevrons (lines 17, 27, 66) — violates "avoid hard-coded dimensions" intent (color isn't a dimension, but hard-coded styling not adopting tint/accent colors makes this less reusable).
- **[Platform]** `monthYearList` is empty on non-iOS; `showYearMonthListButton`'s popover only attaches on macOS — on tvOS/watchOS toggling `showingMonthsAndYears` does nothing, but the button still rotates the chevron (no popover/list). Confusing UX.

### `SwiftUI/Other Views/CalendarMonthView/CalendarMonthView.DayView.swift`
- **[Convention]** Hard-coded dimension `geo.size.height + 3` for selected-circle padding (lines 32) and `.padding(.vertical, 4)` (line 43). Use environment-driven spacing or `.padding()`.
- **[Bug]** Selection circle uses `frame(width: geo.size.height + 3, height: geo.size.height + 3)` — if the day cell is wider than tall the circle still keys off height; if cell is square and small, circle may clip. Acceptable but not robust.
- **[Suggestion]** `.foregroundStyle(dayColor ?? .primary)` only applies in unselected branch; selected branch uses hard-coded `.white` (line 27) instead of an `EnvironmentValue`.

### `SwiftUI/Other Views/CalendarMonthView/CalendarMonthView.WeeksView.swift`
- **[Bug]** `options(for dateIndex: Int)` compares `dateIndex == selected.day.day` (line 104). For previous-month placeholders `dateIndex` is negative (`-1`, `-2`, ...), and for current month it's the day-of-month integer — but `selected.day.day` returns the day-of-month of `selected`, which could match a current-month day even if `selected` is in a different month. The function does not check that `selected` is within `date.month` and `date.year`, so any selected day in any month highlights the same day-number in the displayed month.
- **[Bug]** `Date.Day(day: dayDate, month: date.month, year: date.year)` is constructed with `dayDate` that may be negative for previous-month placeholders (line 43). The `Date.Day` ctor likely doesn't expect negatives — check whether this produces an invalid date or wraps backward into prior month correctly.
- **[Bug]** `for i in 1..<date.firstDayOfWeekInMonth.rawValue` inserts negatives at index 0 in increasing `i` order, so the array becomes `[-(n-1), ..., -2, -1, 1, 2, ...]` — but inserting `-i` at index 0 each iteration produces `[-1, -2, -3, ...]` reversed: the leading filler becomes `[-(n-1), -(n-2), ..., -1]` only if reversed properly. Walk: i=1 → insert -1 at 0 → `[-1, 1..n]`; i=2 → insert -2 at 0 → `[-2, -1, 1..n]`. OK — that's correct order. (line 116)
- **[Bug]** `dates: [Int]` returns `Int` but those ints carry sign-as-flag semantics; use a tagged enum or `Date.Day?` instead. (line 113)
- **[Convention]** Multi-line function `init` declaration not used here, but `dayBuilder` and `weekDayLabelBuilder` are stored escaping closures with `@ViewBuilder` annotation on stored properties (line 27, 28) — that annotation does nothing on a stored property and is misleading.
- **[Convention]** Dead code: `oldBody` (lines 74-98) — unused fallback; should be removed.
- **[Suggestion]** Using `weeks.indices` and re-indexing inside `ForEach` is fine but stable identity for week rows would be `\.self` on weeks (each week is unique 7-tuple).

### `SwiftUI/Other Views/CalendarMonthView/CalendarMonthView.swift`
- **[Bug]** `_date = State(initialValue: display ?? date.wrappedValue)` (line 53) — if `display` later changes, the `onChange` updates `date` but the initial `State` is captured only once; that's fine, but if `date` (selected) changes from outside, the displayed month does not follow. UX trade-off, undocumented.
- **[Convention]** Multi-line public `init` (lines 51-58) — guideline says avoid multi-line function declarations. Same for the convenience inits at lines 115, 124.
- **[Convention]** Multiple view-returning computed `some View` properties: `monthNames`, `monthYearBinding` (binding, ok), `monthYearBar` (ViewBuilder func) — at least `monthYearBar` would be cleaner as a subview.
- **[Bug]** `monthYearBar(includeSpacer: false).opacity(0)` on line 63 used as a sizing placeholder, then real bar in `.overlay(alignment: .top)` (line 76). Layout depends on the placeholder always matching the overlay — a fragile pattern; if accessibility or text scaling change one, layout drifts. Hard-coded duplication.
- **[Platform]** `#if os(visionOS)` branch uses zero-arg onChange (iOS 17+), `#else` uses deprecated single-value `onChange(of:perform:)` (line 80-83). On iOS 17+, the deprecated form emits warnings.
- **[Deprecated]** `onChange(of: overrideDate) { newDate in ... }` (line 82) is deprecated on iOS 17+/macOS 14+. With `@available(iOS 16, macOS 14, ...)` you're partially in deprecation territory; consider the new `onChange(of:_:)` two-closure form.
- **[Bug]** `components.year = Int(newValue[1])` (line 93) — `Int(...)` on user-facing year string can return nil and then setting `components.year = nil` clears the year, falling back to the whole `date = ...` fallback. Probably fine but silent.
- **[Convention]** `CalendarPreview` is at file scope (line 130); add `#if DEBUG` guard.
- **[API]** `overrideDate` is stored but only read in onChange; consider a clearer name `displayDate`.

### `SwiftUI/Other Views/CalendarMonthView/CalendarWeekDayLabel.swift`
- No issues.

### `SwiftUI/Other Views/CalendarMonthView/MonthYearPopover.swift`
- **[Convention]** View-returning computed `some View` properties `monthList`, `yearList` (lines 30, 52) — prefer subview types per project guideline.
- **[Convention]** Hard-coded `.frame(height: 150)` (line 19) — magic dimension.
- **[Suggestion]** `let years = (Date().year - 50...Date().year)` recomputes `Date()` per body invocation (line 56); minor.
- **[API]** Year range `now-50...now` excludes future years; date pickers commonly need future years (birthdays vs. expiration dates). Hard-coded range.

### `SwiftUI/Other Views/CalendarMonthView/MultiColumnPicker.swift`
- **[Bug]** `extension UIPickerView { override open var intrinsicContentSize: CGSize { ... } }` (lines 11-17) — overriding `UIPickerView`'s intrinsicContentSize globally via a Swift extension is fragile (`open` on an extension override is questionable; this affects ALL `UIPickerView` instances app-wide, not just the one used here). Side-effecting other code that imports Suite.
- **[Convention]** Hard-coded `minimumColumnWidth = 140.0`, `.frame(height: 150)` (lines 23, 34) and the global 150 in the override — magic dimensions.
- **[Concurrency]** `extension UIPickerView` override may have isolation/MainActor implications; UIView is `@MainActor` on iOS 18+.
- **[Bug]** `$selection[column]` (line 41) — `Binding` subscript through array; if `selection.count != data.count`, index-out-of-range crash. No bounds check.
- **[Bug]** `Picker(label, ...)` uses `String(describing: columnData[row])` (line 43) — works for strings but `Data` is generic `Hashable`, so descriptions may be ugly for custom types.
- **[Platform]** Whole file `#if os(iOS)` — no fallback or stub on macOS/tvOS, callers using it conditionally must also `#if os(iOS)`.

### `SwiftUI/Other Views/DictionaryView.swift`
- **[Bug]** `init(dictionary dict: [Key: Any], excluding: [String] = [])` — `Key: Hashable` but `LineInfo.build(from: dict, ...)` expects `[AnyHashable: Any]`. The bridging from `[Key: Any]` to `[AnyHashable: Any]` happens implicitly on line 19 — actually it does NOT bridge automatically; this likely fails to compile or requires `dict as [AnyHashable: Any]`. Verify (line 19).
- **[Bug]** `LineInfo` has `Identifiable` `id: String { label + "\(indent)" }` (line 67) — collisions when two siblings share a label name at the same indent (impossible at same level since dict has unique keys, but across nested branches with same key+indent, IDs collide).
- **[Convention]** Hard-coded `indentSize = 12.0` constant — magic dimension (line 10).
- **[Perf]** `lines = LineInfo.build(...).sorted()` runs on init (line 19) — fine for small dicts, O(n log n) for large.
- **[Suggestion]** Sorting by `path` string is locale-insensitive but works; document.
- **[Suggestion]** `Row` uses `String(describing: value)` for non-dict values (line 55); `Date`, `Data`, etc. format poorly.
- **[Bug]** `Row` shows chevron-down for dictionaries (line 51) but tapping does nothing — no expand/collapse implemented.

### `SwiftUI/Other Views/ScreenOverlay.swift`
- **[Convention]** Heavy UIKit fallback (`UIHostingController`, `UIWindow`, runtime class swizzling via `objc_allocateClassPair`, `class_addMethod`) — explicitly contradicts the project's "avoid UIKit fallbacks" guideline. Major violation.
- **[Bug]** Runtime subclassing of view classes via `disableSafeArea()` (lines 105-128) is fragile, undocumented Apple-private behavior, and the subclass is registered globally — repeated calls leak class definitions; first-attempt-creates-class then subsequent calls reuse, OK, but allocating `objc_allocateClassPair` is non-trivial.
- **[Memory]** `OverlayWrapper` holds `overlayWindow: ScreenOverlay<Content>?` in `@State` — if the parent view body recomposes the State persists, but if parent disappears without `onDisappear` firing (e.g., scene torn down) the window leaks.
- **[Concurrency]** `ScreenOverlay` is `@MainActor` but `HostWindow.hitTest` is overridden without isolation; `UIView` is `@MainActor` so fine, but the file mixes manual class-pair Obj-C runtime and Swift concurrency — risky.
- **[Bug]** `if let focus = UIWindowScene.focused` then `HostWindow(windowScene: focus)`; otherwise `HostWindow()` without scene — on multi-scene apps, scene-less windows are deprecated and may be invisible (lines 55-59).
- **[API]** `ScreenOverlay<Content>` type name conflicts conceptually with the `View.screenOverlay` extension function — same name for type and function modifier is confusing.
- **[Convention]** `screenOverlay` modifier returns a `ZStack` rather than a typed view — minor; but `alignment` parameter is `VerticalAlignment` (only top/bottom/center handled). The `default:` case (line 86) treats anything else as center which silently ignores `.firstTextBaseline`/`.lastTextBaseline`.
- **[Bug]** `overlay-window.windowLevel = .statusBar` blocks the system status bar / interaction (line 63).
- **[Concurrency]** `Task { @MainActor ... }` not used anywhere; `HostWindow` is created on main, OK, but no rotation/size-change observer — `updateFrames()` only called once in init.
- **[Suggestion]** Class is 90+ lines including the `disableSafeArea` extension and `UIWindowScene.focused` extension — exceeds ~100-line guideline; consider splitting into separate files.
- **[Memory]** `UIHostingController` holds rootView; replacing `controller.rootView` is preferred over recreating the controller, but here `Content` is captured at init only — content updates do not propagate.

### `SwiftUI/Other Views/vprint.swift`
- **[Bug]** `vprint(_:)` invokes `print(...)` as a side-effect during view-body evaluation (lines 12-14). Returning `EmptyView()` from a function with side effects works, but means logs fire on every body re-render, which can be very noisy and is hard to reason about.
- **[Convention]** Performs IO during view layout; should be wrapped in `#if DEBUG` or guarded — currently logs in release builds.
- **[Suggestion]** `Content` is unconstrained; `print(content)` works for anything but returning `some View` from a non-`View` argument is awkward — consider `@ViewBuilder` or naming it `debugPrint(...)` to clarify intent.

## SwiftUI / Extensions

### `SwiftUI/EnviromentEchoingView.swift`
- **[Convention]** Filename typo: `EnviromentEchoingView` should be `EnvironmentEchoingView` — and per project conventions, the type itself also has the typo throughout (line 15). The struct name should be renamed too.
- **[Convention]** Imports `Foundation` instead of `SwiftUI` (line 8) — works only because SwiftUI is re-exported elsewhere; should explicitly `import SwiftUI`.
- **[API]** Public type but no module-level doc comment for the purpose of echoing environment values.
- **[Concurrency]** `content: () -> Content` closure stored without `@escaping` and not `@Sendable`; the trailing-closure init takes `@escaping` but the stored property's type doesn't reflect that — works at compile time but is sloppy.
- **[Suggestion]** No availability annotation on the `@Entry` extension at line 10–12 — `@Entry` requires iOS 18 / macOS 15 etc., which mismatches the struct's own `iOS 15` availability (line 14).

### `SwiftUI/Extensions/ToolbarItem.swift`
- **[Concurrency]** `static var default` is mutable on a value type extension and `@MainActor`-annotated (lines 13, 15). Mutable static state is a footgun — should be `let` if it's meant as a default constant. Mutating it from one place affects everything in the process.
- **[API]** Using a mutable global default for `ToolbarItemPlacement` is surprising; consider a function returning the platform default instead.

### `SwiftUI/Extensions/Closure.swift`
- **[Bug]** `body` performs side effects during view evaluation (line 26) — SwiftUI may invoke `body` arbitrarily many times, so the closure runs unpredictably. This is a known anti-pattern; recommend `.onAppear { closure() }` instead, or rename to make the side-effect intent clear.
- **[API]** `init(_ closure: @escaping @autoclosure () -> Void)` (line 21) is duplicate-overload-prone; calling `Closure(foo())` is ambiguous-ish and surprising.

### `SwiftUI/Extensions/NavigationPath.swift`
- No issues.

### `SwiftUI/Extensions/Environment.swift`
- **[Concurrency]** Multiple `nonisolated(unsafe) public static var defaultValue` declarations (lines 11, 16, 20, 24) — `unsafe` opt-out of isolation checking. For these (Bool, closure, Binding) consider `let` instead of `var`; `var` invites accidental mutation across threads.
- **[API]** `NavigationPathEnvironmentKey.defaultValue = Binding.constant(NavigationPath())` (line 16) — a default constant Binding silently swallows writes; reading the env value when no path is provided will surprise callers. Consider making it Optional.
- **[Platform]** `@Entry` on `namespace` (line 29) requires iOS 17+/macOS 14+ for `@Entry` macro; the availability `iOS 14` is too low — will fail to compile on older minimum deployments.
- **[API]** `var namespace: Namespace.ID!` IUO env value (line 29) — force-unwrap on read if not set; better as Optional.

### `SwiftUI/Extensions/App+Extensions.swift`
- **[Convention]** File contains only a single small enum; could collapse with related platform enums.
- No real issues.

### `SwiftUI/Extensions/TextField.swift`
- **[Convention]** File header still says "SwiftUIView.swift" (line 1) — stale.
- **[Bug]** Infinite recursion: optional `addTextContentType(_:)` (line 34) calls `self.addTextContentType(type)` (line 37) which is itself! Should call the non-optional overload — currently this calls itself recursively until stack overflow when a non-nil type is passed.
- **[Deprecated]** `.autocapitalization(...)` (line 52) is deprecated since iOS 15 in favor of `.textInputAutocapitalization(...)`.
- **[Platform]** `@available(macOS 14.0, *)` on a type-level extension (line 32) but file header allows iOS, where `textContentType` is available much earlier — adds an unnecessary iOS gate via the macOS-only annotation? Actually `@available(macOS 14, *)` only constrains macOS — okay but worth verifying.
- **[API]** `shouldAutocorrect`/`shouldAutocapitalize` switch (lines 73–93) duplicates logic; a shared helper would reduce drift.

### `SwiftUI/Extensions/Gradient.swift`
- No issues.

### `SwiftUI/Extensions/Color+Codable.swift`
- **[Bug]** `encode(to:)` silently encodes nothing if `hex` is nil (lines 27–29) — produces invalid container state and downstream decode errors. Should throw an `EncodingError`.
- **[Concurrency]** `@retroactive Codable` on `Color` (line 11) — fine, but Color is Sendable already; just note the cross-module retro-conformance.

### `SwiftUI/Extensions/AnimationCompletion.swift`
- **[Concurrency]** `MainActor.run { self.completion() }` inside `notifyCompletionIfFinished()` is called from `didSet` of an animatable property; `AnimatableModifier` is deprecated in favor of `Animatable` + `ViewModifier` (line 23).
- **[Deprecated]** `AnimatableModifier` is deprecated in iOS 17 in favor of `Animatable & ViewModifier`. Consider modern API or `withAnimation(_:completionCriteria:_:completion:)` (iOS 17+).
- **[API]** `onAnimationCompleted` is internal (no `public`) on line 17 even though the modifier is `@MainActor` and intended for external use.
- **[Bug]** `MainActor.run { ... }` from a non-async context inside a `@MainActor` modifier: it executes synchronously and can re-trigger the "modifying state during view update" warning the comment claims to avoid (line 50). The original intent was `DispatchQueue.main.async`. Calling `MainActor.run` while already on main runs synchronously — the comment is now wrong.

### `SwiftUI/Extensions/NavigationView.swift`
- **[Deprecated]** Uses `NavigationLink(isActive:)` throughout (lines 32, 56, 77) — deprecated in iOS 16. The whole API surface predates `NavigationStack`.
- **[Bug]** `OptionalNavigationLink` uses `$check.bool` (line 32) — if a binding extension returns `Binding<Bool>` from `Binding<Check?>` whose setter sets to nil on false, dismissing the link will null out `check`; on true with nil it does what? Verify behavior of the `bool` Binding extension.
- **[API]** `ContainedContentNavigationLink.onChange(of:)` (lines 85–87) uses old single-argument closure; iOS 17 deprecates this signature.
- **[Convention]** File approaching 92 lines — fine, but mixing several types together.

### `SwiftUI/Extensions/SceneState.swift`
- **[Concurrency]** Uses Combine `AnyCancellable` and `.sink` for state observation (lines 75–82) — violates "use async/await, not Combine" project rule. Should be replaced with `for await _ in NotificationCenter.default.notifications(named:)`.
- **[Concurrency]** `Task { @MainActor in self.objectWillChange.send() }` (line 95) inside a non-isolated closure captured by `.sink` — captures `self` strongly inside `cancellables`-stored closure which is held by `self`: classic retain cycle.
- **[Memory]** Retain cycle: `self.cancellables` stores closures that capture `self` (line 93–96) without `[weak self]`.
- **[Bug]** `StateChange.allOptions` (line 26) lists `.appEnterBackground` twice and omits `.appEnterForeground` — likely a copy-paste bug.
- **[Platform]** Whole file gated on `os(iOS)` only (line 14); could be ported using cross-platform notifications, but acceptable.

### `SwiftUI/Extensions/Font.swift`
- **[Convention]** Hard-coded dimension `size: 32` (line 11) — violates "avoid hard-coded dimensions" rule. Should derive from `.title`/`.largeTitle` or use a Dynamic Type relative size.
- **[Convention]** File header says "File.swift" (line 2).

### `SwiftUI/Extensions/Color.swift`
- **[Bug]** `init?(hex:)` (lines 21–28) calls `self.init(white: 0, opacity: 0)` *before* returning nil (line 23). For a failable initializer this is unnecessary and confusing — just `return nil`.
- **[Bug]** `Color.randomGray` uses `Double.random(in: 0...100.0)` (line 50) — `Color(white:)` expects 0...1. Produces a uniformly white color almost always.
- **[Platform]** `withFullOpacity` is duplicated across iOS and macOS blocks (lines 56–84); could be unified using `CrossPlatformKit`.
- **[Concurrency]** `static let rainbow: [Color]` (line 54) is fine but no `Sendable` constraint; should compile but worth tagging.
- **[API]** `hex` getter is duplicated in two `#if` blocks (lines 122–143 and 168–192) — drift risk.
- **[Convention]** File is ~194 lines, exceeds the ~100-line guideline; split per-platform helpers.

### `SwiftUI/Extensions/NavigationLink.swift`
- **[Deprecated]** `NavigationLink(isActive:destination:label:)` (line 42) — deprecated in iOS 16; should migrate to `navigationDestination`.
- **[Bug]** `BoundNavigationLink`'s `Binding(get: { bound != nil }, set: { _ in })` (line 42) — set is a no-op, so when SwiftUI tries to dismiss via the binding, the parent's `bound` never gets cleared; users can navigate but never programmatically pop via this binding.
- **[Concurrency]** `BoundNavigationLink` and `Wrapped` not `@MainActor` annotated — Views are MainActor by default in modern Swift but worth verifying.
- **[API]** No availability annotation on `BoundNavigationLink` (line 32) even though it uses `NavigationLink(isActive:)` (iOS 13+ ok).

### `SwiftUI/Compatibility/Compatibility.swift`
- **[API]** Stub that silently no-ops `navigationBarItems`/`navigationBarHidden` on macOS (lines 15–16) — accepts `Any?` for type erasure but doesn't actually warn callers their args are dropped. A logg() warning would help.
- **[Convention]** Uses `os(OSX)` instead of `os(macOS)` (line 12).

### `SwiftUI/Compatibility/iOS14Shims.swift`
- **[Deprecated]** Targeting iOS 14/15 shims; Suite already requires iOS 15+ per the iOS 15 deployment in package — these may be dead code, candidate for removal.
- **[API]** `alignedOverlay` fallback uses `HStack`/`VStack`/`Spacer` chains (lines 24–35) which is heavyweight; consider gating the whole API to iOS 15+ and dropping the fallback.

### `SwiftUI/Compatibility/NavigationTitle.swift`
- No issues.

### `SwiftUI/Utilities/TapGestures.swift`
- **[Convention]** File header lowercases the name "tapGestures.swift" (line 2).
- No real issues.

### `SwiftUI/Utilities/UnitRect.swift`
- **[Bug]** `UnitRect.init(origin:bottomRight:)` defaults `bottomRight` to `.bottomLeading` (line 64) — `.bottomLeading` is a UnitPoint at (0, 1) — produces a zero-width rect. Either no default or `.bottomTrailing` (1, 1).
- **[Bug]** `overlap(with:)` (line 88) — `bottomRight` y uses `max(bottom, other.bottom)` (line 92) where it should be `min` to clip to overlap; result is incorrect for height.
- **[Bug]** `union(with:)` similar logic concern, but actually correct (uses max for max edges).
- **[Bug]** `init(_ child: CGRect, in parent: CGRect)` (lines 69–78): when the parent doesn't contain the child, it returns `.full` (all ones) — odd fallback that hides programmer error. Consider returning a clamped or nil value.
- **[Convention]** File is ~152 lines, exceeds ~100-line guideline; split UnitSize / UnitRect / UnitPoint extensions.
- **[API]** `extension UnitPoint: @retroactive Codable {}` (line 132) splits Codable conformance from its method body — works, but the methods then live in a non-conformance extension; cleaner to keep them together.
- **[Suggestion]** `fileprivate extension CGFloat { var short: String }` (lines 113–117) is unused and dead.

### `SwiftUI/Utilities/PositionedLongPress.swift`
- **[Suggestion]** Entire file (lines 10–69) is commented-out deprecated code; should be deleted from version control rather than left in source.
- **[Convention]** File header references `PositionedLongPressGesture.swift` (line 2).

### `SwiftUI/Utilities/Tooltips.swift`
- **[Bug]** iOS overload calls `logg("Tooltips not supported on iOS")` *every time the modifier is applied* (line 15) — happens during view evaluation, so it logs on every recompose. Should be silent.
- **[Concurrency]** `TooltipView`/`Tooltip` are not `@MainActor` annotated; on macOS 14+ the strict concurrency may flag.
- **[Convention]** UIKit fallback present in tooltip pattern but acceptable since `NSHostingView`/`NSViewRepresentable` is the only way to bridge `toolTip:`.

### `SwiftUI/Utilities/Console.swift`
- **[API]** `Message` struct includes `error: Error?` but `Error` is not Sendable here (line 23) — `Message` will not be Sendable, which constrains use.
- **[API]** `writeToFile()` is a public empty stub (line 36) — half-implemented public API; either implement or hide.
- **[Concurrency]** `@Published var messages: [Message]` may grow unboundedly; no cap. Memory leak risk for long-running sessions.
- **[Convention]** Uses ObservableObject + @Published instead of `@Observable` (iOS 17+) — acceptable for back-compat.
- **[API]** `Console.print` shadows `Swift.print`, leading to confusing call sites.
- **[Convention]** `ConsoleView` uses hard-coded padding numbers (`padding(2)`, `width: 2`) on lines 60–61 — borderline.

### `SwiftUI/Utilities/SwipeActions.swift`
- **[Concurrency]** `MainActor.run(after: 0.01)` used to defer mutations (lines 41, 46, 58, 106) — this looks like GCD/delay usage hidden in a helper; violates "no GCD/queues" rule. Use `Task { try await Task.sleep(...); ... }` instead.
- **[Concurrency]** Three top-level `@MainActor private var` globals (lines 18–20): `currentCellCollapseBlock`, `currentCellID`, `activeCellID` — global mutable state used to coordinate between cells. Hard to reason about; should be wrapped in an actor or coordinator object.
- **[Bug]** `buildContent(in:)` (line 39) mutates `screenWidth` from inside a sync code path passed to `MainActor.run(after:)`; SwiftUI views are evaluated frequently, so this schedules work on every frame.
- **[Bug]** `buildContent` mutates state during body evaluation (line 41–50), which is the classic SwiftUI anti-pattern. Should be in `.onAppear`/`.onChange`.
- **[Convention]** File is ~158 lines; over guideline.
- **[Convention]** Mixed indentation — tabs and spaces inconsistent (lines 41, 46, 106).
- **[Deprecated]** `currentCellCollapseBlock`-based gestures: should consider native `.swipeActions` (iOS 15+).
- **[API]** Public extension method only exposes `addSwipeActions(trailing:id:)`; no leading variant despite the implementation supporting it (line 13).

### `SwiftUI/Utilities/ViewStorage.swift`
- **[Concurrency]** `@MainActor public class ViewStorage: ObservableObject` (line 14) but stores `AnyView`s (line 36, 50) — AnyView retention can capture closures and create retain issues.
- **[API]** `views` dictionary keyed by `String` rawValue, but a `[ViewKey: StoredView]` (Hashable rawRepresentable) would be more type-safe.
- **[API]** `lastStoredView` does `.values.sorted().last` (line 60) — O(n log n) when O(n) max would do. Minor perf nit.
- **[Suggestion]** `clear` and `store` manually invoke `objectWillChange.send()` (lines 46, 51) instead of marking `views` `@Published`.

## UIKit

### `UIKit/Error+UIKit.swift`
- **[Concurrency]** `display(in:title:)` uses `MainActor.run { ... }` (the project helper that fires-and-forgets a `Task`). The closure captures non-`Sendable` `UIViewController` and `Error`; under Swift 6 strict concurrency this will warn/error. Marking `display` itself `@MainActor` (or making it `async`) is cleaner than dispatching internally (line 15).
- **[API]** Method is named `display` but it silently no-ops if `controller` is nil. Consider making the parameter non-optional or renaming to `tryDisplay`.

### `UIKit/ScreenSize.swift`
- **[Suggestion]** Hard-coded device dimension table; many duplicates (e.g. iPhone15ProMax == iPhone14ProMax) and missing newer devices (iPhone 16, etc.). Maintenance burden. Consider deriving from runtime `UIScreen` traits.
- **[Perf]** `nearest(to:)` allocates `phones + pads` on every call (line 48). Cache the combined array as a static.
- **[Convention]** Not a violation but file is fine — under 100 lines.

### `UIKit/SelfContainedRefreshControl.swift`
- **[Concurrency]** `refreshed()` is `@objc` (called on main, fine), but it forwards the `closure` synchronously and then schedules a delayed `endRefreshing()`. Modern API: convert `closure` to an `async` closure and `await` it before calling `endRefreshing()`. Avoids passing completion handlers around.
- **[API]** Two distinct callers can mutate `closure`/`delay` on the existing refresh control (line 33-35), which is fine; but the convenience initializer also wires up `addTarget` only once — replacing the closure later via `addRefreshControl` works, but if someone constructs the class via `init()` and assigns `closure` directly, no target is wired. Document or guard.
- **[Memory]** `[ weak self]` capture is correct.

### `UIKit/UIAlertController.swift`
- No issues.

### `UIKit/UIApplication.swift`
- **[Deprecated]** Line 37 falls back to `self.windows.first` which is deprecated on iOS 15+. Should be removed entirely now that the `currentScene?.frontWindow` path covers iOS 13+. The `delegate?.window` fallback also relies on AppDelegate's `window` property which is rarely set in scene-based apps.
- **[Concurrency]** `UIApplication` access should be `@MainActor`. These computed properties are not annotated; under strict concurrency they'll warn. Mark the extensions `@MainActor`.
- **[Platform]** `currentScene` is gated on `iOS 13.0` only, but the file compiles on tvOS too where `UIScene` is also iOS 13+/tvOS 13+. Availability annotation should include tvOS/visionOS/Mac Catalyst for clarity.

### `UIKit/UIBarButtonItem.swift`
- **[Convention]** Hard-coded dimensions (`width: 44`, `height: 20`) — `width` is a parameter but the height is fixed. Acceptable since these are bar button defaults, but flag per CLAUDE.md guidance.
- **[Concurrency]** Should be `@MainActor`; touches UIView and Auto Layout.

### `UIKit/UIButton.swift`
- **[Bug]** `backgroundImage(_:for:)` ignores the `state` parameter and always passes `.normal` (line 50). Copy-paste bug.
- **[Concurrency]** Should be `@MainActor`.

### `UIKit/UICollectionView.swift`
- **[Suggestion]** `UICollectionViewCell.nib` assumes a XIB exists for every cell type (line 14); if there is no nib, `register(cellClass:)` will crash at runtime. The `UIView+Convenience` typically guards this.
- **[Concurrency]** Should be `@MainActor`.

### `UIKit/UIColor.swift`
- **[Bug]** `extractedHexValues` for `hex.count == 3` is wrong (lines 164-170). The 3-char form is "RGB" (each digit doubled) but the masks `0x000F00 >> 8`, `0x0000F0 >> 4`, `0x00000F` operate on a 12-bit value. The first mask drops the top nibble entirely — for input "F00" (rgbValue=0xF00), `(0xF00 & 0x000F00) >> 8 = 0xF/15 = 1.0`, which is correct. For "ABC" (rgbValue=0xABC), it yields A/15, B/15, C/15. Actually OK. But the **4-char "ARGB" branch is broken** (lines 172-179): `(rgbValue & 0x000F00) >> 12` always yields 0 because `0x000F00 >> 12 = 0`. The masks for the alpha-prefixed case are wrong, and the alpha is not divided by 15.
- **[Bug]** `hex.count == 8` shift: `(rgbValue & 0xFF000000) >> 24` — `rgbValue` is `UInt32`; the literal `0xFF000000` fits but the shift can lose precision in some configurations. Since `rgbValue` is `UInt32`, this works, but the more robust pattern is unsigned shift.
- **[Bug]** `hex` computed property: `r << 16 + g << 8 + b` — Swift's `<<` has higher precedence than `+`, so this evaluates as `(r << 16) + (g << 8) + b`. Correct, but easy to misread; parens recommended (line 93).
- **[Bug]** `convenience init?(hex:)` calls `self.init(white:alpha:)` THEN returns nil (lines 49-50). For a Swift convenience init, you must fully initialize before failing — calling another init then `return nil` is a compile error in Swift. Likely doesn't compile or has been working only due to weird forgiveness; verify. The standard pattern is to fail before any init call.
- **[Bug]** `luminosity` formula uses `0.2126 * r + g * 0.7152 + 0.0722 * b` — works but stylistically inconsistent (line 43).
- **[Concurrency]** `defaultText`, `secondaryText`, `tertiaryText`, `defaultBackground` static lets call dynamic colors like `UIColor.label` at process init; these are fine since `UIColor` lazy resolution is thread-safe, but they should ideally be computed properties or `@MainActor` accessors.
- **[Convention]** File is 250 lines — exceeds the ~100 line guideline. Split into UIColor+Hex, UIColor+Brightness, UIColor+Defaults, UIColor+Packed, etc.
- **[API]** Empty `public extension Int { }` block (lines 146-148) — dead code.
- **[Platform]** The "averageColor" extension is gated `#if os(iOS) || os(watchOS) || os(visionOS) || os(tvOS)` (line 201) which is essentially "any UIKit platform" — replace with `#if canImport(UIKit)` for consistency.
- **[Bug]** `unpacked:withAlphaStyle:` `.premultipliedLast` branch (lines 231-237) extracts components from the *wrong* bytes for ARGB-vs-RGBA. For premultipliedLast the byte order is RGBA; `unpacked >> 24` is the *first* byte (R), not alpha. The current code extracts as `a, b, g, r` from high to low which corresponds to little-endian RGBA word load. This is correct only on little-endian and only if the caller packed the bytes that way. Document the assumption.

### `UIKit/UIControl.swift`
- **[Concurrency]** Should be `@MainActor`.

### `UIKit/UIImage.swift`
- **[Deprecated]** `UIGraphicsBeginImageContextWithOptions`/`UIGraphicsEndImageContext` is the legacy API (lines 60-64, 80-89, 97-102, 110-114, 147-152). Apple recommends `UIGraphicsImageRenderer` (which is used elsewhere in this same file). Migrate `clipped(to:)`, `tintedImage`, `overlaying`, `resized(to:trimmed:scale:)` to `UIGraphicsImageRenderer`.
- **[Concurrency]** `overlaying(_:)` is `async` but the body calls `UIGraphicsBeginImageContextWithOptions` and `UIGraphicsGetImageFromCurrentImageContext` — these touch the *current* graphics context which is thread-local. If the function is called from a non-main task, the inner `await overlay.resized(...)` suspension can move execution between threads; the surrounding context can be lost. Wrap in `MainActor.run` or use `UIGraphicsImageRenderer` (which is thread-safe).
- **[Bug]** `resized(to:trimmed:scale:)` (lines 135-155): logic in lines 139-145 looks suspicious. After `within(limit:placed:.scaleAspectFit).rounded()`, you compare `frame.origin.x > 0` — but `scaleAspectFit` always centers, so origin will be `>= 0` for both axes. The branching to set `width` vs `height` based on which origin is `> 0` is a fragile heuristic for "which axis got letterboxed." Use `frame.size.width < limit.width` instead.
- **[Bug]** `UIImage(contentsOf:)` calls `self.init()` then `return nil` (line 41) — same Swift convenience init pattern issue as UIColor. Calling `self.init()` on `UIImage` may succeed (UIImage has a parameterless init returning an empty image), so this MAY compile, but it allocates a wasted object before returning nil.
- **[Convention]** File is 206 lines — exceeds guideline. Split into UIImage+IO, UIImage+Resize, UIImage+Drawing, UIImage+Generation.
- **[API]** `byRoundingCorners` returns `UIImage` (non-optional) but falls back to `self` if `create` fails — silent failure ok, but inconsistent with `clipped(to:)` returning optional.
- **[Concurrency]** `resized(to:trimmed:)` is `@MainActor` because of `UIView.screenScale`. But `UIView.screenScale` is a static let — it's accessed once. The `@MainActor` is unnecessary; just compute the scale eagerly. Marking image manipulation as `@MainActor` blocks off-main resize.

### `UIKit/UILabel.swift`
- **[Concurrency]** Should be `@MainActor`.

### `UIKit/UIScene.swift`
- **[Concurrency]** Should be `@MainActor`. `UIWindowScene.windows` is main-thread only.
- **[API]** `frontWindow` and `mainWindow` look almost identical; `mainWindow` filters by `windowLevel == .normal`, `frontWindow` by `isKeyWindow`. The naming is unclear; document the difference.

### `UIKit/UIStackView.swift`
- **[Concurrency]** Should be `@MainActor`.
- **[Bug]** `setup(inScrollView:withMargins:)` (line 13) sets `widthAnchor`, `centerXAnchor`, `topAnchor` but **not** `bottomAnchor`. The scroll view's content size will not be derived from the stack view's bottom, so vertical scrolling won't size correctly. Likely a bug.

### `UIKit/UITableView.swift`
- **[Concurrency]** Should be `@MainActor`.
- **[Bug]** `dequeueCell(type:indexPath:)` uses `as!` (force cast) on line 28 — will crash at runtime if the cell wasn't registered or the type doesn't match. Acceptable only with a precondition; consider `as?` with a more helpful crash message.

### `UIKit/UITextField.swift`
- **[Concurrency]** Should be `@MainActor`.

### `UIKit/UITraitCollection.swift`
- No issues.

### `UIKit/UIView+BlockingView.swift`
- **[Memory]** `removeBlockingView(duration:completion:)` captures `self` strongly in two animation closures (lines 20-25). For long durations or if the view is removed mid-animation, this retains `self` until the animation completes. Use `[weak self]`.
- **[Concurrency]** Should be `@MainActor`. Also, `tappedClosure` and `excludedRects` are stored properties on a `UIView` subclass — which means they're touched only on main. Fine, but mark the class explicitly.
- **[API]** `blockingView(excluding:tappedClosure:)` returns `UIView` not `SA_BlockingView` — caller can't access excluded rects after creation without casting (line 28).
- **[Bug]** `blockingView` getter loops through subviews and returns the first `SA_BlockingView`, but if multiple exist (e.g. due to race or programmer error) this hides the issue. Minor.

### `UIKit/UIView.swift`
- **[Deprecated]** `UIScreen.main.scale` (line 17) is deprecated in iOS 16+. Use the trait collection's `displayScale` from a window/scene. Critical because `screenScale` is a static let computed at first access and cached forever — if the app is multi-screen (iPad with external display) this will be wrong.
- **[Concurrency]** Static let `screenScale` evaluates `UIScreen.main.scale` lazily — accessing it from a background thread on first access would crash. Mark the whole extension `@MainActor`, or eagerly compute on a main-thread init.
- **[Concurrency]** `isResigningFirstResponderOnAll` is a `static var` — non-isolated mutable global state. Data race. Either mark `@MainActor` or use a lock.
- **[Bug]** `frontSafeAreaInsets` chain (line 45) walks `currentScene?.frontWindow?.rootViewController?.view.safeAreaInsets`. If the front window's root is a navigation/tab controller, the topmost visible view's safe area may differ from root's. Acceptable approximation; document.
- **[Convention]** File is 230 lines. Should be split (e.g. UIView+Builder, UIView+Activity, UIView+Image).
- **[Memory]** `viewController` walks `responder.next` with a `responder!` force-unwrap (line 54) inside a `while responder != nil` loop — safe because the loop guard ensures non-nil, but `responder?.next` is cleaner and matches Swift idiom.
- **[Bug]** `addActivityView(color:)`: constraint orientation is reversed — `self.centerXAnchor.constraint(equalTo: spinner.centerXAnchor)` (line 85) is written backward. This works mathematically (equality is symmetric) but is non-idiomatic; usually reads `spinner.centerXAnchor.constraint(equalTo: self.centerXAnchor)`.
- **[Bug]** `rotatedBy(degrees:)` formula `(angle * .pi * 2) / 360` is just `angle * .pi / 180`; the current form is `angle * 2π / 360 = angle * π / 180`, which is equivalent — OK but unnecessarily obfuscated (line 149).

### `UIKit/UIViewController.swift`
- **[Bug]** `fromStoryboard()` force-unwraps `components(separatedBy: ".").last!` (line 14). Class names always contain a dot for Swift classes, so this works, but for `@objc` Obj-C-style classes registered without a module prefix (e.g. legacy code) `last!` returns the whole string — not actually a crash, but worth noting.
- **[Bug]** `fromStoryboard(class:name:bundle:)` uses `instantiateInitialViewController()` which returns optional, then force-casts via `as! T` (line 22). Crash if storyboard has no initial VC or wrong class. Minor.
- **[Bug]** `fromXIB`: passes `bndle` as `bundle:` but `nibName` defaults to `self.nibName` (the class var defined below). If `nibName` is nil and the user didn't override, `init(nibName: nil, bundle:)` will look for a XIB with the same name as the class — UIViewController's default behavior. OK but worth a comment.
- **[Concurrency]** Extensions should be `@MainActor`.
- **[Platform]** `share(something:...)` is gated `#if !os(tvOS)` and uses `UIApplication.shared.currentWindow?.rootViewController?.presentedest.view`. On Mac Catalyst, this works; visionOS is excluded via the parent file's gate. Looks fine, but `UIActivityViewController` is unavailable on visionOS — verify the surrounding `#if`.
- **[API]** `presentedest` typo-ish; suggest `topPresentedViewController` (line 55).

## Combine & Async

### `Combine & Async/AsyncFlag.swift`
- **[Bug]** `wait()` is fundamentally broken. Line 32 creates an `AsyncStream(unfolding: { })` whose unfolding closure returns `Void` immediately (since `() -> Void?` returning `()` is implicit `Optional.some(())`), so the inner `for await` will spin forever yielding without ever observing a signal — and `isFlagSet` is never re-checked while suspended on the actor's stream. It does not actually use `self.stream` or `self.continuation`. `wait()` never sees the flag set; this is a busy/infinite loop.
- **[Concurrency]** `init` spawns a `Task` to call `setupContinuation()` (line 16). Until that task runs, `continuation` is `nil`, so any `setFlag(...)` call early on does nothing — initial state is racy.
- **[Concurrency]** Only one `AsyncStream` continuation is created — multiple concurrent `wait()` callers will share/clobber it. The whole design needs rethinking; consider `withCheckedContinuation` array, or a `CheckedContinuation` set, or just `AsyncSemaphore`.
- **[API]** `setFlag(to:)` does not signal/yield when set to `false`. Naming/behavior is unclear: should the flag be one-shot or resettable?
- **[Suggestion]** Replace this entire type with a small actor that stores `[CheckedContinuation<Void, Never>]` and resumes them on `setFlag(true)`.

### `Combine & Async/AsyncSemaphore.swift`
- **[Convention]** 240+ lines — well over the ~100-line guideline. Could split `Suspension`, `wait`, and `waitUnlessCancelled` into separate files.
- **[Bug]** `suspensions.insert(at: 0)` + `popLast()` (lines 124, 174, 227) — comments say "FIFO" but inserting at 0 and popping from the end gives LIFO order. Either the comment or implementation is wrong; based on intent the comment is right but you should pop first or insert at end.
- **[Suggestion]** Attribution is good (groue/Semaphore). Otherwise sound.

### `Combine & Async/Binding.swift`
- **[Convention]** Line 85-86: ugly multi-line declaration of `inverted` with closing `}) }` jammed together; reformat for readability.
- **[API]** `Binding(_ boolProvider:)` (line 88) constructs a Binding with no setter — silently swallows writes. This can be surprising; consider naming `init(get:)` or document loudly.
- **[Suggestion]** `bool(default:)` on line 59 — missing space before `{`.

### `Combine & Async/CurrentValueSubject.swift`
- **[Concurrency]** `extension CurrentValueSubject: @unchecked @retroactive Sendable` — broad retroactive Sendable conformance on an Apple type can collide if Apple later marks it Sendable; works but flagged as fragile.
- No other issues.

### `Combine & Async/Debouncer.swift`
- **[Concurrency]** `Value: Sendable` is good, but `Debouncer` is `@MainActor` while sink callback runs on RunLoop.main and dispatches a `Task { @MainActor in ... }` — this introduces an unnecessary hop. Since the sink already runs on RunLoop.main, you could call `MainActor.assumeIsolated` or restructure as an async sequence.
- **[Memory]** `[weak self]` in sink + `Task { @MainActor in self.output = ... }` (line 31) captures `self` strongly inside the Task closure (`self.output`), but since `guard let self` already extracted a strong ref this is fine; just noting the closure isn't visibly weak inside.
- **[API]** `setInput(_:withoutDebounce:)` only sets `output` when bypassing — but doesn't cancel the existing debounce, so a previously queued debounced value can still arrive after the bypass. Consider cancelling/restarting the pipeline on bypass.
- **[Convention]** Stray spaces in `.debounce (for: . seconds (delay), ...)` (line 28).

### `Combine & Async/Loadable.swift`
- No issues.

### `Combine & Async/ObservableObjectPublisher.swift`
- **[Memory]** `ObserverMonitor` stores `cancellable` as a struct property and assigns inside `init`. Because `ObserverMonitor` is a `View` (struct, value type) created on each render, the cancellable is recreated every render and the previous one is dropped — leaks/duplicate logging are likely. Subscriptions like this don't belong on a `View` struct; use `.onReceive`/`.task` or a `@StateObject` wrapper.
- **[API]** `monitor(message:)` on line 60 calls `eraseToAnyPublisher().onSuccess()` but discards the resulting subscription — the `Subscribers.Sink` will be released immediately. This is broken.
- **[Concurrency]** `sendOnMain()` uses `Thread.isMainThread` then `MainActor.run` synchronously from arbitrary contexts — `MainActor.run` is async and not called via `await`; this likely doesn't compile under strict concurrency or silently ignores the call. Verify.
- **[Convention]** Mixed availability annotations (`OSX 11` vs `macOS 11`).

### `Combine & Async/ObservableObserver.swift`
- **[Memory]** `target.objectWillChange.sink { _ in self.update() }` (line 22) — strong-captures `self`, retain cycle: `self` -> `cancellable` -> closure -> `self`. Use `[weak self]`.
- **[Concurrency]** `check: () -> Bool` is not marked `@Sendable` and the class is `@MainActor` — fine in practice but the closure stored is non-Sendable if the type is later relaxed.
- **[API]** `target` parameter is unused after init (only `target.objectWillChange` captured) — fine, just noting.

### `Combine & Async/Observables.swift`
- **[Memory]** `NotificationWatcher` adds an observer with `forName:object:queue:` block API but never removes it, and never stores the observation token — this leaks the observer (it's tied to `self`'s lifetime via NotificationCenter's strong reference internally; the watcher never dies). Capture token and remove in `deinit`.
- **[Concurrency]** Closure on line 13 captures `self` strongly; classic notification-leak pattern.
- **[API]** `PokeableObject` is fine but trivial — could just be `final class`.

### `Combine & Async/Publishers.swift`
- **[Memory]** `onCompletion`, `onSuccess`, `onFailure` (lines 63, 73, 84) call `subscribe(Subscribers.Sink(...))` without storing the cancellable. The sink's lifetime depends on the upstream retaining it; for a finite publisher this works, but for a long-lived publisher these can be released early. Even so, returning `AnyCancellable` would be safer.
- **[Bug]** `withPreviousValue()` (lines 92-98) force-unwraps `$0.new!` — the very first scan emits `(nil, nil)`, so the first map will crash. You probably want to drop the initial tuple via `.compactMap` or filter where new is non-nil.
- **[API]** `sink(_:completed:receiveValue:)` shadows `Combine.sink` and changes argument labels — call sites can be ambiguous.

### `Combine & Async/Subscription.swift`
- **[Concurrency]** Global `var SubscriptionBag` annotated `@MainActor` — works under strict concurrency, but a single global bag means cancellables are never freed unless rotated by key. Method ignores `key` (line 19) — `sequester(_ key:)` doesn't actually use the key. Misleading API.
- **[API]** `key` parameter is dead. Either implement keyed storage (dictionary of sets keyed by key) or remove the parameter.

## AppKit

### `AppKit/NSAlert.swift`
- **[Concurrency]** `MainActor.run { ... }` on line 16 inside a non-async function is incorrect — `MainActor.run` returns an async closure result. This compiles only with implicit discard; under strict concurrency this is a warning/error. `Task { @MainActor in ... }` would be correct.
- **[API]** `showAlert` and `show(in:completion:)` don't expose a `default`/`cancel` button distinction nor return a value; consider an `async` variant.
- **[Convention]** Multi-line function signature on line 14 is borderline.

### `AppKit/NSApplication.swift`
- **[Concurrency]** `DisableSleep` is `@MainActor`, but `NSApplication.sleepDisabled` set/get accessors aren't isolated — calling from non-main contexts will blow up. Mark the extension property `@MainActor` or guard.
- **[Bug]** `disableScreenSleep` reuses `sleepDisabled` as both "should be disabled" and "successfully disabled" (line 37). If `IOPMAssertionCreateWithName` fails, `sleepDisabled` stays `false` which is OK, but `assertionID` may have been written. Acceptable but a clearer second flag would help.
- **[Convention]** File is fine size-wise.

### `AppKit/NSButton.swift`
- No issues.

### `AppKit/NSColor.swift`
- **[Bug]** `convenience init?(hex hexString: String?)` (line 15) calls `self.init(white: 0, alpha: 0)` then returns `nil` — calling a designated init then returning nil is allowed for failable inits, but the work of initializing is wasted. Cleaner: `self.init(white: 0, alpha: 0); return nil` is the correct pattern; just noting.
- **[Bug]** `hex` getter (line 58): `r << 16 + g << 8 + b` — Swift operator precedence: `<<` is *lower* than `+`, so this evaluates as `r << (16 + g) << (8 + b)`. Definitely a bug. Add parens: `(r << 16) + (g << 8) + b` or use `|`.
- **[Bug]** `hexString` does not include alpha but `init?(hex:)` accepts 4 components — round-tripping via hexString loses alpha. Inconsistent.
- **[API]** `luminosity` (line 76): does not convert to sRGB first (unlike `brightness`), so values are colorspace-dependent — inconsistent with `brightness`.

### `AppKit/NSEvent.swift`
- No issues.

### `AppKit/NSView.swift`
- **[Bug]** `backgroundColor` getter accesses `self.layer?.backgroundColor` without `wantsLayer = true` — fine, returns nil if no layer, but setter sets `wantsLayer = true` while getter doesn't. Asymmetric.
- **[Convention]** `if #available(OSX 10.14, ...)` always true since deployment is 10.15+. Dead branch.

### `AppKit/PasteboardMonitor.swift`
- **[Bug]** Line 42: `addObserver(forName:...)` closure parameter shadowed as `timer` — should be `_ in` or `note in` (it's a Notification, not a Timer). Confusing typo.
- **[Memory]** Notification observer token is never stored and never removed; the `MainActor`-isolated singleton leaks an observer reference. Since this is a singleton with `static let instance`, this is acceptable in practice, but if anyone instantiates more `PasteboardMonitor`s, leaks ensue. Consider `private init` to enforce singleton.
- **[Memory]** Same for `Timer.scheduledTimer` — never invalidated unless `self` is nil. With singleton lifetime this is fine.
- **[Perf]** Polling every 1s for pasteboard is wasteful when the app is backgrounded. Consider only polling while frontmost (you already observe activation; you could stop the timer on resign-active).
- **[API]** `init(pollInterval:)` is `public` but the type is documented as a singleton (`static let instance`) — second instances are possible and dangerous given the shared observer/timer. Make `init` private.
- **[Concurrency]** `Timer.scheduledTimer` block runs on the main runloop; calling `Task { @MainActor in self.checkForChanges() }` is unnecessary indirection — within main runloop you're already on main thread; can call directly with `MainActor.assumeIsolated`.

## Cocoa

### `Cocoa/ErrorHandling.swift`
- **[Concurrency]** `@MainActor extension Error` adds main-actor isolation to `display(...)`. The `completion` is `@Sendable` but the closure passed to `beginSheetModal` captures it without crossing actors — fine under main actor, but the modal `runModal()` blocks the main thread, which is exactly what main-actor isolation is supposed to discourage.
- **[Suggestion]** Extracting an async variant `func display(in:) async -> Int` would be much nicer than a completion handler.
- **[Convention]** Logic is duplicated for sheet vs modal — extract a `finish(_:)` like NSAlert.swift does.
- **[Platform]** `#if !canImport(UIKit)` is brittle — Catalyst can import both. Prefer `#if canImport(AppKit) && !targetEnvironment(macCatalyst)` for consistency with neighboring files.

### `Cocoa/NSImage.swift`
- **[Concurrency]** `scaledImage(newSize:)` uses `lockFocus()`/`unlockFocus()` — these are main-thread only, but the function is not `@MainActor`. Will misbehave off the main thread.
- **[Bug]** In `resized(to:trimmed:changeScaleTo:)` the `changeScaleTo` parameter is accepted but never used (line 26).
- **[Convention]** Trailing semicolons on lines 36, 37, 44 (`frame.origin.x = 0;`) — non-Swift style.

### `Cocoa/NSTextFieldAndView.swift`
- **[Convention]** `editabled(_:)` (line 42) — typo, should be `editable(_:)`.
- No other issues.

### `Cocoa/NSView+Helpers.swift`
- **[Bug]** `fullyConstrain(to:)` (line 116): top constant is `23` instead of `0`. Almost certainly a leftover/typo — it asymmetrically inset the top.
- **[Bug]** `rotatedBy(degrees:)` (line 53): `(angle * .pi * 2) / 360` — that's `angle * pi/180`? Let's check: `angle * pi * 2 / 360 = angle * pi / 180` ✓. OK, correct, just confusingly written. Suggestion: write as `angle * .pi / 180`.
- **[Convention]** Filename mismatch: file is `NSView+Helpers.swift` but file header comment says `NSView.swift`. Also there's another file `AppKit/NSView.swift` — possible duplication/confusion.
- **[Suggestion]** Commented-out code on lines 91-99 should be removed.

## Geometry

### `Geometry/CGAngle.swift`
- **[Bug]** `angle` formula uses sides `ab`, `bc`, `ac` and computes the angle at vertex `B` via `acos((ab^2 + bc^2 - ac^2) / (2*ab*bc))`. That is the law of cosines for angle at B (opposite side `ac`) — correct math, but the type is named `CGAngle` with three points `a, b, c`, and there is no doc clarifying which vertex's angle is computed. **[API]** Misleading: a consumer could reasonably expect the angle at `a` or `c`. Add documentation or rename.
- **[Bug]** No protection for degenerate cases: if `a == b` (`ab == 0`) or `b == c` (`bc == 0`), denominator is 0 → NaN/inf. If the law-of-cosines argument falls outside `[-1, 1]` (floating point), `acos` returns NaN. Should clamp or guard.

### `Geometry/CGContext.swift`
- **[Convention]** 152 lines — exceeds the ~100 LOC guideline. Split UIImage/CGContext/CGImage extensions into separate files.
- **[Bug]** `buildContext` constructs the context with `bytesPerRow: Int(self.size.width * 4)` using `size` (points), not `cgImage.width` (pixels). On a Retina display this allocates a buffer at point dimensions while the cgImage is in pixels — drawing will scale or fail. Use `cgImage.width / .height` and `bytesPerRow` aligned to pixels.
- **[Bug]** `bytes` capacity is `height * bytesPerRow * 4` — `bytesPerRow` already includes the 4 bytes-per-pixel; correct capacity is `height * bytesPerRow`. Same on `uint32s` capacity uses `height * bytesPerRow` (which actually is 4× too large for UInt32). Both bindings are wrong by a factor of 4.
- **[Bug]** `data.withMemoryRebound(to: UInt32.self, capacity: height * pixelsPerRow) { data in return data }` returns the temporary pointer outside the closure — undefined behavior; the rebinding is only valid within the closure scope.
- **[Bug]** `contentFrame` logic is broken: when a new x/y is encountered, it only widens the rect if x > maxX or x < minX, but never accounts for points strictly inside the running rect. Worse, after the first point sets origin, the second point that is greater than origin.x is always > maxX (maxX = origin.x + 0), so width grows by absolute pixel index rather than delta — width ends up incorrect. Rework using running min/max.
- **[Bug]** `alphaOfPixelAt` for `.premultipliedFirst` reads byte at `offset` (which is the alpha first byte) but then returns `255 - byte`. That inversion is wrong — alpha-first means the first byte IS alpha; no inversion needed.
- **[Perf]** Brute-force O(width × height) scans on the main pixel buffer; on big images this is heavy. Consider early bail-out optimizations or note in docs.
- **[Convention]** Indentation is irregular (mixed leading-spaces and tabs).

### `Geometry/CGFloat.swift`
- **[API/Bug]** `shortDescription` uses `"%.0f"` which truncates everything to integers (e.g. 3.7 → "4", 0.001 → "0"). Name suggests "short" rather than "integer rounded"; misleading.

### `Geometry/CGLine.swift`
- **[Convention]** 229 lines — exceeds the ~100 LOC guideline. Could split (StringInitializable, Hashable, intersection helpers).
- **[Bug]** `Equatable`'s `==` uses approximate equality (`≈≈`) but `hash(into:)` hashes exact `start` and `end`. Two equal-by-`==` lines can have different hashes — violates `Hashable` contract.
- **[Bug]** `init(start:length:angle:)`: the `while degrees > 360` loop will not handle `degrees == 360` correctly (loop runs once, becoming 0), and the comparisons against `90/180/270/360` use exact float equality on a value that may have been produced by repeated subtraction — small floating point errors will fall into the trig branch instead. Use `truncatingRemainder(dividingBy: 360)` and tolerance comparisons.
- **[Bug]** `slope` divides by `vector.x`; will be `inf`/NaN for vertical lines — no guard. Caller must know.
- **[Bug]** `quadrant` returns 1 when `dy <= 0`, 2 when `dy > 0`, etc. — but lines exactly on an axis (dx == 0 or dy == 0) are mapped silently into one of the four quadrants, which then feeds `angle`. That branch is reached only after the early-return for `vector.x == 0` / `vector.y == 0` in `angle`, so okay there, but `quadrant` itself is misleading on its own.
- **[Bug]** In `angle`: `case 1: return .degrees(360) - .radians(basis.radians * -1)` simplifies to `360° - (-basis)` = `360° + basis`. This goes outside `[0, 360)` whenever basis is positive, and in quadrant 1 (dx>0, dy<0 in this code's flipped Y) the expected angle is `360° - |basis|`, which is `.degrees(360) + basis` only if `basis` is negative — fragile and confusing. Verify and add tests.
- **[Bug]** `linesCross`: uses `> 0 && < 1` (strict) which excludes intersections exactly at endpoints. The pre-checks at the top of `intersection(with:)` only handle pairwise endpoint equality, not "line A endpoint sitting on line B's interior." Edge cases will return `nil`.
- **[Bug]** `init?(rawValue:)` calls `rawValue.trimmingCharacters(in: .decimalDigits.inverted)` — this strips commas, parentheses and minus signs, breaking negative coordinates and the `(...,...)` separator. Likely doesn't actually parse the format produced by `stringValue`.
- **[Bug]** `midpoint` setter uses old `midpoint` after computing `startDelta`/`endDelta`; reads `midpoint` again to compute `endDelta`. The math: `start = newValue + (midpoint - start)` translates start to `newValue + (midpoint - start)` rather than `start + (newValue - midpoint)`. End up shifting both points by the wrong delta unless the line is symmetric about midpoint. Rewrite as `let delta = newValue - midpoint; start += delta; end += delta`.

### `Geometry/CGPath.swift`
- **[Bug]** `boundingSize` force-unwraps `xs.max()!` / `ys.max()!` after checking `points.isEmpty`. Safe given the guard, but minor.
- **[Suggestion]** Could use `applyWithBlock` to compute bounds without materializing a `[CGPoint]`.

### `Geometry/CGPoint.swift`
- **[Bug]** `nearestPoint(on:)` sets `distanceFactor = -1` for zero-length lines, then early-returns `line.start` — which is correct (line.start == line.end here). But the `< 0` and `> 1` clamps for non-degenerate lines correctly clamp to endpoints. Looks ok.
- No major issues.

### `Geometry/CGRect.swift`
- **[Convention]** 320 lines — exceeds the ~100 LOC guideline by a lot. Split (Placement enum/extension, layout helpers, parsing).
- **[Bug]** `roundcgf` uses `floorf(Float(value))`. Going through Float drops precision for large CGFloats (CGFloat is Double on all modern platforms). Use `floor(value)` or `value.rounded(.down)`.
- **[Bug]** `rounded()` formula: `width: roundcgf(value: self.width + (self.origin.x - roundcgf(value: self.origin.x)))`. Because `roundcgf` floors, `(origin.x - floor(origin.x))` is the fractional part — fine for adjusting width — but then the outer `roundcgf` floors *again*, which can shrink the rect by 1 unit. For a typical "snap to integer pixels and grow to cover" you'd want to floor origin and ceil maxX. As written, content can fall outside the rounded rect.
- **[Bug]** `allPoints` uses `Int(...)` truncation; for negative origins it rounds toward 0, missing pixels. Loops `Int(upperLeft.y)..<Int(lowerRight.y)` — if rect height is 0.7, this is empty; if origin is 0.6 and lower is 1.6, you get only y=1. Inconsistent rounding. Also memory-heavy for large rects.
- **[Bug]** `Comparable` conformance compares by `area`. Two rects with equal area are not equal-by-`==` (CGRect.==), but `<` returns false in both directions, implying equality — violates strict weak ordering when used with `Hashable`/`Equatable` invariants on Comparable.
- **[Bug]** `within(limit:placed:)` — `.scaleAspectFit` branch mutates `newSize` then uses it, but earlier `newRect = parent` is overwritten; `newRect` final assignment uses `parent.width / .height` for centering coordinates, not `parent.origin.x + ...`. If the parent has non-zero origin, the result is wrong. Same in `.scaleAspectFill`.
- **[Bug]** In `.center`: it inset the running `newRect` (already scaled-down) but then re-clamps `size.height/.width` with `min(limit.height - insetY*2, self.height)`. The clamp uses `self.height` (the original child) not `newRect.height`, which can re-expand the rect beyond what the previous scaling decided.
- **[Convention]** A massive switch with `default: break` after `.scaleToFill: return parent` returning early — fine, but consider an enum-driven approach.

### `Geometry/CGSize.swift`
- **[Bug]** `scaleDown(toWidth:height:)` has obvious typos: in the second `if` (`maxWidth < self.width`), it sets `heightGood = true` instead of `widthGood = true`. As a result `widthGood` is *never* assigned and the function's logic is broken in nearly all branches. The early-return `heightGood && widthGood` is also unreachable.
- **[Bug]** `aspectRatioType`: `case ..<1: return .portrait` — if width or height is 0/NaN you get NaN, which falls into `default: .landscape`. Edge case bad classification.

### `Geometry/UnitPoint.swift`
- **[Platform]** `UnitPoint` is a SwiftUI type but the file imports only Foundation. Likely compiles via implicit re-export, but should `import SwiftUI` for clarity.

### `Geometry/Vector2.swift`
- **[Bug]** `init?(rawValue:)` parses `components[0]` for both `x` and `y` — typo, should use `components[1]` for `y`. Round-trips never produce correct values for `y`.
- **[Bug]** Same `trimmingCharacters(in: .decimalDigits.inverted)` issue as CGLine — strips minus signs and decimals' separators.
- **[Bug]** `Hashable` extension on `Vector2` defines `hash(into:)`, but it's a protocol extension, so concrete types like `CGPoint`/`CGSize` that already conform to `Hashable` use their own conformance — this protocol-extension hash is dead code. Confirm intent.
- **[Bug]** `≈≈` operator on `Vector2` compares using `isRoughlyEqual` (distance < eps). That's fine, but `CGLine` uses `≈≈` between `CGPoint`s and the protocol-witness is selected at compile time — generic dispatch should work.

## Logging

### `Logging/Logger.swift`
- **[Bug]** `static let suiteLoggerSubsystem = Bundle.main.bundleIdentifier! + ".suite"` force-unwraps `bundleIdentifier`. In test bundles, command-line tools, and some app extensions this is `nil` and crashes at module load.
- **[Convention]** Top-level `let SuiteLogger` capitalized as if a type; might shadow the legacy `SuiteLogger` class in `SuiteLogger.swift` — confusing dual naming. Actually the legacy one is named `OldSuiteLogger`, so no shadow, but the global variable named `SuiteLogger` is then referenced from `ModelContext.swift` (`SuiteLogger.error(...)`) — works only if iOS 14 / macOS 12 are available. Add doc comment.
- **[Concurrency]** `let SuiteLogger = Logger(...)` at file scope is fine for `os.Logger` (Sendable), but file-internal `let` global is technically OK in Swift 6 only because Logger is Sendable.

### `Logging/Slog.File.swift`
- **[Convention]** 183 lines — over the ~100 LOC guideline. Already split via Slog.File / Header / Line; could be split further.
- **[Bug]** `save()` rewrites the entire file every time `record(_:)` is called. Each log line costs full re-encode + write — O(n²) over a session. Use append-mode `FileHandle` like the legacy logger.
- **[Bug]** `save()` uses `try data.write(to: url)` without `.atomic` — if the app is killed mid-write, the file can be left truncated/corrupted. Use `.atomic`.
- **[Bug]** `Line.init?(rawValue:)` uses `delimiter = "/"` and splits on every `/`. Any log message containing `/` is mis-parsed. Also `init?` joins back via `dropFirst().joined(separator: delimiter)` only after color detection — but color detection uses `components[2]` which assumes message has no `/`. URLs in messages will be broken. Use a delimiter unlikely in messages, or escape.
- **[Bug]** `Header(rawValue:)` parses on `delimiter` but `iso8601` formatter strings often contain `:`; if it ever contains `/` (some locales / formatters), header is unparseable. Also: `DateFormatter.iso8601` is presumably defined elsewhere — make sure timezone is fixed.
- **[Bug]** `Line.id = UUID()` is regenerated on every decode, causing SwiftUI list diffing to churn whenever lines are reloaded.
- **[Concurrency]** `nonisolated func removeLog()` removes the file while the actor may be writing — race. Should be actor-isolated.
- **[Memory/Perf]** `lines: [Line]` accumulates indefinitely in memory. No rotation or cap.
- **[Bug]** `extractedHeader(from:)` reads `data.prefix(400)` then strings only `data.prefix(200)` of that — typo of intent? Also `URL.init(contentsOf: options: .mappedIfSafe)` requires the URL be a file URL — okay here, but no error logging.

### `Logging/Slog.swift`
- **[Bug]** `disabled = true` by default. With no public way to enable on `instance` other than `setEnabled`, the actor swallows all `record` calls silently until enabled. Document or default to enabled.
- **[Concurrency]** `slog(_:color:)` fires `Task { ... }` with no ordering guarantee — log lines can land out of order. Use a serial queue/actor pattern that preserves order, or document.
- **[Convention]** `let logger = Logger(subsystem: "suite", category: "general")` is initialized but never used — dead code.
- **[Bug]** `setEchoCallback` keeps a `@MainActor (String) -> Void` closure that may capture `self` of the caller — leak risk if not cleared. Document `clearEchoCallback`.
- **[Concurrency]** `printLogs = Gestalt.isAttachedToDebugger` reads at actor init off any task; if `Gestalt` is `MainActor`-isolated, this would race. Verify.

### `Logging/SlogButton.swift`
- **[Convention]** Filename header says "File.swift" — copy-paste leftover.
- **[Platform]** `#if os(iOS) || os(macOS)` excludes watchOS/tvOS/visionOS; SlogScreen has same gating, ok.

### `Logging/SlogScreen.swift`
- **[Bug]** `Picker` selection of `Slog.File?` with `Optional.some(file).tag(...)` will not have a tag for `nil` — picker may be in undefined state when current is `nil`. Add a `.tag(Slog.File?.none)` row or supply a Sentinel.
- **[Bug]** "Clear Log" calls `current.removeLog()` (nonisolated) immediately, but if the current file is the actively-logging `Slog.instance.file`, the actor will continue writing and resurrect the file. Should also clear/replace the active file.
- **[Bug]** `files.remove(current)` — relies on `Hashable`/`Equatable` on `Slog.File` (an actor). Actors are Equatable/Hashable here via custom impl (`==` on URL), good.
- **[Concurrency]** `current = await Slog.instance.file ?? files.first` — fine.

### `Logging/SlogView.swift`
- **[Bug]** `await file.load()` early-returns when `lines` is non-empty (see Slog.File.load), which is not communicated; on second `onChange`, you may show stale data. Maybe intended.
- **[Convention]** `ForEach(lines.indices, id: \.self)` is anti-pattern; use `ForEach(lines) { line in ... }` with `Identifiable` (Line conforms). Index-based ForEach breaks animation on insertion.

### `Logging/SuiteLogger.swift`
- **[Convention]** 169 lines — over the ~100 LOC guideline.
- **[Concurrency]** `OldSuiteLogger` is `@unchecked Sendable` with `var fileURL`, `var prefix`, `var showTimestamps`, `var redirected`, `var level` — all mutable from any thread without locking. Only `log(_:level:)` takes the lock. Race conditions on every other accessor.
- **[Memory]** `_lock` is allocated but never `deinitialize`d / `deallocate`d (singleton is forever, so OK in practice).
- **[Bug]** `write(_:to:)` opens `FileHandle(forUpdating:)` for every line of output — costly. Also, on error code `4` it sets `logFileExists = false` and silently drops the message; for any other error, recurses into `OldSuiteLogger.instance.log(error:...)` which will call `write` again and could infinite-loop on persistent failure.
- **[Concurrency/Convention]** Uses GCD-style file APIs (FileHandle synchronously), but no async/await. Project guideline: use async/await.
- **[Bug]** `force-unwrap` `"\n".data(using: .utf8)!` and `"".data(using: .utf8)!` — safe in practice but `try?` would be cleaner.
- **[API]** All public globals (`logg`, `dlogg`, etc.) lack documentation and there are many overloads with subtle behavior differences (e.g., `dlogg(_ msg:)` is identical to `logg(_ msg:)`).
- **[Bug]** `logg<Failure>(completion:)`: prints only on `.failure`, but `.finished` case falls through silently. Document.
- **[Bug]** `level` lazy var reads `Gestalt.distribution` and `Gestalt.isAttachedToDebugger` at first use; if invoked off main actor where Gestalt requires it, could deadlock or race. Verify Gestalt's isolation.
- **[Concurrency]** `@preconcurrency import CoreData` masks Sendable warnings; the `NSManagedObject.logObject` extension uses `dlogg(desc, level)` capturing `self` indirectly — fine but worth noting.

## Property Wrappers

### `Property Wrappers/CodableAppStorage.swift`
- **[Bug]** Uses `store.synchronize()` — Apple has long deprecated/recommended against this; it's a no-op on modern systems but unnecessary noise.
- **[Bug]** When `JSONEncoder().encode(newValue)` succeeds but the value is `Optional.none` represented as `null`, the code stores the string `"null"` rather than removing the object. The fallback `removeObject(forKey:)` only triggers on encoding failure, not on null content. Optional initializer's intent is broken.
- **[Bug]** Initial load via `store.object(forKey:) as? String` — if a previous run wrote a non-string, it's silently treated as nil with no error.
- **[Bug]** `wrappedValue` setter writes to UserDefaults synchronously on the main actor — large values can hitch UI.
- **[Suggestion]** Encoder/decoder are recreated on every set/get; cache them.
- **[API]** `Equatable` constraint on `StoredValue` is required, but `Optional<T>` is Equatable only when T is Equatable; the convenience initializer doesn't constrain `OptionalStoredValue: Equatable`, making the type fail to compile when `T` isn't Equatable. Probably a compile-error trap for users.

### `Property Wrappers/CodableFileStorage.swift`
- **[Bug]** Default `equal(_:_:)` returns `false` always (when StoredValue is not Equatable). This means non-Equatable types perform a write on *every* `set` — even setting the same value re-writes the file. Compare encoded data instead, or document.
- **[Bug]** `data == "null".data(using: .utf8)` is intended to delete the file when value is `nil` — but JSONEncoder may emit `null\n` or with surrounding whitespace depending on options; comparison is fragile. Better: in the Optional convenience init, explicitly check `newValue == nil`.
- **[Bug]** `try? data.write(to: url)` — non-atomic write; partial writes can corrupt the file. Use `.atomic`.
- **[Bug]** No directory creation: if `url`'s parent directory doesn't exist, the write silently fails (because of `try?`). Either log or pre-create the dir.
- **[Suggestion]** No file-coordination — concurrent processes (extension + app) writing to the same URL can race.

### `Property Wrappers/NonIsolatedWrapper.swift`
- **[API]** Wraps a `ThreadsafeMutex` in `@State`. SwiftUI `@State` re-uses storage across view rebuilds, but `State` is itself not thread-safe; the wrapper relies on `ThreadsafeMutex.value` for synchronization which is fine. Setting `wrappedValue` does not call `value.objectWillChange` or anything to trigger re-renders — name suggests it's deliberately non-observed, which is correct. Document that.

### `Property Wrappers/ObservedValue.swift`
- **[Bug]** `update()` is called from `init`, which spawns a `Task { @MainActor in ... }` referencing `_wrappedValue` — that's `@State` storage not yet attached to a view. SwiftUI guidance: do not write to `@State` from `init`. May produce a runtime warning ("Modifying state during view update is not allowed") or be lost.
- **[Bug]** `MutableObservedValue.projectedValue` setter spawns a detached `Task { ... }` that calls `set(target, value)` — but `wrappedValue` (the `@State`) is not optimistically updated, so the binding's get returns the stale value until the next `update()` after the ObservableObject's publisher fires. UI feels laggy.
- **[Concurrency]** `Task { await self.set(self.target, value) }` captures `self` by value (struct). Fine for a struct property wrapper, but ensure `Target` and `closure` Sendability holds.
- **[Memory]** `@ObservedObject var target: Target` — the property wrapper holds a strong reference to `target`; if the calling view owns `target`, no cycle, but if `target` later captures the view, watch out.
- **[API]** Two property wrappers in one file share a lot of code; suggest factoring or document.

### `Property Wrappers/ReadyFlag.swift`
- **[Bug]** `set(false)` does nothing because `if !newValue { return }` early-exits. So once made ready, the flag can never be reset; `set(_:)` is misleading. Either remove the public `set(_:)` or actually allow toggling.
- **[Bug]** `waitForReady`: the check `if storage.value { return }` is *not* under the lock; between this check and `storage.append`, `set(true)` could run and not see the new continuation, leaving `waitForReady` to hang forever. Move the check inside the lock.
- **[Concurrency]** `class Storage` is not Sendable; the struct is `@MainActor`, but `Storage` contains `var value` and `var continuations` accessed from `append`/`set` under a lock — need `@unchecked Sendable` declaration or actor.
- **[Memory]** `_lock` is properly deinitialized/deallocated in `deinit`.
- **[Convention]** Could use Swift's `Mutex` (iOS 18+) or async-friendly `AsyncStream`/`continuation`.

## Widgets

### `Widgets/WidgetFamily.swift`
- **[Convention]** 111 lines — borderline. Many hard-coded dimensions per device — but as widget sizes are a published Apple table, this is correct usage. Still flagging:
- **[Convention]** Hard-coded dimensions throughout. The framework guideline says "avoid hard-coded dimensions"; here they're justified because Apple specifies widget sizes per device, but the table is incomplete (no iPhone 16, no 13 series, no iPad mini after 6th gen, no `accessoryRectangular`/`accessoryCircular`/`accessoryInline` cases). Will return wrong sizes silently for new devices.
- **[Platform]** Uses `UIScreen.main` — deprecated since iOS 16 in multi-scene apps. `UIScreen.main.bounds.size` returns the screen of the first connected scene; widgets typically run in their own process anyway, where `UIScreen.main` is the host's screen. Behavior is questionable.
- **[Bug]** `case .iPhone15Pro, .iPhone14Pro` reused with `iPhone12` for systemMedium and systemLarge — those phones have different screen sizes (iPhone 14 Pro is 393×852, 15 Pro is 393×852, 12 is 390×844). Lumping all into 338×158 is incorrect.
- **[Bug]** `.systemExtraLarge` on iPhone falls through `default: return CGSize(width: 360, height: 379)` — but `.systemExtraLarge` is iPad-only; should not be reachable for iPhone screens. If reached returns something that looks like systemLarge.
- **[Platform]** `#if canImport(WidgetKit) && !os(visionOS) && !os(tvOS)` — does not exclude watchOS even though `WidgetFamily` on watchOS uses `accessory*` cases that aren't switched here. The `#if os(watchOS)` branch uses a constant 40×40 regardless of family — inaccurate.
- **[API]** `@MainActor` extension forces all callers onto the main actor for what is essentially a constant lookup.

## SwiftData

### `SwiftData/ModelContext.swift`
- **[Bug]** `countModels(_ modelType: T)` takes a `T` *instance* but uses only its type for fetching. Should be `countModels<T: PersistentModel>(_ modelType: T.Type)`. Calling site wastes an instance.
- **[Bug]** `countModels` fetches ALL models then takes `.count` — for any non-trivial table this is O(n) and pulls all instances. Use `try fetchCount(descriptor)` (SwiftData 17+).
- **[Bug]** `allModels` swallows the error via `try?` — silent data loss / hard-to-debug.
- **[Bug]** `reportedFetch` uses `print` instead of `SuiteLogger.error` like `reportedSave` does — inconsistent.
- **[Bug]** `reportedSave` only reports save errors; if `presave()`'s body throws (it can't in current protocol — `presave()` is non-throwing — but if a model's `presave` triggers further mutations during iteration of `changedModelsArray`, you may invalidate the iterator).
- **[API]** `changedModelsArray` is referenced but I cannot find its definition in this repo — likely an extension elsewhere; flag if missing.
- **[Concurrency]** `ModelContext` is not Sendable; these extensions are usable only within the context's isolation domain (typically `@MainActor` for the main context). Methods are not annotated; fine in practice but document.
- **[Convention]** File is fine size-wise.

## Tests

### `Tests/SuiteTests/AnyEquatableTesting.swift`
- No issues. Filename `AnyEquatableTesting` is slightly off (most others are `*Tests.swift`); minor [Suggestion] to rename for consistency.

### `Tests/SuiteTests/ArrayExtensionTests.swift`
- **[Bug]** `testCollectionSplitByKeyPath` (line 193-202) doesn't actually verify that `split(by:)` produces both groups, only that count is 2 and that the age-25 group is correct. The age-30 group is never asserted, so a regression that conflates groups by accident could go undetected.
- **[Suggestion]** `testIdentifiableSubscript` (line 117) uses `items[1]` after writing — could be clearer with `items[id: searchItem]?.name == "Updated"` to test the read path of the same subscript being exercised on write.
- **[Coverage]** `breakIntoChunks(ofSize:growth:)` only tests one growth factor (2.0); fractional or zero growth is untested.
- File length: 204 lines — exceeds the ~100-line guideline ([Convention]).

### `Tests/SuiteTests/AsyncSemaphoreTests.swift`
- **[Flakiness]** Multiple tests depend on `Task.sleep(nanoseconds: 50_000_000)` / `100_000_000` to assume a task has reached suspension. Under load (CI runners, sanitizers) these can race. Examples: `signalResumesTask` (line 51), `cancellationRestoresValue` (lines 162/167), `fifoOrdering` (line 107). Prefer an explicit synchronization primitive (e.g. another semaphore signaled inside the spawned Task) or restructure to remove the sleep.
- **[Bug]** `fifoOrdering` (line 87) — name says FIFO, but the assertion only checks set membership (`Set(results) == Set(0...4)`). Either rename the test or actually assert ordering.
- **[Concurrency]** `blocksOnZero` (line 27) writes `completed = true` on whatever actor the test runs on, then reads it from the same path — works but the spawned `Task` captures `semaphore` (a class) implicitly; OK, but the assertion is trivially true since the line after `await wait()` always runs. The test does not really verify "blocking" — it just verifies `wait` eventually returns. Consider asserting elapsed time ≥ 100ms.
- **[Concurrency]** `multipleWaitsAndSignals` (line 65) has the same shape — `completed` is always true after `wait()` returns.
- File length: 282 lines ([Convention]).

### `Tests/SuiteTests/CoreGraphicsExtensionTests.swift`
- **[Bug]** `testRoundCGFloat` (lines 132-137) — function is named `roundcgf` but expectations behave like `floor`, not `round` (3.7 → 3.0, 0.9 → 0.0, -2.8 → -3.0). If the implementation truly does floor, the test name is misleading; if it's supposed to round, the assertions are wrong. Verify against the implementation.
- **[Suggestion]** `testCGRectStringInitializable` (line 58) only checks substring presence ("contains 1, 2, 3, 4") — would also pass if values were swapped. A round-trip via `CGRect(stringValue:)`/init from rawValue would be stronger.
- File length: 137 lines ([Convention]).

### `Tests/SuiteTests/CoreGraphicsTests.swift`
- No issues.

### `Tests/SuiteTests/Date.swift`
- **[Platform]/[Flakiness]** Many tests use `Date(calendar: .current, ...)`. `.current` depends on user locale/timezone, so e.g. `firstDayInWeek` (line 261) can be Sunday or Monday depending on locale — assertion against `Date.DayOfWeek.firstDayOfWeek` papers over this but `lastDayInMonth` for June being 30 (line 109) and `dayOfMonth` arithmetic could shift across DST transitions. Prefer a fixed `Calendar(identifier: .gregorian)` with `TimeZone(identifier: "UTC")`.
- **[Bug]** `testHourMinuteString` (line 252) — assertion `string.contains("14") || string.contains("2")` is far too lax; "2" appears in many strings (e.g., "02:00 PM" contains "2"). It almost cannot fail.
- **[Bug]** `testDateOnlyTimeOnly` (line 228) — `#expect(timeOnly == date)` looks wrong. `timeOnly` should presumably strip date components; expecting equality to the original `date` either reveals the implementation is a no-op or the test is wrong.
- **[Bug]** `testISO8601String` (line 134) uses parameter name `iso8691String:` — likely a typo (should be `iso8601String:`). If the API really has the typo, that's an [API] bug worth flagging.
- **[Coverage]** `testDayOfWeek` (lines 112-118) sets a value but never asserts on it.
- **[Suggestion]** `testNearestSecond` (line 53): 123.456 → 123.0 looks like floor not round — verify implementation matches name.
- **[Convention]** Filename `Date.swift` shadows Foundation's `Date` and doesn't follow `*Tests.swift` pattern.
- File length: 264 lines ([Convention]).

### `Tests/SuiteTests/DictionaryTests.swift`
- **[Coverage]** Only one test for the entire Dictionary extension surface area. Many extensions on Dictionary in Suite are untested.
- **[Bug]** `dict3["C"]` is `["1", 3]` (an array of mixed types) while `dict1["C"]` is `["1": 3]` (a dict). Asserting `diff1To3.count == 2` is opaque — there's no documentation of what diff returns when types disagree, so this is a brittle "golden number" test.

### `Tests/SuiteTests/EnhancedMacroTests.swift`
- **[Coverage]** This file is essentially a placeholder (`#expect(Bool(true))`). The comment notes that real macro testing was disabled due to SwiftSyntaxMacrosTestSupport/XCTest dep issues. Consider deleting since `MacroTests.swift` already does the same placeholder, or restoring real macro expansion tests now that Swift Testing is mature.

### `Tests/SuiteTests/GestaltTests.swift`
- **[Suggestion]** Many tests are tautologies: e.g. `#expect(isSimulator == true || isSimulator == false)` (line 32), `debuggerAttachment`, `previewDetection`, `unitTestsDetection`. They only verify the property is accessible and returns a Bool — which compilation already guarantees. Remove or replace with meaningful assertions (e.g., `#expect(Gestalt.isOnSimulator == true)` under a simulator-only guard).
- **[Bug]** `platformExclusivity` (line 54-63) does not include iPad/iPhone in the list, so on iOS the `trueCount <= 1` check is effectively `0 <= 1` and trivially passes.
- **[Suggestion]** `buildDate` (line 117): `buildDate < Date()` will fail on systems where the build artifact's mtime is in the future (clock skew on CI). Consider asserting non-nil only, or `buildDate < Date().addingTimeInterval(60)`.
- File length: 140 lines ([Convention], minor).

### `Tests/SuiteTests/JSON+Codable.swift`
- **[Bug]** `testDictionaryCoding` (lines 31-38) — encodes/decodes but never asserts that decoded values match originals. The only assertion is `!data.isEmpty`. False-positive risk: any non-throwing encode passes.
- **[Bug]** `testCodableJSONDictionary` (lines 45-57) uses `try!` twice (lines 52, 55) which crashes the whole test process on failure rather than reporting a clean test failure. Use `try` with throwing test, or `#require`.
- **[Convention]** Filename `JSON+Codable.swift` doesn't follow `*Tests.swift`. Struct name `JSON_Codable` uses underscore.

### `Tests/SuiteTests/JSON+Hashing.swift`
- **[Convention]** Filename `JSON+Hashing.swift` and struct `Test` (line 17) — a struct named `Test` is too generic and may collide.
- **[Suggestion]** Trailing TODO comment on line 34 ("Write your test here…") — leftover from template. Remove.

### `Tests/SuiteTests/LoadingStateTests.swift`
- **[Bug]/[Concurrency]** `testSendableConformance` (line 94) spawns a `Task` but never awaits it. The `#expect` inside may run after the test ends; if the task fails the test won't report failure. Either await the task or remove (Sendable conformance is a compile-time check anyway — this test adds nothing).
- **[Bug]** `testLoadingStateEquality` comment on line 30 ("compares case, not associated value") — the test never verifies that two `.failed` cases with *different* errors are still considered equal. If equality really only compares the case, write that assertion explicitly: `#expect(.failed(errorA) == .failed(errorB))`.
- File length: 106 lines (borderline OK).

### `Tests/SuiteTests/MacroTests.swift`
- **[Coverage]** Placeholder only, no real tests. Same comment as `EnhancedMacroTests.swift` — restore actual macro expansion tests.

### `Tests/SuiteTests/NumericExtensionTests.swift`
- **[Bug]** `fixedWidthBytes` (lines 53-62) assumes big-endian byte order (`bytes[0] == 0x12`). On Apple silicon (little-endian), if `bytes` returns native order this would be `[0x78, 0x56, 0x34, 0x12]`. The assertion may pass only if the implementation explicitly converts to big-endian — verify and document the contract.
- **[Bug]** `individualBytes` (lines 78-85) and `characterCode` (lines 88-93) make the same endian assumption.
- **[Bug]** `durationStringSimple` and three sibling `durationString*` tests (lines 167-200) assert only `!string.isEmpty`. They do not verify the formatted output is correct (e.g., 60s → "1:00"). Strengthen by asserting actual expected strings.
- File length: 208 lines ([Convention]).

### `Tests/SuiteTests/OptionalExtensionTests.swift`
- **[Suggestion]** `testOptionalUnwrap` (lines 36-50) uses `#expect(Bool(false), …)` to indicate failure. Prefer `Issue.record(…)` or `#require(…)` patterns idiomatic to Swift Testing.
- File length: 137 lines ([Convention]).

### `Tests/SuiteTests/ReadyFlagTests.swift`
- **[Flakiness]** Heavy reliance on `Task.sleep` to coordinate (`startsNotReady` line 28, `multipleWaiters` line 70, `setTrue` line 92, `setFalse` line 114, `sequentialFlags` line 138/145, `concurrentWaiters` line 170). Each is a flake risk on slow CI. Replace with an explicit barrier (e.g., a child semaphore) when possible.
- **[Concurrency]** `startsNotReady`, `setTrue`, `setFalse` write `completed` from a spawned `Task` and read it from the test. `var completed = false` is a non-isolated capture. Despite `@MainActor` on the suite, the spawned `Task {}` may inherit MainActor — verify; if not, this is a data race, even if it appears to work.
- **[Concurrency]** `setFalse` (line 102) reads `completed` after only a 50ms wait. If the test were to fail, it would do so silently because we never make the flag ready or cancel the spawned waiter — the leaked task continues. The check only proves "still false after 50ms," which is also a [Flakiness] property.
- File length: 178 lines ([Convention]).

### `Tests/SuiteTests/SharedDependencyManagerTests.swift`
- **[Coverage]** Only one test, and it doesn't assert anything — it just registers a dependency. Add reads/lookups, scoping, double-registration, etc.
- **[Bug]** Test only verifies that `register(_:_:)` does not throw/crash — no `#expect` on retrieval.

### `Tests/SuiteTests/StringExtensionTests.swift`
- **[Bug]** `testStringInitFromData` (lines 92-96): `String(data: data, encoding: .utf8)` is the standard Foundation initializer; `String(data: nil, encoding: .utf8)` requires the data parameter to be optional. If Suite adds an optional-data init, the test name and intent are unclear. Confirm what extension is being exercised.
- **[Suggestion]** `testPathExpansion` (line 113-121) — line 119 `let _ = expandedPath.abbreviatingWithTildeInPath` tests nothing. Either assert behavior or remove.
- **[Coverage]** Email/phone validation only happy-path on common formats; no Unicode emails, IPv6-bracket emails, or international phone formats.
- File length: 122 lines (borderline OK).

### `Tests/SuiteTests/SwiftUIComponentTests.swift`
- **[Bug]** Several tests (`testAsyncButtonInitialization` line 32, `testLoadingViewInitialization` line 66, `testMockLoadingViewStates` line 135, `testViewExtensionsCompile` line 143) end with `#expect(Bool(true))`. These are no-op tests — they only verify compilation. Either remove or assert something meaningful (e.g., observable state changes via ViewInspector or by reading published properties).
- **[Bug]** `testButtonIsPerformingActionKey` (lines 22-25): the comment says "OR operation should keep true" but the reduce semantics typically *replace* with `nextValue()` in SwiftUI's PreferenceKey contract. Verify the implementation actually does an OR — if it just calls `value = nextValue()`, the assertion at line 25 `#expect(value == true)` would fail. (The test passing currently confirms one or the other, but the assertion at line 28 with `false → false` is consistent with both replace and OR semantics, so this only weakly proves OR.)
- **[Suggestion]** `if(_:transform:)` is redefined locally in the test file (lines 165-173). If Suite already provides this extension (likely), the test is shadowing production code. If not, this is a bug being smuggled into the test target.
- File length: 173 lines ([Convention]).

### `Tests/SuiteTests/ThreadsafeMutexTests.swift`
- **[Platform]** All tests gated `@available(iOS 16, watchOS 9, macOS 14, *)`. On older OSes the entire suite is silently skipped. CLAUDE.md says iOS 13+ minimum — confirm the type itself is gated to those versions; otherwise add a fallback test.
- **[Coverage]** No test for read contention (only write-write). Reentrancy / nested `perform` calls are not exercised.
- No further issues.

### `Tests/SuiteTests/VersionStringTests.swift`
- **[Bug]** `testVersionStringInitialization` (line 121-124): asserts `complexVersion != otherVersion` for `"1.2.3-beta.1"` vs `"1.2.3"`. Earlier (`testVersionStringWithInvalidComponents` line 73-77) asserts that non-numeric parts are filtered out, in which case `1.2.3-beta.1` should equal `1.2.3`. These two tests appear contradictory — verify which behavior is correct.
- **[Bug]** `testVersionStringEdgeCases` line 86-88 asserts `"1 . 2 . 3"` (spaces between components) equals `"1.2.3"` — this depends on whitespace stripping that may or may not be intended; document/verify.
- File length: 126 lines ([Convention], minor).

### Cross-cutting notes
- **[Convention]** All test files already use Swift Testing — good. No XCTest violations to flag.
- **[Convention]** Many files exceed ~100 lines (Date 264, AsyncSemaphore 282, Numeric 208, Array 204, ReadyFlag 178, SwiftUI 173). Consider splitting by sub-feature.
- **[Coverage]** Macros currently have no real expansion tests (placeholders only). Per CLAUDE.md the macro system is a key feature — restoring `SwiftSyntaxMacrosTestSupport` tests should be a priority.
- **[Flakiness]** `Task.sleep`-based coordination appears across `AsyncSemaphoreTests`, `ReadyFlagTests`, and `LoadingStateTests`. A shared helper using an `AsyncSemaphore` or `CheckedContinuation` would reduce flake surface area.
