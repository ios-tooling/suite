# Suite — Detailed Code Review

**Scope:** Every Swift file in `Sources/Suite/`, `Sources/SuiteMacrosImpl/`, `Tests/SuiteTests/`, plus `Package.swift` (310 files).
**Date:** 2026-05-03
**Method:** File-by-file review by 13 parallel review agents, aggregated here.

Each finding is tagged: **[Bug]**, **[Concurrency]**, **[API]**, **[Perf]**, **[Platform]**, **[Convention]**, **[Memory]**, **[Deprecated]**, **[Diagnostics]**, **[Coverage]**, **[Flakiness]**, **[Suggestion]**.

> **Update 2026-05-03 — critical-bug fixes landed.** All 40 critical bugs are now closed: 39 fixed across `fab966b` and a follow-up rewrite, plus 1 disputed and closed as no-op (the `Trig.swift` quadrant claim — re-analysis showed the two mappings agree). Public API typos and CLAUDE.md drift (sections below) were addressed earlier in `74ce1eb`. Status tags inline: `[FIXED fab966b]`, `[FIXED 74ce1eb]`, `[DISPUTED]`. Detailed file-by-file findings further down have **not** been re-audited line-by-line; treat them as the original review snapshot.

---

## Executive Summary

### Critical bugs (crash, data corruption, security, won't-compile)

Progress: 39 fixed, 1 disputed (closed as no-op). **40 / 40 closed.**

- [x] `[FIXED fab966b]` **`Types/Keychain.swift`** — `AccessOptions.accessibleAlwaysThisDeviceOnly` returns `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. Silent security degradation. (line 396)
- [x] `[FIXED fab966b]` **`Types/RawCollection.swift`** — Subscript setter is **inverted**: `collection[item] = true` REMOVES the item, `false` INSERTS. Silent data corruption. *Resolved by deleting `RawCollection` entirely; the `StringInitializable` protocol remains.*
- [x] `[FIXED fab966b]` **`Foundation/String.swift`** — `extractSubstring(start:end:)` references undefined symbol `string`; **won't compile**. Called by `MobileProvisionFile.swift` (which is itself entirely commented out).
- [x] `[FIXED fab966b]` **`Foundation/Date.Month.swift:20`** — `abbrev` indexes `[self.rawValue]` instead of `[rawValue - 1]`. **Crashes on `.dec`** and is off-by-one for every other month.
- [x] `[FIXED fab966b]` **`SwiftUI/Extensions/TextField.swift`** — Optional `addTextContentType(_:)` calls itself recursively; **infinite recursion / stack overflow** when called with non-nil. *Resolved by giving the non-optional overload a distinct argument label (`type:`).*
- [x] `[FIXED fab966b]` **`Foundation/Optional.swift`** — Custom `<` returns `true` for `nil < nil`, **violating strict weak ordering**. Breaks any `sort` that uses it.
- [x] `[FIXED fab966b]` **`Foundation/StableMD5.swift`** — `Date` hashed differently in dict path (`timeIntervalSinceReferenceDate`) vs array path (`String(describing:)`, locale-formatted). **Same data → different hashes**; defeats "stable" purpose.
- [x] `[FIXED fab966b]` **`Combine & Async/AsyncFlag.swift`** — `wait()` is fundamentally broken: spins forever in an `AsyncStream(unfolding:)` that never observes the signal. *Rewritten with a `CheckedContinuation` queue.*
- [x] `[FIXED fab966b]` **`Types/VersionString.swift`** — `==` uses `suffix(from: count - minCount)` (wrong); `"1.2.5.0.0" == "1.2"` returns true.
- [x] `[FIXED fab966b]` **`Types/SoundEffect.swift:232`** — `pause()` sets `isPlaying = true`.
- [x] `[FIXED]` **`Geometry/CGSize.swift`** — `scaleDown(toWidth:height:)` typo: sets `heightGood = true` where it means `widthGood = true`. Function broken in nearly every branch. *Rewritten as a min-of-per-axis-ratios scale (capped at 1 to avoid enlarging); 8 lines vs the prior 30, no boolean flags, no special-case branches. No callers in-repo.*
- [x] `[FIXED fab966b]` **`Geometry/Vector2.swift`** — `init?(rawValue:)` parses `components[0]` for both x and y; round-trip loses y.
- [x] `[DISPUTED]` **`SwiftUI/Shapes/Trig.swift`** — `Angle.quadrant` and `CGPoint.quadrant` use the same enum for two different quadrant systems with conflicting mappings. *Re-analysis: both mappings agree (i = top-right, ii = top-left, iii = bottom-left, iv = bottom-right) when interpreted as clockwise-from-12 for `Angle` and screen-coordinates for `CGPoint`. `point(for angle:)` round-trips correctly under that interpretation. Closed as no-op pending a counter-example.*
- [x] `[FIXED fab966b]` **`SwiftUI/View Modifiers/Spinning.swift`** — `SpinningModifier.period` is stored but dropped at construction; the `period` argument is silently ignored.
- [x] `[FIXED fab966b]` **`SwiftUI/View Wrappers/Guidelines.swift:49`** — `yMarks` is built from the `x` parameter range; concrete bug when `x != y`.
- [x] `[FIXED fab966b]` **`SwiftUI/Other Views/CalendarMonthView/CalendarMonthView.WeeksView.swift`** — `options(for:)` ignores month/year; selecting a day in any month highlights the same day-number across all displayed months. *Now takes a `Date.Day` and compares with `Calendar.isDate(_:inSameDayAs:)`; also sets `.isToday` and `.isNextMonth`.*
- [x] `[FIXED fab966b]` **`SwiftUI/Extensions/Color.swift`** — `Color.randomGray` uses `Double.random(in: 0...100.0)` then passes to `Color(white:)` which expects 0...1. Always near-white.
- [x] `[FIXED fab966b]` **`SwiftUI/Utilities/UnitRect.swift`** — `overlap(with:)` uses `max` where it should use `min`; result is wrong height.
- [x] `[FIXED fab966b]` **`SwiftUI/Extensions/NavigationLink.swift`** — `BoundNavigationLink`'s binding setter is a no-op; programmatic dismissal is impossible. *Resolved by deleting the file (the type wrapped the deprecated `NavigationLink(isActive:)` API).*
- [x] `[FIXED fab966b]` **`UIKit/UIButton.swift:50`** — `backgroundImage(_:for:)` always passes `.normal`, ignoring the state parameter.
- [x] `[FIXED fab966b]` **`UIKit/UIColor.swift:172-179`** — 4-char ARGB hex branch: masks/shifts produce 0 for alpha and wrong components. *Reworked to RGBA layout (`0xF000` / `0x0F00` / `0x00F0` / `0x000F`), matching the 8-char branch.*
- [x] `[FIXED fab966b]` **`AppKit/NSColor.swift:58`** — `hex` getter: `r << 16 + g << 8 + b`. Swift `<<` has **lower** precedence than `+`, so this evaluates as `r << (16 + g) << (8 + b)`. Definite bug.
- [x] `[FIXED fab966b]` **`Cocoa/NSView+Helpers.swift:116`** — `fullyConstrain(to:)` top constant is `23` instead of `0`.
- [x] `[FIXED fab966b]` **`Foundation/DateInterval.swift:19`** — `fullRange` returns `.start` of the latest-ending interval; should be `.end`.
- [x] `[FIXED fab966b]` **`Foundation/AVPlayer.swift:23-38`** — failable convenience init flow is malformed (`self.init(url:)` then `return nil`).
- [x] `[FIXED 74ce1eb]` **`Foundation/Date.swift:326-336`** — typo `iso8691String` (should be `iso8601String`) on a public API; tests carry the typo through. *Fixed in the earlier "fix typos" commit.*
- [x] `[FIXED fab966b]` **`Foundation/Date.swift:480-487`** — `thisWeek(_:)` and `upcoming(_:)` are byte-identical duplicates. *Resolved by making `upcoming(_:)` always return the next future occurrence (no `previous` branch). This is a name-driven judgment call; deletion of `upcoming` is also a defensible alternative if no callers depend on the new semantics.*
- [x] `[FIXED fab966b]` **`Foundation/FileManager.swift:64-68`** — `uniqueURL` first-collision loop sets the name back to base; never finds a unique name.
- [x] `[FIXED fab966b]` **`Foundation/UserDefaultsBackedDictionary.swift`** — URL retrieval via `value(forKey:)` doesn't work; need `defaults.url(forKey:)`.
- [x] `[FIXED fab966b]` **`Geometry/CGContext.swift`** — `bytes`/`uint32s` capacity is wrong by a factor of 4; pointer escapes the `withMemoryRebound` closure (UB). *Capacity corrected; callers now use `self.uint32s` (which permanently rebinds via `bindMemory`) instead of escaping a `withMemoryRebound` pointer.*
- [x] `[FIXED fab966b]` **`Geometry/CGContext.swift`** — `alphaOfPixelAt` inverts alpha for `.premultipliedFirst`. *Switched on alpha-info: `.premultipliedFirst`/`.first`/`.alphaOnly` read offset 0; everything else reads offset 3.*
- [x] `[FIXED fab966b]` **`Property Wrappers/ReadyFlag.swift`** — `set(false)` silently no-ops; `waitForReady` race between value check and continuation append; flag can hang waiters forever. *Append-or-resume happens under the lock; resume runs outside the lock; `set(false)` actually clears the value.*
- [x] `[FIXED fab966b]` **`Property Wrappers/CodableAppStorage.swift`** — Optional handling stores the literal string `"null"` instead of removing the key. *Setter now removes the key whenever JSON encoding produces `"null"`.*
- [x] `[FIXED fab966b]` **`Logging/Slog.File.swift`** — `save()` rewrites the entire file on every log line (O(n²)) without `.atomic`; `Line` parsing splits on `/` so any URL/path in a message corrupts parsing. *Delimiter changed to U+001F (Unit Separator); color is now detected at the end of the components rather than at index 2; `save()` writes `.atomic`. The O(n²) full-file rewrite per line remains — flagged for a future change to append/streaming I/O.*
- [x] `[FIXED fab966b]` **`Combine & Async/Publishers.swift`** — `withPreviousValue()` force-unwraps `$0.new!` while the first scan emits `(nil, nil)`; **crashes on first emission**. *Replaced `map { $0.new! }` with `compactMap` that drops the seed.*
- [x] `[FIXED fab966b]` **`Utilities/JSON/CodableJSONArray.swift:44`** — `init?(_:[String:Sendable]?)` is a copy-paste stub from the dictionary variant; takes a dict but constructs an array. *Now takes `[Sendable]?`.*
- [x] `[FIXED fab966b]` **`Utilities/JSON/JSONDecoder+JSONDictionary.swift`** — `date(from double:)` and `date(from int:)` always return `nil`; `secondsSince1970`/`millisecondsSince1970` strategies never work for keyed numeric dates. *Both now honor those strategies (`int` delegates to `double`).*
- [x] `[FIXED fab966b]` **`Utilities/Reachability.swift`** — `setupAndCheckForOnline()` returns early when a continuation is already installed; second waiter is told the current state but never awaits. *Replaced single-slot continuation with a poll loop on `isStartingUp`; multiple concurrent waiters all resolve. (Polling vs. continuation queue is a deliberate tradeoff — startup is bounded at 250ms, and the simpler shape was preferred.)*
- [x] `[FIXED fab966b]` **`SwiftData/ModelContext.swift`** — `countModels` accepts a `T` *instance*, fetches all rows then `.count`s; should accept `T.Type` and use `fetchCount`.
- [x] `[FIXED fab966b]` **`SwiftUI/View Wrappers/SideDrawerContainer.swift:37`** — Trailing-side rendering anchors content to leading; trailing drawer behaves wrong. *Spacer now lives on the opposite side based on `side`.*

### Documentation drift

- [x] `[FIXED 74ce1eb]` **`CLAUDE.md`** documents five macros (`@GeneratedEnvironmentKey`, `@GeneratedPreferenceKey`, `@AppSettings`, `@AppSettingsProperty`, `@NonisolatedContainer`). Only **two** actually exist (`@GeneratedPreferenceKey`, `@NonisolatedContainer`). Also references runtime file `Types/UserDefaultsContainer.swift`, which doesn't exist. The Tests CLAUDE.md description claims XCTest with SwiftSyntaxMacrosTestSupport — but **all current tests use Swift Testing**. *Macros list, runtime pointer, testing description, and platforms section all updated in the earlier "fix typos / refresh CLAUDE.md" commit.*

### Public API typos (rename = breaking)

All six were fixed in `74ce1eb`:

- [x] `[FIXED 74ce1eb]` `Date.iso8691String` → `iso8601String` (Foundation/Date.swift) — typo carried through tests
- [x] `[FIXED 74ce1eb]` `OverlayModifer` → `OverlayModifier` (SwiftUI/View Wrappers/BottomSheetView.swift)
- [x] `[FIXED 74ce1eb]` `EmbdeddedWebView` → `EmbeddedWebView` (Utilities/Views/SimpleWebView.swift) — appears 5+ times
- [x] `[FIXED 74ce1eb]` `EnviromentEchoingView.swift` filename and type name → `Environment…` (SwiftUI/EnviromentEchoingView.swift)
- [x] `[FIXED 74ce1eb]` `editabled(_:)` → `editable(_:)` (Cocoa/NSTextFieldAndView.swift)
- [x] `[FIXED 74ce1eb]` `presentedest` → `topPresentedViewController` (UIKit/UIViewController.swift)

### Recurring patterns

Tiered for triage. **Tier A** = small, clear fixes done in a focused pass. **Tier B** = moderate, scope-per-file. **Tier C** = large refactor, separate effort.

#### Tier A (closed)

- [x] `[FIXED]` **Swift convenience-init failure pattern.** Several `init?` overloads call `self.init(...)` then `return nil`. UIColor, UIImage, NSColor, AVPlayer, SwiftUI Color all had this; semantics are dubious in Swift. *AVPlayer fixed in fab966b; UIColor / NSColor / UIImage / `Color.init?(hex:)` fixed in this pass — all now use a bare `return nil` before any `self.init` call.*
- [x] `[FIXED]` (4 of 5) **Memory leaks**: `NotificationWatcher`, `Subscribers.Sink` in Publishers.swift, `SceneStateObserver` retain cycle, `WebConsole.urlObservation` strong-self capture, IOKit leaks in `Gestalt` (`takeUnretainedValue` on Create-rule + missing `IOObjectRelease`).
    - `NotificationWatcher` — switched to selector-based observer with `removeObserver(self)` in `deinit`.
    - `SceneStateObserver` — `[weak self]` in the per-name closure (was a retain cycle through `cancellables`).
    - `WebConsole.urlObservation` — `[weak self]` in the KVO observer block (the observation is held by `self`).
    - `Gestalt.rawDeviceType` (macOS) — `IOObjectRelease(service)` via `defer`; switched `takeUnretainedValue` → `takeRetainedValue` (Create-rule property was being leaked AND under-retained).
    - `Gestalt.serialNumber` (macOS) — `IOObjectRelease(platformExpert)` via `defer`. Retain-rule was already correct here.
    - **Open**: `Subscribers.Sink` in `Publishers.swift` (`onCompletion` / `onSuccess` / `onFailure`). Direct `subscribe(Subscribers.Sink(...))` keeps the sink alive until the publisher completes — fine for one-shot publishers, leaks for never-ending ones. Fixing requires returning `AnyCancellable` to the caller, which is an API-shape change. Left as-is pending a broader Combine cleanup (Tier C).
- [x] `[FIXED 74ce1eb]` **Entirely commented-out files** (delete or restore): `Types/MobileProvisionFile.swift`, `Foundation/TimePost.swift`, `SwiftUI/Component Views/KeyboardSpacer.swift`, `SwiftUI/Utilities/PositionedLongPress.swift`. *All four removed.*

#### Tier B

- [ ] **Hard-coded dimensions** despite the project rule, especially in: `TitleBar`, `FullWidthButtonStyle`, `SlideUpSheet`, `MultiColumnPicker`, `BottomSheetView`, `Font.swift`, `MonthYearPopover`. *Blocked: the natural fix (`@ScaledMetric`) requires iOS 14 / macOS 11, but the package targets macOS 10.15. Either bump the deployment target, add per-type `@available` annotations (breaking for older callers), or accept the hardcoded values. Tried `@ScaledMetric` on `TitleBar.barHeight` and reverted on the availability error. `Font.buttonImage` (`.system(size: 32)`) is a deliberate constant for icon-button glyphs; arguably the least-bad form of hardcoded dimension.*
- [x] `[FIXED]` **View-returning `some View` computed properties** (rule says prefer subview types).
    - `AsyncButton.buttonLabel` → `AsyncButtonContent` (generic subview).
    - `AsyncButtonBusyLabel.spinner` → inlined into `body` (it was a single-use indirection).
    - `MonthYearPopover.monthList` / `.yearList` → private `MonthList` / `YearList` subviews bound to `$date`.
    - `CalendarMonthView+Components.*` → `MonthStepButton`, `MonthYearList`, `ShowYearMonthListButton`, `ShowYearMonthListTitle` subviews; the `monthYearBar(_:)` helper became `MonthYearBar`.
    - `FlowedHStack.legacyBody` → `LegacyFlowedHStack` subview that owns its own `availableWidth` / `elementSizes` state.
    - `CalendarMonthView.monthNames` is `[String]`, not a view — left as a computed property.
- [x] `[FIXED]` (3 of 9, others triaged) **State mutation during view body.**
    - `OffsetReportingScrollView.clearBackground` — `MainActor.run { position = offset }` was a no-op (sync from main-actor doesn't defer); replaced with `Task { @MainActor in ... }`. **Real bug.**
    - `ScrollCanary` — direct `scrollOffset = ...` mutation inside a `GeometryReader` closure, no deferring. Wrapped in `Task { @MainActor in ... }`. **Real bug.**
    - `AnimationCompletionObserverModifier.notifyCompletionIfFinished` — same `MainActor.run` misconception; replaced with `Task { @MainActor in completion() }`. **Real bug.** (Comment claimed it was deferring; it wasn't.)
    - `View+sizeReporting` (`SizeOverlay`) — already uses `PreferenceKey` + `onPreferenceChange`. **False positive** — that's the correct SwiftUI pattern.
    - `SwipeActions.buildContent` — uses the `MainActor.run(after: 0.01)` shim, which actually does defer (it's a `DispatchQueue.main.asyncAfter` wrapper). Crosses with Tier C #2 (GCD usage); leaving alone.
    - `vprint`, `Tooltips.tooltip` — call `print` / `logg` during body. Side effects, not state mutation; benign.
    - `Closure.body` — calls the closure during body computation. This is the entire purpose of the type. Fixing requires changing the API contract (e.g., `.onAppear`-based variant), which would be a breaking change and changes semantics (recompute vs once). Left alone.
    - `LoadingView.task` — `state = .loading` inside `.task { ... }`. `.task` runs after the body is committed, so this is fine. **False positive.**
- [x] `[FIXED]` **Stale device tables**: `Gestalt+DeviceType.swift`, `UIKit/ScreenSize.swift`, `Widgets/WidgetFamily.swift` — missing iPhone 15/16, recent iPads, Apple Watch Ultra/9/10, Apple TV 4K 3rd gen. *Added: iPhone 15 / 15 Plus / 15 Pro / 15 Pro Max, iPhone 16 / 16 Plus / 16 Pro / 16 Pro Max / 16e, iPad 9th/10th gen, iPad Mini 6th/7th gen, iPad Air 5th gen + M2 (11"/13"), iPad Pro 11" 3rd/4th gen + M4, iPad Pro 12.9" 5th/6th gen + 13" M4, Apple Watch SE 2nd gen, Series 8/9/10, Apple Watch Ultra/Ultra 2, Apple TV 4K 2nd/3rd gen. Screen sizes added for iPhone 16 Pro/Pro Max plus the recent iPad lineup. WidgetFamily.swift's per-device pixel sizes were not updated since they require Apple's HIG specs and overlap with the hardcoded-dimensions item.*
- [ ] **Deprecated APIs in active use**: status by API:
    - `NavigationLink(isActive:)` — `[FIXED]` no remaining direct call sites (the `BoundNavigationLink` file was deleted in fab966b; the other usages live inside the legacy `NavigationView.swift` back-compat layer below).
    - `NavigationView` — `[OPEN]` `Sources/Suite/SwiftUI/Extensions/NavigationView.swift` is intentionally a pre-iOS 16 back-compat layer (`OptionalNavigationLink`, `ContainedContentNavigationLink`). Replacing it with `NavigationStack` is a behavior change *and* would require dropping iOS 15/macOS 12 support. Leave as-is until the deployment-target bump.
    - single-arg `onChange` — `[OPEN — mostly false positive]` Surveyed; nearly every call site already wraps the deprecated single-arg form inside an `#if os(visionOS)` (or `if #available(iOS 17, *)`) check with a zero-arg companion. Pattern is intentional back-compat.
    - `UIScreen.main` — `[OPEN]` 5 real call sites (`UIView.screenScale`, 4 in `WidgetFamily.swift`, 2 in `CurrentDevice.swift`). Proper replacement requires walking from a `UIWindowScene`, which changes API shape (static property → function with a window argument). Deferred.
    - `UIApplication.windows` — `[CLEAN]` no usages found.
    - `UIGraphicsBeginImageContextWithOptions` — `[FIXED]` all 5 call sites in `UIImage.swift` (`clipped`, `create`, `tintedImage`, `overlaying`, `resized`) converted to `UIGraphicsImageRenderer`. Removed the iOS 10 fallback in `create(size:closure:)` since Suite already targets iOS 13.
    - `Process.launchPath` / `launch()` — `[FIXED]` switched to `executableURL` / `try run()` (macOS 10.13+, well within the macOS 10.15 target). The new API throws; failures map to return code `-1`.
    - `kIOMasterPortDefault` — `[OPEN]` two call sites in `Gestalt.swift`. `kIOMainPortDefault` requires macOS 12; the values are identical at runtime so the deprecation is cosmetic. Adding an availability check costs more than it earns.
    - `.autocapitalization` — `[FIXED]` `addTextContentType` uses `.textInputAutocapitalization` on iOS 15+, falls back on older.
    - `AnimatableModifier` — `[FIXED]` `AnimationCompletionObserverModifier` conforms to `ViewModifier, Animatable` separately.

#### Tier C (open — large refactor, separate effort)

- [x] `[RESOLVED]` **Combine usage despite "use async/await" rule.** `Pluralizer`, `Timer`, `Reachability`, `CommunalFetcher`, `DeSync`, `ObservableValue`, `SignificantTimeChangeObserver`, `InterfaceOrientedView`, `PublisherView`, `SceneStateObserver`, `Keychain`, `onTimer`, `NotificationObserver`, `Debouncer`. Every sub-item below is now FIXED, OUT-OF-SCOPE (Combine bridge by design), KEPT-AS-IS (user decision), or NOT-COMBINE (reviewer false positive).
    - `Pluralizer` — `[FIXED]` `CurrentValueSubject<[String:String], Never>` was being used purely as a thread-safe box (no subscribers). Replaced with an `NSLock`-guarded dictionary; `@unchecked Sendable` because `ThreadsafeMutex` would force iOS 16. Public API unchanged.
    - `onTimer` — `[FIXED]` `Timer.publish(...).autoconnect() + onReceive` replaced with a `Task { ... try? await Task.sleep ... perform(Date()) }` loop driven by `.onAppear` / `.onDisappear`. No more `Combine` import in the file.
    - `Debouncer` — `[FIXED]` `$input.debounce(for:scheduler:).sink` replaced with a `didSet` on `input` that cancels any in-flight debounce `Task` and schedules a new one with `Task.sleep`. `@Published` kept (it's the SwiftUI binding seam, not a flow operator). No more `import Combine`.
    - `NotificationObserver` — `[FIXED]` switched to `NSObject` + selector-based `addObserver` with `removeObserver(self)` in `deinit`. Same Swift-6 deinit-isolation workaround used in `NotificationWatcher`. Also closes a previously unflagged observer leak. The file still imports `Combine` to provide a `Notification.Name.publisher()` extension that's part of the public API; that's a Combine-bridge surface, kept on purpose.
    - `SignificantTimeChangeObserver` — `[FIXED]` `.publisher().sink` swapped for `NotificationCenter.addObserver(forName:object:queue:using:)` with `[weak self]` and an actor hop. No `import Combine`. Kept iOS 13+ availability (the async `notifications(named:)` sequence requires iOS 15).
    - `InterfaceOrientedView` (`OrientationWatcher`) — `[FIXED]` Combine notification subscription replaced with `NSObject` + `@objc` selector pattern. Adds `removeObserver(self)` in `deinit`, which the original lacked (each call to `OrientationWatcher.setup(windowScene:)` previously leaked the prior instance's subscription via the `cancellables` set). Kept iOS 13+ availability.
    - `CommunalFetcher` — `[FIXED]` rewrote `CurrentValueSubject<Value?, Error> + sink + cancellables` as a `Task<Value, Error>` dedupe: cached value short-circuits, in-flight task is awaited by all concurrent callers, success populates the cache. ~20 lines vs 58, no `import Combine`.
    - `ObservableValue` — `[OUT-OF-SCOPE]` the type's purpose is to bridge an arbitrary `Publisher` into an `ObservableObject` for SwiftUI. Removing Combine would require changing the public API to take an `AsyncSequence` instead — a breaking change for callers and a strict-loss in expressiveness (Combine operators don't translate 1:1 to AsyncSequence). Bridge-by-design.
    - `PublisherView` — `[OUT-OF-SCOPE]` same reasoning: this view's whole job is to render a SwiftUI view from a Combine `Publisher`. Removing Combine = remove the type.
    - `DeSync` — `[OUT-OF-SCOPE]` the file's free `desync(...)` helpers are already pure async/await. The `Publisher.asynchronize()` extension at the bottom is also a deliberate Combine→async bridge for callers stuck with Combine.
    - `Reachability` — `[NOT-COMBINE]` Re-checked: doesn't use Combine. Uses `NWPathMonitor` (closure-based; no async alternative in the Network framework) and `ObservableObject`/`objectWillChange` (the SwiftUI binding seam, not flow control). Reviewer's flag was loose. The `DispatchQueue` in `init(queue:)` is mandatory for `NWPathMonitor.start(queue:)`, so it rolls into Tier C #2 only nominally.
    - `SceneStateObserver` — `[KEPT-AS-IS]` user reviewed and decided to keep the existing `[AnyCancellable]` driver; the retain-cycle was already fixed in the Tier A pass.
    - `Keychain` — `[OUT-OF-SCOPE — public API]` `lastResultCodeSubject`, `accessGroupSubject`, `keyPrefixSubject`, `synchronizableSubject` are **public** `CurrentValueSubject`s — they're Suite's observation API for keychain config. Removing them is a breaking change. Bridge-by-design.
    - `Subscribers.Sink` leak in `Publishers.swift` (`onCompletion`/`onSuccess`/`onFailure`) — `[OUT-OF-SCOPE — public API]` fixing requires returning `AnyCancellable` to the caller, an API-shape change.
- [x] `[FIXED — partly false positive]` **GCD usage despite "no GCD" rule.** `MainActor.run(after:)` (used in SwipeActions, ScrollCanary, AnimationCompletion) appears to be a `DispatchQueue.main.asyncAfter` shim. `SeededRandomNumberGenerator` uses `DispatchSerialQueue.global()` and `.sync`. `Reachability` stores a `DispatchQueue`.
    - `MainActor.run(after:)` shim — **false positive**. `Sources/Suite/Utilities/MainActor.swift` already implements it with `Task { try? await Task.sleep(...); await MainActor.run { ... } }` — async/await, not GCD.
    - `SeededRandomNumberGenerator` — `[FIXED]` `DispatchSerialQueue.global() + .sync` replaced with an `NSLock` + manual `lock()/unlock()` pattern (Suite targets iOS 13+ so `NSLock.withLock` is unavailable). Public sync API (`reseed`, `next()`, `with(_:)`) is preserved.
    - `Reachability` `DispatchQueue` — required by `NWPathMonitor.start(queue:)`. No alternative API. Kept.
- [x] `[FIXED]` **`nonisolated(unsafe) static var`** for `EnvironmentKey.defaultValue` and similar is widespread. Many should be `let` (constants); a few are genuinely shared mutable state with no synchronization (`CodableJSONDictionary.dataKeyNames`, `EnclosingViewControllerKey.defaultValue`, `OrientationWatcher.instance`).
    - 9 of 15 call sites converted from `nonisolated(unsafe) static var X = …` to plain `static let X = …`: `TitleBarFontKey`, `ShowViewLabelsEnvironmentKey`, `IsEditingEnvironmentKey`, `IsScrollingEnvironmentKey`, `NavigationPathEnvironmentKey`, `SizePreferenceKey`, `FramePreferenceKey`, `CurrentDragPositionEnvironmentKey`, `DragAndDropEnabledEnvironmentKey`. (Each was a true compile-time constant being needlessly declared mutable.)
    - 4 sites kept the modifier on a `let` because the value type itself isn't `Sendable` (closure types, `Binding`): `HostingWindowKey.defaultValue`, `WebViewDidFinishLoadingEnvironmentKey.defaultValue`, `DismissParentEnvironmentKey.defaultValue`, `NavigationPathEnvironmentKey.defaultValue`. Switched to `static let` so the modifier now narrowly suppresses Sendable rather than blanketing a `var`.
    - `EnclosingViewControllerKey.defaultValue` — was `nonisolated(unsafe) static var = EnclosingViewControllerContainer()`, i.e., one shared default container across every unconfigured view (real shared-mutable-state issue: `EnclosingViewControllerContainer` has a mutable `_viewController`). Changed to a computed `static var` that returns a fresh container per access, matching the per-view contract SwiftUI expects.
    - `CodableJSONDictionary.dataKeyNames` — was `nonisolated(unsafe) public static var dataKeyNames: [String] = []`, public mutable, no synchronization. Wrapped in an `NSLock`-guarded accessor pair backed by a private `_dataKeyNames` storage; public read/write API unchanged.
    - `SeededRandomNumberGenerator.sharedGenerator` — already protected by the `NSLock` introduced in the GCD pass.
    - `OrientationWatcher.instance` — `static var` (not `nonisolated(unsafe)`), reassignable via `OrientationWatcher.setup(windowScene:)`. The class is `@MainActor`, so reads/writes are isolated to the main actor; the only race is whether `setup` ever runs off-main. Left as-is.
- [x] `[FIXED]` **Files vastly exceeding the ~100 line guideline** (top offenders): `Types/SFSymbol.swift` (1804), `Foundation/Date.swift` (553), `Foundation/Date.Time.swift` (349), `Foundation/URL.swift` (330), `Geometry/CGRect.swift` (320), `Foundation/Codable.swift` (241), `UIKit/UIColor.swift` (250), `Foundation/String.swift` (235), `Combine & Async/AsyncSemaphore.swift` (282).
    - `Date.swift` → 5 files in `Foundation/Date/` (`Date.swift` 68, `Date+Components` 102, `Date+Math` 152, `Date+Comparison` 55, `Date+Formatting` 169). `Date+Formatting` is the largest at 169 lines, dominated by the unsplittable `ageString` switch tower.
    - `Date.Time.swift` → 4 files in `Foundation/Date/` (`Date.Time` 190, `Date.Time+Formatting` 49, `Date.TimeRange` 75, `Date+Time` 59).
    - `URL.swift` → 5 files in `Foundation/URL/` (URL/Path/File/Query/Bookmark, none over 110).
    - `CGRect.swift` → 4 files in `Geometry/CGRect/` (core / math / placement / slicing, none over 96).
    - `UIColor.swift` → 3 files in `UIKit/UIColor/` (core / hex / packing).
    - `Codable.swift` → 4 files in `Foundation/Codable/` (core / encoding / decoding / dictionary).
    - `String.swift` → 5 files in `Foundation/String/` (core / subscript / validation / random / array).
    - `AsyncSemaphore.swift` (242 lines): **not split** — single thread-safety-critical class with private value/suspensions/lock state shared across every method; splitting would force those to `internal` and fragment lock-discipline reasoning.
    - `SFSymbol.swift` (1804 lines): **not split** — Swift doesn't allow splitting an enum's cases across files; converting to a struct would break `: CaseIterable` and `switch` exhaustiveness. (Per user direction.)
    - All splits also reorganized so each type's files live in a per-type subdirectory.

---


# Detailed Findings (file-by-file) — Open Work

> **Status:** 89 file sections still labeled `[UNAUDITED]` here — the original review snapshot, not yet re-verified against current code. The other ~212 file sections have been resolved (fixed, false positives, kept-as-is with reasoning, or rendered moot by other refactors) and moved to **`CODE_REVIEW_RESOLVED.md`** in this directory.
>
> Re-audit passes that have produced finding-level tags so far: macros, Foundation M-Z, Utilities, Foundation A-K, SwiftUI batch C, SwiftUI batch B, SwiftUI batch A, SwiftUI batch D, UIKit.


## Package


### `Package.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Platform]** Per `CLAUDE.md`, the framework targets iOS 13+, macOS 10.15+, watchOS 6+, tvOS, and visionOS. tvOS is currently set to `.v13`, but recent commits added "tvOS and visionOS support" — confirm `tvOS(.v13)` is intended (vs `.v14`/`.v15` to match SwiftUI features used elsewhere in the framework). visionOS(.v1) is correct.
- **[Convention]** Mixed indentation (a blend of tabs and spaces) makes this file hard to scan. Several lines use leading tabs while `platforms:`/`products:`/`targets:` use spaces. Worth normalizing.
- **[Suggestion]** swift-syntax is pinned `from: "603.0.0"`. That allows any 603.x.x and up to <604, which is the standard approach but ties build to a recent toolchain. Acceptable, but worth double-checking compatibility on older Xcode.
- **[API]** Test target depends on `SuiteMacrosImpl` directly — fine for macro-expansion testing, but be aware that this couples the test target to the macro plugin module's internal symbols. The plugin product is a `.macro` target, so depending on it from a `testTarget` is the right pattern.
- **[Suggestion]** `.target(name: "Suite", dependencies: ["SuiteMacrosImpl"])`: the macro target is correctly listed as a dependency so the macro plugin is built alongside the library. No issue.
- **[Convention]** Trailing blank line at line 43 inside `targets:` array, and the macro target's stanza is indented differently from the others. Cosmetic only.

## Macro Declarations


## Exported Modules


### `Suite/ExportedModules.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Suggestion]** Re-exports SwiftUI and Combine. Both are guarded by `canImport`. No issues. Note that `@_exported` is an unofficial attribute — Apple discourages public reliance — but the rest of iOS-tooling uses it consistently and it's been stable for years. OK.

## Macro Implementations


## Foundation (A-K)


### `Foundation/Box.swift` — **[UNAUDITED]** _no findings reported_
- No issues.

### `Foundation/Condensable.swift` — **[UNAUDITED]** _no actionable findings_
- **[API]** `Reconstitutable: Condensable` shape — **[KEPT-AS-IS]** intentional design.
- **[Suggestion]** `version >= condensed.version` silent skip — **[KEPT-AS-IS]** documented contract; signaling would change the API shape.

### `Foundation/Date+String.swift` — **[UNAUDITED]** _no actionable findings_
- **[Concurrency]** Per-call `DateFormatter()` — **[KEPT-AS-IS]** allocation cost; not a concurrency bug.
- **[Platform]** No Locale param — **[KEPT-AS-IS]** function name `localTimeString` documents the user-locale dependence.
- **[Bug]** `:00` substring matching locale-fragile — **[KEPT-AS-IS]** edge case for non-Western numeral locales.

### `Foundation/DateTag.swift` — **[UNAUDITED]** _no findings reported_
- No issues.

## Foundation (M-Z)


### `Foundation/OptionSet.swift` — **[UNAUDITED]** _no findings reported_
- No issues.

### `Foundation/Range.swift` — **[UNAUDITED]** _no findings reported_
- No issues.

### `Foundation/Result.swift` — **[UNAUDITED]** _no findings reported_
- No issues.

### `Foundation/Throwable.swift` — **[UNAUDITED]** _no findings reported_
- No issues.

### `Foundation/TimePost.swift` — **[FIXED 74ce1eb]** entirely-commented-out file deleted in earlier typo/cleanup pass.

### `Foundation/URLResponse.swift` — **[UNAUDITED]** _no findings reported_
- No issues.

## Types


### `Types/AsyncBlocker.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** In both `ThrowingAsyncBlocker.update()` and `AsyncBlocker.update()`, the `defer` block resets `continuations = []` before resuming. Since the for-loop runs *before* the defer, this is fine for resumption, but the `defer` ordering is subtle: `defer { isUpdating = false; continuations = [] }` runs after the loop. Correct as-is, but fragile — a future edit moving the resume into a separate Task could leak.
- **[Bug]** Race window in coalescing: a caller arriving between `isUpdating = false` (in defer) and the *next* call to `update()` will start a fresh action — that's intended. But a caller that arrives after the action returns but BEFORE the defer runs (impossible inside an actor — fine on reflection). No bug, but worth noting the assumption.
- **[Bug]** Continuations appended *after* the action completes but *before* the defer clears them will never resume. Inside an actor with non-reentrant calls this can't happen between the loop and the defer, but the action's `await` points permit reentry. Specifically: if `action` itself awaits and another `update()` re-enters during that await, the new caller sees `isUpdating == true` and appends a continuation. When the original action returns and the loop resumes everyone, the new caller is correctly resumed too — so no leak. OK on closer read, but worth a comment to document the invariant.
- **[Suggestion]** The `action` closure should be `@Sendable` since it's stored across actor boundaries.

### `Types/ChangeTracker.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Memory]** `tokens` dictionary entries are never reaped except in `didChange(id:)` when the token is found nil. If `didChange` is never called for a particular ID after its observer goes away, the `WeakToken` entry stays in the dictionary forever. With many short-lived IDs this grows unbounded.
- **[Bug]** In `OnTrackedChangeModifier`, `task?.cancel()` is on `onDisappear` but the previous task is *also* cancelled in `onChange(of: token?.version)` — fine. However, on first appear, `token` is set in `onAppear`, which sets `token?.version` from `nil` to `0` — this triggers `onChange` and fires `callback()` immediately on appearance. That may or may not be desired; if not, it's a bug.
- **[Suggestion]** `let _ = token?.version` in `ObserveIDModifier.body` is a clever way to subscribe to Observation, but a comment explaining why is warranted.

### `Types/CrashPad.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Concurrency]** `Task { ... UserDefaults.standard.set(false, ...) }` is detached and uncancellable. If the app crashes during the sleep window, the `true` value persists — that's the intended behavior. OK.
- **[Bug]** `launchedSafely` performs side effects (`set`, `Task`) on every call. Calling it twice flips state. The doc says "should be called just before restoring state" — assumes single-call. A guard against repeated calls would be safer.
- **[Concurrency]** `Task.sleep(nanoseconds:)` is deprecated in favor of `Task.sleep(for:)` on iOS 16+; minor.

### `Types/DefaultsBasedPreferences.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Concurrency]** Heavy use of KVO + Mirror reflection + UserDefaults from `observeValue` callback (called on arbitrary threads). No synchronization — `defaults.set(...)` is thread-safe but `Notification.postOnMainThread` mitigates only the notify side. No `Sendable` conformance possible.
- **[Bug]** In `load()`, `addObserver` is added every time `load()` is called (init + `willEnterForeground` + `refresh()`). Each call re-adds observers without removing existing ones, leading to multiple-fire on KVO and crashes when `removeObserver` runs only once in `deinit`.
- **[Convention]** 121 lines — slightly over the ~100 guideline.
- **[API]** Mirror-based reflection for KVO is fragile; the macro-based `@AppSettings` approach is recommended in `CLAUDE.md` and supersedes this. Consider deprecating.
- **[Suggestion]** `saveTimer` property is declared but never used.

### `Types/Gestalt+Background.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Platform]** `application?` is a fileprivate `@MainActor` UIApplication holder. The else-branch (non-iOS) provides empty stubs; this is fine for cross-platform compilation. OK.
- **[Suggestion]** `logger` uses `@available(iOS 14.0, ...)`, but the surrounding extension already targets iOS — the availability annotation on a top-level fileprivate is unusual but harmless.

### `Types/Gestalt+watchOS.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `WatchCaseSize` extraction strips trailing "m" but the model strings used are like "Apple Watch Series 7 41mm" → split by space → last is "41mm" → trim "m" → "41" — works. But "larger = 100" sentinel is suspect; if a new size lands (e.g. 50mm), it returns `.larger` silently.
- **[Bug]** No entry for Apple Watch Ultra (49mm is there) or Apple Watch Series 8/9/10. Stale data.
- **[Concurrency]** `WKInterfaceDevice.current()` access in a `static let` initializer is MainActor-isolated in newer SDKs; the `caseSize` is `static let` (not @MainActor), which may now warn under strict concurrency.

### `Types/IdentifiableEnum.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `id` for an enum case with associated values returns just the case name (not including associated values). Two enum values like `.foo(1)` and `.foo(2)` share the same `id` — violates `Identifiable` semantics. The doc/name suggests this is for enums, but with associated-value enums this breaks ForEach uniqueness.
- **[Suggestion]** Should be documented as "for enums *without* associated values" or use a hash that includes the full description.

### `Types/IntSize.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `IntPoint.magnitude` returns `x * y` — that's not magnitude (which would be `sqrt(x*x + y*y)` or at least area). Misleading name.
- **[Bug]** `IntSize(screenW w:_:)` swaps to ensure `width <= height`. Internal-only init so OK, but the doc/name unclear.

### `Types/KeychainBasePreferences.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** Same KVO double-add issue as `DefaultsBasedPreferences` if `refresh()` is called after init.
- **[Bug]** `setValue(value, forKey: label)` on KVO change can re-fire `observeValue`, potentially recursing if the observer doesn't recognize the no-op.
- **[Bug]** `observeValue` ignores `Bool`, `Int`, `Double` types — only stores `String` and `Data`. If a subclass has `@objc dynamic var count: Int`, changes are silently dropped on the keychain side.
- **[Concurrency]** Same lack of thread-safety as `DefaultsBasedPreferences`.

### `Types/LoadingState.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** Custom `==` ignores associated values: `.failed(errorA) == .failed(errorB)` returns true regardless of error identity. Likely intended for state-equality, but it's surprising. Also `.loaded(a) == .loaded(b)` falls into `default` which returns false — so `.loaded` cases are *never* equal to each other, which is also surprising.
- **[Bug]** `Equatable` is not declared on the enum (just an `==` operator). Cannot be used in generic Equatable contexts.
- **[API]** `isLoaded` returns true for both `.loaded` and `.empty` — that's a design choice (data is "ready"), but the name is misleading; consider `isReady` or `hasResolved`.

### `Types/MobileProvisionFile.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Convention]** Entire file is commented out (deprecated). Either remove the file or leave a stub. Currently it consumes a slot but has no compiled code.

### `Types/NetworkInterface.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Concurrency]** `static var allInterfaces` is a computed property doing C calls each time — not `static let`. That's correct (interfaces change), but it's not Sendable-safe across threads (although `getifaddrs` is reentrant per man page). Consider documenting.
- **[Bug]** `String(NSString(cString: hostname, encoding: NSUTF8StringEncoding) ?? "")` is a roundabout conversion and depends on Foundation. The simpler `String(cString: hostname)` (commented out) is safer for null-terminated strings.
- **[Bug]** `addrFamily` filters in callers compare `UInt8(family)` to a `sa_family_t` (`UInt8` on Darwin) — OK on Darwin but fragile if ported.
- **[Suggestion]** No filtering of loopback or link-local — caller sees `lo0`, etc.

### `Types/OnDemandFetcher.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `request.endAccessingResources()` is called only on success; if `JSONDecoder` throws, the resources are never released. Use `defer`.
- **[Bug]** Caches the dictionary in Keychain — peculiar choice (Keychain isn't designed for bulk cache data and survives app uninstalls). UserDefaults or Caches dir would be more appropriate.
- **[Suggestion]** Hardcoded `loadingPriority = 1` is the maximum — ensure that's intended.

### `Types/Point.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[API]** Just `Equatable` — no `Hashable`, `Codable`, or `Sendable` despite being trivially conformable. Compare with `IntPoint` in `IntSize.swift` which is a duplicate. Two structs serving the same purpose; consolidate.
- **[Convention]** Custom `==` is unnecessary; default synthesized `Equatable` would suffice.

### `Types/RawCodable.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `RawCodable` requires `Identifiable` and conforms `id = rawValue`. But if `RawValue` is `String`, two enum cases with the same rawValue (impossible by definition) — fine. But forcing Identifiable is restrictive; some users may want their own `id`.
- **[Suggestion]** `RawCodableError` is internal but the protocol is public — decoding errors thrown to the caller will be opaque.

### `Types/SFSymbol.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Convention]** 1804 lines — vastly exceeds guideline. Auto-generated data dictionary, but Apple now provides `Image(systemName:)` with broad coverage and Apple's own SF Symbols framework. Recommend deprecating or splitting by category file.
- **[Bug]** Many entries marked "Usage restricted to ..." (Apple App Store rules) are exposed as public cases — App Store reviewers may reject apps that ship these symbols outside the allowed contexts.
- **[Perf]** Compiling this file is slow (1804 cases). Consider moving to a generated resource bundle.

### `Types/SharedDependencyManager.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Concurrency]** Manual `os_unfair_lock` via `UnsafeMutablePointer` — this is correct but verbose. Modern Swift offers `OSAllocatedUnfairLock` (iOS 16+). Recommend migrating once min target allows.
- **[Bug]** In `register`, `case .default: if replace == .default { fatalError(...) }` — the outer `case .default` already implies `replace == .default`, so the inner check is redundant. The logic is correct but reads as a typo.
- **[Bug]** `ReplacementRule.single` policy: "current.isDefault → allow replace; not default → fatalError". So registering twice as `.single` crashes — that's harsh for a framework-level singleton; consider returning a Bool or throwing.
- **[Concurrency]** `SharedDependency` property wrapper resolves on every access (no caching); each access takes the lock. For hot paths this is contention.
- **[Memory]** `dependencies: [String: Any]` keyed by `String(describing: T.self)` — a generic struct used with two type parameters distinguishes properly, but `String(describing:)` on generic types can produce ambiguous keys for nested types. Consider `ObjectIdentifier` for class types or `_typeName` for stable keys.
- **[API]** `@unchecked Sendable` is justified given the lock, but a comment to that effect would help.

### `Types/Titleable.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- No issues.

## Utilities


### `Utilities/JSON/JSONEncoder.swift` — **[UNAUDITED]** _no findings reported_
- No issues.

### `Utilities/WKWebView.swift` — **[UNAUDITED]** _no findings reported_
- No issues.

## SwiftUI / View Extensions, Modifiers, Wrappers


### `SwiftUI/View Extensions/GeometryReader.swift` — **[UNAUDITED]** _no findings reported_
- No issues.

### `SwiftUI/View Extensions/View+Debug.swift` — **[UNAUDITED]** _no actionable findings_
- **[Concurrency]** Log on every render — **[KEPT-AS-IS]** `View.log()` is explicitly a debug helper.

### `SwiftUI/View Modifiers/NotYetImplemented.swift` — **[UNAUDITED]** _no findings reported_
- No issues.

### `SwiftUI/View Wrappers/AsyncContainerView.swift` — **[UNAUDITED]** _no actionable findings_
- **[Concurrency]** No `@Sendable` on `function` — **[KEPT-AS-IS]** breaking signature change.
- **[API]** No issues — confirmed.

## SwiftUI / Other Views, Observers, Gestures, Navigation


### `SwiftUI/Other Views/CalendarMonthView/CalendarWeekDayLabel.swift` — **[UNAUDITED]** _no findings reported_
- No issues.

## Combine & Async


### `Combine & Async/AsyncSemaphore.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Convention]** 240+ lines — well over the ~100-line guideline. Could split `Suspension`, `wait`, and `waitUnlessCancelled` into separate files.
- **[Bug]** `suspensions.insert(at: 0)` + `popLast()` (lines 124, 174, 227) — comments say "FIFO" but inserting at 0 and popping from the end gives LIFO order. Either the comment or implementation is wrong; based on intent the comment is right but you should pop first or insert at end.
- **[Suggestion]** Attribution is good (groue/Semaphore). Otherwise sound.

### `Combine & Async/Binding.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Convention]** Line 85-86: ugly multi-line declaration of `inverted` with closing `}) }` jammed together; reformat for readability.
- **[API]** `Binding(_ boolProvider:)` (line 88) constructs a Binding with no setter — silently swallows writes. This can be surprising; consider naming `init(get:)` or document loudly.
- **[Suggestion]** `bool(default:)` on line 59 — missing space before `{`.

### `Combine & Async/CurrentValueSubject.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Concurrency]** `extension CurrentValueSubject: @unchecked @retroactive Sendable` — broad retroactive Sendable conformance on an Apple type can collide if Apple later marks it Sendable; works but flagged as fragile.
- No other issues.

### `Combine & Async/Loadable.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- No issues.

### `Combine & Async/ObservableObjectPublisher.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Memory]** `ObserverMonitor` stores `cancellable` as a struct property and assigns inside `init`. Because `ObserverMonitor` is a `View` (struct, value type) created on each render, the cancellable is recreated every render and the previous one is dropped — leaks/duplicate logging are likely. Subscriptions like this don't belong on a `View` struct; use `.onReceive`/`.task` or a `@StateObject` wrapper.
- **[API]** `monitor(message:)` on line 60 calls `eraseToAnyPublisher().onSuccess()` but discards the resulting subscription — the `Subscribers.Sink` will be released immediately. This is broken.
- **[Concurrency]** `sendOnMain()` uses `Thread.isMainThread` then `MainActor.run` synchronously from arbitrary contexts — `MainActor.run` is async and not called via `await`; this likely doesn't compile under strict concurrency or silently ignores the call. Verify.
- **[Convention]** Mixed availability annotations (`OSX 11` vs `macOS 11`).

### `Combine & Async/ObservableObserver.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Memory]** `target.objectWillChange.sink { _ in self.update() }` (line 22) — strong-captures `self`, retain cycle: `self` -> `cancellable` -> closure -> `self`. Use `[weak self]`.
- **[Concurrency]** `check: () -> Bool` is not marked `@Sendable` and the class is `@MainActor` — fine in practice but the closure stored is non-Sendable if the type is later relaxed.
- **[API]** `target` parameter is unused after init (only `target.objectWillChange` captured) — fine, just noting.

### `Combine & Async/Subscription.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Concurrency]** Global `var SubscriptionBag` annotated `@MainActor` — works under strict concurrency, but a single global bag means cancellables are never freed unless rotated by key. Method ignores `key` (line 19) — `sequester(_ key:)` doesn't actually use the key. Misleading API.
- **[API]** `key` parameter is dead. Either implement keyed storage (dictionary of sets keyed by key) or remove the parameter.

## AppKit


### `AppKit/NSAlert.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Concurrency]** `MainActor.run { ... }` on line 16 inside a non-async function is incorrect — `MainActor.run` returns an async closure result. This compiles only with implicit discard; under strict concurrency this is a warning/error. `Task { @MainActor in ... }` would be correct.
- **[API]** `showAlert` and `show(in:completion:)` don't expose a `default`/`cancel` button distinction nor return a value; consider an `async` variant.
- **[Convention]** Multi-line function signature on line 14 is borderline.

### `AppKit/NSApplication.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Concurrency]** `DisableSleep` is `@MainActor`, but `NSApplication.sleepDisabled` set/get accessors aren't isolated — calling from non-main contexts will blow up. Mark the extension property `@MainActor` or guard.
- **[Bug]** `disableScreenSleep` reuses `sleepDisabled` as both "should be disabled" and "successfully disabled" (line 37). If `IOPMAssertionCreateWithName` fails, `sleepDisabled` stays `false` which is OK, but `assertionID` may have been written. Acceptable but a clearer second flag would help.
- **[Convention]** File is fine size-wise.

### `AppKit/NSButton.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- No issues.

### `AppKit/NSEvent.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- No issues.

### `AppKit/NSView.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `backgroundColor` getter accesses `self.layer?.backgroundColor` without `wantsLayer = true` — fine, returns nil if no layer, but setter sets `wantsLayer = true` while getter doesn't. Asymmetric.
- **[Convention]** `if #available(OSX 10.14, ...)` always true since deployment is 10.15+. Dead branch.

### `AppKit/PasteboardMonitor.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** Line 42: `addObserver(forName:...)` closure parameter shadowed as `timer` — should be `_ in` or `note in` (it's a Notification, not a Timer). Confusing typo.
- **[Memory]** Notification observer token is never stored and never removed; the `MainActor`-isolated singleton leaks an observer reference. Since this is a singleton with `static let instance`, this is acceptable in practice, but if anyone instantiates more `PasteboardMonitor`s, leaks ensue. Consider `private init` to enforce singleton.
- **[Memory]** Same for `Timer.scheduledTimer` — never invalidated unless `self` is nil. With singleton lifetime this is fine.
- **[Perf]** Polling every 1s for pasteboard is wasteful when the app is backgrounded. Consider only polling while frontmost (you already observe activation; you could stop the timer on resign-active).
- **[API]** `init(pollInterval:)` is `public` but the type is documented as a singleton (`static let instance`) — second instances are possible and dangerous given the shared observer/timer. Make `init` private.
- **[Concurrency]** `Timer.scheduledTimer` block runs on the main runloop; calling `Task { @MainActor in self.checkForChanges() }` is unnecessary indirection — within main runloop you're already on main thread; can call directly with `MainActor.assumeIsolated`.

## Cocoa


### `Cocoa/ErrorHandling.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Concurrency]** `@MainActor extension Error` adds main-actor isolation to `display(...)`. The `completion` is `@Sendable` but the closure passed to `beginSheetModal` captures it without crossing actors — fine under main actor, but the modal `runModal()` blocks the main thread, which is exactly what main-actor isolation is supposed to discourage.
- **[Suggestion]** Extracting an async variant `func display(in:) async -> Int` would be much nicer than a completion handler.
- **[Convention]** Logic is duplicated for sheet vs modal — extract a `finish(_:)` like NSAlert.swift does.
- **[Platform]** `#if !canImport(UIKit)` is brittle — Catalyst can import both. Prefer `#if canImport(AppKit) && !targetEnvironment(macCatalyst)` for consistency with neighboring files.

### `Cocoa/NSImage.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Concurrency]** `scaledImage(newSize:)` uses `lockFocus()`/`unlockFocus()` — these are main-thread only, but the function is not `@MainActor`. Will misbehave off the main thread.
- **[Bug]** In `resized(to:trimmed:changeScaleTo:)` the `changeScaleTo` parameter is accepted but never used (line 26).
- **[Convention]** Trailing semicolons on lines 36, 37, 44 (`frame.origin.x = 0;`) — non-Swift style.

### `Cocoa/NSTextFieldAndView.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Convention]** `editabled(_:)` (line 42) — typo, should be `editable(_:)`.
- No other issues.

## Geometry


### `Geometry/CGAngle.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `angle` formula uses sides `ab`, `bc`, `ac` and computes the angle at vertex `B` via `acos((ab^2 + bc^2 - ac^2) / (2*ab*bc))`. That is the law of cosines for angle at B (opposite side `ac`) — correct math, but the type is named `CGAngle` with three points `a, b, c`, and there is no doc clarifying which vertex's angle is computed. **[API]** Misleading: a consumer could reasonably expect the angle at `a` or `c`. Add documentation or rename.
- **[Bug]** No protection for degenerate cases: if `a == b` (`ab == 0`) or `b == c` (`bc == 0`), denominator is 0 → NaN/inf. If the law-of-cosines argument falls outside `[-1, 1]` (floating point), `acos` returns NaN. Should clamp or guard.

### `Geometry/CGFloat.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[API/Bug]** `shortDescription` uses `"%.0f"` which truncates everything to integers (e.g. 3.7 → "4", 0.001 → "0"). Name suggests "short" rather than "integer rounded"; misleading.

### `Geometry/CGLine.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Convention]** 229 lines — exceeds the ~100 LOC guideline. Could split (StringInitializable, Hashable, intersection helpers).
- **[Bug]** `Equatable`'s `==` uses approximate equality (`≈≈`) but `hash(into:)` hashes exact `start` and `end`. Two equal-by-`==` lines can have different hashes — violates `Hashable` contract.
- **[Bug]** `init(start:length:angle:)`: the `while degrees > 360` loop will not handle `degrees == 360` correctly (loop runs once, becoming 0), and the comparisons against `90/180/270/360` use exact float equality on a value that may have been produced by repeated subtraction — small floating point errors will fall into the trig branch instead. Use `truncatingRemainder(dividingBy: 360)` and tolerance comparisons.
- **[Bug]** `slope` divides by `vector.x`; will be `inf`/NaN for vertical lines — no guard. Caller must know.
- **[Bug]** `quadrant` returns 1 when `dy <= 0`, 2 when `dy > 0`, etc. — but lines exactly on an axis (dx == 0 or dy == 0) are mapped silently into one of the four quadrants, which then feeds `angle`. That branch is reached only after the early-return for `vector.x == 0` / `vector.y == 0` in `angle`, so okay there, but `quadrant` itself is misleading on its own.
- **[Bug]** In `angle`: `case 1: return .degrees(360) - .radians(basis.radians * -1)` simplifies to `360° - (-basis)` = `360° + basis`. This goes outside `[0, 360)` whenever basis is positive, and in quadrant 1 (dx>0, dy<0 in this code's flipped Y) the expected angle is `360° - |basis|`, which is `.degrees(360) + basis` only if `basis` is negative — fragile and confusing. Verify and add tests.
- **[Bug]** `linesCross`: uses `> 0 && < 1` (strict) which excludes intersections exactly at endpoints. The pre-checks at the top of `intersection(with:)` only handle pairwise endpoint equality, not "line A endpoint sitting on line B's interior." Edge cases will return `nil`.
- **[Bug]** `init?(rawValue:)` calls `rawValue.trimmingCharacters(in: .decimalDigits.inverted)` — this strips commas, parentheses and minus signs, breaking negative coordinates and the `(...,...)` separator. Likely doesn't actually parse the format produced by `stringValue`.
- **[Bug]** `midpoint` setter uses old `midpoint` after computing `startDelta`/`endDelta`; reads `midpoint` again to compute `endDelta`. The math: `start = newValue + (midpoint - start)` translates start to `newValue + (midpoint - start)` rather than `start + (newValue - midpoint)`. End up shifting both points by the wrong delta unless the line is symmetric about midpoint. Rewrite as `let delta = newValue - midpoint; start += delta; end += delta`.

### `Geometry/CGPath.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `boundingSize` force-unwraps `xs.max()!` / `ys.max()!` after checking `points.isEmpty`. Safe given the guard, but minor.
- **[Suggestion]** Could use `applyWithBlock` to compute bounds without materializing a `[CGPoint]`.

### `Geometry/CGPoint.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `nearestPoint(on:)` sets `distanceFactor = -1` for zero-length lines, then early-returns `line.start` — which is correct (line.start == line.end here). But the `< 0` and `> 1` clamps for non-degenerate lines correctly clamp to endpoints. Looks ok.
- No major issues.

### `Geometry/UnitPoint.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Platform]** `UnitPoint` is a SwiftUI type but the file imports only Foundation. Likely compiles via implicit re-export, but should `import SwiftUI` for clarity.

## Logging


### `Logging/Logger.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `static let suiteLoggerSubsystem = Bundle.main.bundleIdentifier! + ".suite"` force-unwraps `bundleIdentifier`. In test bundles, command-line tools, and some app extensions this is `nil` and crashes at module load.
- **[Convention]** Top-level `let SuiteLogger` capitalized as if a type; might shadow the legacy `SuiteLogger` class in `SuiteLogger.swift` — confusing dual naming. Actually the legacy one is named `OldSuiteLogger`, so no shadow, but the global variable named `SuiteLogger` is then referenced from `ModelContext.swift` (`SuiteLogger.error(...)`) — works only if iOS 14 / macOS 12 are available. Add doc comment.
- **[Concurrency]** `let SuiteLogger = Logger(...)` at file scope is fine for `os.Logger` (Sendable), but file-internal `let` global is technically OK in Swift 6 only because Logger is Sendable.

### `Logging/Slog.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `disabled = true` by default. With no public way to enable on `instance` other than `setEnabled`, the actor swallows all `record` calls silently until enabled. Document or default to enabled.
- **[Concurrency]** `slog(_:color:)` fires `Task { ... }` with no ordering guarantee — log lines can land out of order. Use a serial queue/actor pattern that preserves order, or document.
- **[Convention]** `let logger = Logger(subsystem: "suite", category: "general")` is initialized but never used — dead code.
- **[Bug]** `setEchoCallback` keeps a `@MainActor (String) -> Void` closure that may capture `self` of the caller — leak risk if not cleared. Document `clearEchoCallback`.
- **[Concurrency]** `printLogs = Gestalt.isAttachedToDebugger` reads at actor init off any task; if `Gestalt` is `MainActor`-isolated, this would race. Verify.

### `Logging/SlogButton.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Convention]** Filename header says "File.swift" — copy-paste leftover.
- **[Platform]** `#if os(iOS) || os(macOS)` excludes watchOS/tvOS/visionOS; SlogScreen has same gating, ok.

### `Logging/SlogScreen.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `Picker` selection of `Slog.File?` with `Optional.some(file).tag(...)` will not have a tag for `nil` — picker may be in undefined state when current is `nil`. Add a `.tag(Slog.File?.none)` row or supply a Sentinel.
- **[Bug]** "Clear Log" calls `current.removeLog()` (nonisolated) immediately, but if the current file is the actively-logging `Slog.instance.file`, the actor will continue writing and resurrect the file. Should also clear/replace the active file.
- **[Bug]** `files.remove(current)` — relies on `Hashable`/`Equatable` on `Slog.File` (an actor). Actors are Equatable/Hashable here via custom impl (`==` on URL), good.
- **[Concurrency]** `current = await Slog.instance.file ?? files.first` — fine.

### `Logging/SlogView.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `await file.load()` early-returns when `lines` is non-empty (see Slog.File.load), which is not communicated; on second `onChange`, you may show stale data. Maybe intended.
- **[Convention]** `ForEach(lines.indices, id: \.self)` is anti-pattern; use `ForEach(lines) { line in ... }` with `Identifiable` (Line conforms). Index-based ForEach breaks animation on insertion.

### `Logging/SuiteLogger.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
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


### `Property Wrappers/CodableFileStorage.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** Default `equal(_:_:)` returns `false` always (when StoredValue is not Equatable). This means non-Equatable types perform a write on *every* `set` — even setting the same value re-writes the file. Compare encoded data instead, or document.
- **[Bug]** `data == "null".data(using: .utf8)` is intended to delete the file when value is `nil` — but JSONEncoder may emit `null\n` or with surrounding whitespace depending on options; comparison is fragile. Better: in the Optional convenience init, explicitly check `newValue == nil`.
- **[Bug]** `try? data.write(to: url)` — non-atomic write; partial writes can corrupt the file. Use `.atomic`.
- **[Bug]** No directory creation: if `url`'s parent directory doesn't exist, the write silently fails (because of `try?`). Either log or pre-create the dir.
- **[Suggestion]** No file-coordination — concurrent processes (extension + app) writing to the same URL can race.

### `Property Wrappers/NonIsolatedWrapper.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[API]** Wraps a `ThreadsafeMutex` in `@State`. SwiftUI `@State` re-uses storage across view rebuilds, but `State` is itself not thread-safe; the wrapper relies on `ThreadsafeMutex.value` for synchronization which is fine. Setting `wrappedValue` does not call `value.objectWillChange` or anything to trigger re-renders — name suggests it's deliberately non-observed, which is correct. Document that.

### `Property Wrappers/ObservedValue.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `update()` is called from `init`, which spawns a `Task { @MainActor in ... }` referencing `_wrappedValue` — that's `@State` storage not yet attached to a view. SwiftUI guidance: do not write to `@State` from `init`. May produce a runtime warning ("Modifying state during view update is not allowed") or be lost.
- **[Bug]** `MutableObservedValue.projectedValue` setter spawns a detached `Task { ... }` that calls `set(target, value)` — but `wrappedValue` (the `@State`) is not optimistically updated, so the binding's get returns the stale value until the next `update()` after the ObservableObject's publisher fires. UI feels laggy.
- **[Concurrency]** `Task { await self.set(self.target, value) }` captures `self` by value (struct). Fine for a struct property wrapper, but ensure `Target` and `closure` Sendability holds.
- **[Memory]** `@ObservedObject var target: Target` — the property wrapper holds a strong reference to `target`; if the calling view owns `target`, no cycle, but if `target` later captures the view, watch out.
- **[API]** Two property wrappers in one file share a lot of code; suggest factoring or document.

## Widgets


### `Widgets/WidgetFamily.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Convention]** 111 lines — borderline. Many hard-coded dimensions per device — but as widget sizes are a published Apple table, this is correct usage. Still flagging:
- **[Convention]** Hard-coded dimensions throughout. The framework guideline says "avoid hard-coded dimensions"; here they're justified because Apple specifies widget sizes per device, but the table is incomplete (no iPhone 16, no 13 series, no iPad mini after 6th gen, no `accessoryRectangular`/`accessoryCircular`/`accessoryInline` cases). Will return wrong sizes silently for new devices.
- **[Platform]** Uses `UIScreen.main` — deprecated since iOS 16 in multi-scene apps. `UIScreen.main.bounds.size` returns the screen of the first connected scene; widgets typically run in their own process anyway, where `UIScreen.main` is the host's screen. Behavior is questionable.
- **[Bug]** `case .iPhone15Pro, .iPhone14Pro` reused with `iPhone12` for systemMedium and systemLarge — those phones have different screen sizes (iPhone 14 Pro is 393×852, 15 Pro is 393×852, 12 is 390×844). Lumping all into 338×158 is incorrect.
- **[Bug]** `.systemExtraLarge` on iPhone falls through `default: return CGSize(width: 360, height: 379)` — but `.systemExtraLarge` is iPad-only; should not be reachable for iPhone screens. If reached returns something that looks like systemLarge.
- **[Platform]** `#if canImport(WidgetKit) && !os(visionOS) && !os(tvOS)` — does not exclude watchOS even though `WidgetFamily` on watchOS uses `accessory*` cases that aren't switched here. The `#if os(watchOS)` branch uses a constant 40×40 regardless of family — inaccurate.
- **[API]** `@MainActor` extension forces all callers onto the main actor for what is essentially a constant lookup.

## SwiftData


## Tests


### `Tests/SuiteTests/AnyEquatableTesting.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- No issues. Filename `AnyEquatableTesting` is slightly off (most others are `*Tests.swift`); minor [Suggestion] to rename for consistency.

### `Tests/SuiteTests/ArrayExtensionTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `testCollectionSplitByKeyPath` (line 193-202) doesn't actually verify that `split(by:)` produces both groups, only that count is 2 and that the age-25 group is correct. The age-30 group is never asserted, so a regression that conflates groups by accident could go undetected.
- **[Suggestion]** `testIdentifiableSubscript` (line 117) uses `items[1]` after writing — could be clearer with `items[id: searchItem]?.name == "Updated"` to test the read path of the same subscript being exercised on write.
- **[Coverage]** `breakIntoChunks(ofSize:growth:)` only tests one growth factor (2.0); fractional or zero growth is untested.
- File length: 204 lines — exceeds the ~100-line guideline ([Convention]).

### `Tests/SuiteTests/AsyncSemaphoreTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Flakiness]** Multiple tests depend on `Task.sleep(nanoseconds: 50_000_000)` / `100_000_000` to assume a task has reached suspension. Under load (CI runners, sanitizers) these can race. Examples: `signalResumesTask` (line 51), `cancellationRestoresValue` (lines 162/167), `fifoOrdering` (line 107). Prefer an explicit synchronization primitive (e.g. another semaphore signaled inside the spawned Task) or restructure to remove the sleep.
- **[Bug]** `fifoOrdering` (line 87) — name says FIFO, but the assertion only checks set membership (`Set(results) == Set(0...4)`). Either rename the test or actually assert ordering.
- **[Concurrency]** `blocksOnZero` (line 27) writes `completed = true` on whatever actor the test runs on, then reads it from the same path — works but the spawned `Task` captures `semaphore` (a class) implicitly; OK, but the assertion is trivially true since the line after `await wait()` always runs. The test does not really verify "blocking" — it just verifies `wait` eventually returns. Consider asserting elapsed time ≥ 100ms.
- **[Concurrency]** `multipleWaitsAndSignals` (line 65) has the same shape — `completed` is always true after `wait()` returns.
- File length: 282 lines ([Convention]).

### `Tests/SuiteTests/CoreGraphicsExtensionTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `testRoundCGFloat` (lines 132-137) — function is named `roundcgf` but expectations behave like `floor`, not `round` (3.7 → 3.0, 0.9 → 0.0, -2.8 → -3.0). If the implementation truly does floor, the test name is misleading; if it's supposed to round, the assertions are wrong. Verify against the implementation.
- **[Suggestion]** `testCGRectStringInitializable` (line 58) only checks substring presence ("contains 1, 2, 3, 4") — would also pass if values were swapped. A round-trip via `CGRect(stringValue:)`/init from rawValue would be stronger.
- File length: 137 lines ([Convention]).

### `Tests/SuiteTests/CoreGraphicsTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- No issues.

### `Tests/SuiteTests/Date.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Platform]/[Flakiness]** Many tests use `Date(calendar: .current, ...)`. `.current` depends on user locale/timezone, so e.g. `firstDayInWeek` (line 261) can be Sunday or Monday depending on locale — assertion against `Date.DayOfWeek.firstDayOfWeek` papers over this but `lastDayInMonth` for June being 30 (line 109) and `dayOfMonth` arithmetic could shift across DST transitions. Prefer a fixed `Calendar(identifier: .gregorian)` with `TimeZone(identifier: "UTC")`.
- **[Bug]** `testHourMinuteString` (line 252) — assertion `string.contains("14") || string.contains("2")` is far too lax; "2" appears in many strings (e.g., "02:00 PM" contains "2"). It almost cannot fail.
- **[Bug]** `testDateOnlyTimeOnly` (line 228) — `#expect(timeOnly == date)` looks wrong. `timeOnly` should presumably strip date components; expecting equality to the original `date` either reveals the implementation is a no-op or the test is wrong.
- **[Bug]** `testISO8601String` (line 134) uses parameter name `iso8691String:` — likely a typo (should be `iso8601String:`). If the API really has the typo, that's an [API] bug worth flagging.
- **[Coverage]** `testDayOfWeek` (lines 112-118) sets a value but never asserts on it.
- **[Suggestion]** `testNearestSecond` (line 53): 123.456 → 123.0 looks like floor not round — verify implementation matches name.
- **[Convention]** Filename `Date.swift` shadows Foundation's `Date` and doesn't follow `*Tests.swift` pattern.
- File length: 264 lines ([Convention]).

### `Tests/SuiteTests/DictionaryTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Coverage]** Only one test for the entire Dictionary extension surface area. Many extensions on Dictionary in Suite are untested.
- **[Bug]** `dict3["C"]` is `["1", 3]` (an array of mixed types) while `dict1["C"]` is `["1": 3]` (a dict). Asserting `diff1To3.count == 2` is opaque — there's no documentation of what diff returns when types disagree, so this is a brittle "golden number" test.

### `Tests/SuiteTests/EnhancedMacroTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Coverage]** This file is essentially a placeholder (`#expect(Bool(true))`). The comment notes that real macro testing was disabled due to SwiftSyntaxMacrosTestSupport/XCTest dep issues. Consider deleting since `MacroTests.swift` already does the same placeholder, or restoring real macro expansion tests now that Swift Testing is mature.

### `Tests/SuiteTests/GestaltTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Suggestion]** Many tests are tautologies: e.g. `#expect(isSimulator == true || isSimulator == false)` (line 32), `debuggerAttachment`, `previewDetection`, `unitTestsDetection`. They only verify the property is accessible and returns a Bool — which compilation already guarantees. Remove or replace with meaningful assertions (e.g., `#expect(Gestalt.isOnSimulator == true)` under a simulator-only guard).
- **[Bug]** `platformExclusivity` (line 54-63) does not include iPad/iPhone in the list, so on iOS the `trueCount <= 1` check is effectively `0 <= 1` and trivially passes.
- **[Suggestion]** `buildDate` (line 117): `buildDate < Date()` will fail on systems where the build artifact's mtime is in the future (clock skew on CI). Consider asserting non-nil only, or `buildDate < Date().addingTimeInterval(60)`.
- File length: 140 lines ([Convention], minor).

### `Tests/SuiteTests/JSON+Codable.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `testDictionaryCoding` (lines 31-38) — encodes/decodes but never asserts that decoded values match originals. The only assertion is `!data.isEmpty`. False-positive risk: any non-throwing encode passes.
- **[Bug]** `testCodableJSONDictionary` (lines 45-57) uses `try!` twice (lines 52, 55) which crashes the whole test process on failure rather than reporting a clean test failure. Use `try` with throwing test, or `#require`.
- **[Convention]** Filename `JSON+Codable.swift` doesn't follow `*Tests.swift`. Struct name `JSON_Codable` uses underscore.

### `Tests/SuiteTests/JSON+Hashing.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Convention]** Filename `JSON+Hashing.swift` and struct `Test` (line 17) — a struct named `Test` is too generic and may collide.
- **[Suggestion]** Trailing TODO comment on line 34 ("Write your test here…") — leftover from template. Remove.

### `Tests/SuiteTests/LoadingStateTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]/[Concurrency]** `testSendableConformance` (line 94) spawns a `Task` but never awaits it. The `#expect` inside may run after the test ends; if the task fails the test won't report failure. Either await the task or remove (Sendable conformance is a compile-time check anyway — this test adds nothing).
- **[Bug]** `testLoadingStateEquality` comment on line 30 ("compares case, not associated value") — the test never verifies that two `.failed` cases with *different* errors are still considered equal. If equality really only compares the case, write that assertion explicitly: `#expect(.failed(errorA) == .failed(errorB))`.
- File length: 106 lines (borderline OK).

### `Tests/SuiteTests/MacroTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Coverage]** Placeholder only, no real tests. Same comment as `EnhancedMacroTests.swift` — restore actual macro expansion tests.

### `Tests/SuiteTests/NumericExtensionTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `fixedWidthBytes` (lines 53-62) assumes big-endian byte order (`bytes[0] == 0x12`). On Apple silicon (little-endian), if `bytes` returns native order this would be `[0x78, 0x56, 0x34, 0x12]`. The assertion may pass only if the implementation explicitly converts to big-endian — verify and document the contract.
- **[Bug]** `individualBytes` (lines 78-85) and `characterCode` (lines 88-93) make the same endian assumption.
- **[Bug]** `durationStringSimple` and three sibling `durationString*` tests (lines 167-200) assert only `!string.isEmpty`. They do not verify the formatted output is correct (e.g., 60s → "1:00"). Strengthen by asserting actual expected strings.
- File length: 208 lines ([Convention]).

### `Tests/SuiteTests/OptionalExtensionTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Suggestion]** `testOptionalUnwrap` (lines 36-50) uses `#expect(Bool(false), …)` to indicate failure. Prefer `Issue.record(…)` or `#require(…)` patterns idiomatic to Swift Testing.
- File length: 137 lines ([Convention]).

### `Tests/SuiteTests/ReadyFlagTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Flakiness]** Heavy reliance on `Task.sleep` to coordinate (`startsNotReady` line 28, `multipleWaiters` line 70, `setTrue` line 92, `setFalse` line 114, `sequentialFlags` line 138/145, `concurrentWaiters` line 170). Each is a flake risk on slow CI. Replace with an explicit barrier (e.g., a child semaphore) when possible.
- **[Concurrency]** `startsNotReady`, `setTrue`, `setFalse` write `completed` from a spawned `Task` and read it from the test. `var completed = false` is a non-isolated capture. Despite `@MainActor` on the suite, the spawned `Task {}` may inherit MainActor — verify; if not, this is a data race, even if it appears to work.
- **[Concurrency]** `setFalse` (line 102) reads `completed` after only a 50ms wait. If the test were to fail, it would do so silently because we never make the flag ready or cancel the spawned waiter — the leaked task continues. The check only proves "still false after 50ms," which is also a [Flakiness] property.
- File length: 178 lines ([Convention]).

### `Tests/SuiteTests/SharedDependencyManagerTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Coverage]** Only one test, and it doesn't assert anything — it just registers a dependency. Add reads/lookups, scoping, double-registration, etc.
- **[Bug]** Test only verifies that `register(_:_:)` does not throw/crash — no `#expect` on retrieval.

### `Tests/SuiteTests/StringExtensionTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `testStringInitFromData` (lines 92-96): `String(data: data, encoding: .utf8)` is the standard Foundation initializer; `String(data: nil, encoding: .utf8)` requires the data parameter to be optional. If Suite adds an optional-data init, the test name and intent are unclear. Confirm what extension is being exercised.
- **[Suggestion]** `testPathExpansion` (line 113-121) — line 119 `let _ = expandedPath.abbreviatingWithTildeInPath` tests nothing. Either assert behavior or remove.
- **[Coverage]** Email/phone validation only happy-path on common formats; no Unicode emails, IPv6-bracket emails, or international phone formats.
- File length: 122 lines (borderline OK).

### `Tests/SuiteTests/SwiftUIComponentTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** Several tests (`testAsyncButtonInitialization` line 32, `testLoadingViewInitialization` line 66, `testMockLoadingViewStates` line 135, `testViewExtensionsCompile` line 143) end with `#expect(Bool(true))`. These are no-op tests — they only verify compilation. Either remove or assert something meaningful (e.g., observable state changes via ViewInspector or by reading published properties).
- **[Bug]** `testButtonIsPerformingActionKey` (lines 22-25): the comment says "OR operation should keep true" but the reduce semantics typically *replace* with `nextValue()` in SwiftUI's PreferenceKey contract. Verify the implementation actually does an OR — if it just calls `value = nextValue()`, the assertion at line 25 `#expect(value == true)` would fail. (The test passing currently confirms one or the other, but the assertion at line 28 with `false → false` is consistent with both replace and OR semantics, so this only weakly proves OR.)
- **[Suggestion]** `if(_:transform:)` is redefined locally in the test file (lines 165-173). If Suite already provides this extension (likely), the test is shadowing production code. If not, this is a bug being smuggled into the test target.
- File length: 173 lines ([Convention]).

### `Tests/SuiteTests/ThreadsafeMutexTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Platform]** All tests gated `@available(iOS 16, watchOS 9, macOS 14, *)`. On older OSes the entire suite is silently skipped. CLAUDE.md says iOS 13+ minimum — confirm the type itself is gated to those versions; otherwise add a fallback test.
- **[Coverage]** No test for read contention (only write-write). Reentrancy / nested `perform` calls are not exercised.
- No further issues.

### `Tests/SuiteTests/VersionStringTests.swift` — **[UNAUDITED]** _original review snapshot; not re-verified._
- **[Bug]** `testVersionStringInitialization` (line 121-124): asserts `complexVersion != otherVersion` for `"1.2.3-beta.1"` vs `"1.2.3"`. Earlier (`testVersionStringWithInvalidComponents` line 73-77) asserts that non-numeric parts are filtered out, in which case `1.2.3-beta.1` should equal `1.2.3`. These two tests appear contradictory — verify which behavior is correct.
- **[Bug]** `testVersionStringEdgeCases` line 86-88 asserts `"1 . 2 . 3"` (spaces between components) equals `"1.2.3"` — this depends on whitespace stripping that may or may not be intended; document/verify.
- File length: 126 lines ([Convention], minor).

### Cross-cutting notes
- **[Convention]** All test files already use Swift Testing — good. No XCTest violations to flag.
- **[Convention]** Many files exceed ~100 lines (Date 264, AsyncSemaphore 282, Numeric 208, Array 204, ReadyFlag 178, SwiftUI 173). Consider splitting by sub-feature.
- **[Coverage]** Macros currently have no real expansion tests (placeholders only). Per CLAUDE.md the macro system is a key feature — restoring `SwiftSyntaxMacrosTestSupport` tests should be a priority.
- **[Flakiness]** `Task.sleep`-based coordination appears across `AsyncSemaphoreTests`, `ReadyFlagTests`, and `LoadingStateTests`. A shared helper using an `AsyncSemaphore` or `CheckedContinuation` would reduce flake surface area.
