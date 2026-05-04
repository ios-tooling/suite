# Agents.md

Operating manual for AI agents working in this repo. Read this **before** making changes; many surprising-looking patterns here are deliberate and have been triaged.

`CLAUDE.md` covers architecture; this file covers conventions, triaged decisions, and pitfalls.

---

## Quick orientation

- **Package**: `Suite` — multi-platform utility framework. Targets in `Package.swift`: iOS 13, macOS 10.15, watchOS 6, tvOS 13, visionOS 1.
- **Build**: `swift build` (cross-platform validation: `xcodebuild -scheme Suite -destination 'generic/platform=iOS' build`).
- **Test**: `swift test`. Filter: `swift test --filter ReadyFlagTests`. Tests use **Swift Testing** (`@Test`, `#expect`, `#require`), not XCTest.
- **No new files unless required.** Prefer editing existing files.
- **Never push** — push only when the user explicitly asks.

## Source layout (entry points)

- `Sources/Suite/` — main module, organized by Apple framework being extended (`Foundation/`, `SwiftUI/`, `UIKit/`, `AppKit/`, `Geometry/`, `Combine & Async/`, etc.)
- `Sources/SuiteMacrosImpl/` — macro implementations (SwiftSyntax)
- `Sources/Suite/SuiteMacros.swift` — macro declarations
- `Tests/SuiteTests/` — Swift Testing suite
- `Misc/CODE_REVIEW.md` + `CODE_REVIEW_RESOLVED.md` — exhaustive per-file review with dispositions. **Read the relevant section before "fixing" anything that looks weird.**

## Code conventions

- **Files ~100 lines.** Split larger types into per-functionality files in a per-type subdirectory (see `Foundation/Date/`, `Foundation/URL/`, etc. for the pattern).
- **No multi-line function declarations** if avoidable.
- **No emoji** unless the user asks. Don't add emoji to source files.
- **No new docs** (`*.md`, `README*`) unless the user asks.
- **Comments**: default to none. Only write a comment when the *why* is non-obvious. Don't restate what well-named code already says.
- **Subview structs > view-returning computed properties.** A `var foo: some View` computed property in a SwiftUI struct should usually be a separate `private struct Foo: View`.
- **Full-screen views are `*Screen`, not `*View`** (e.g. `LoginScreen`, not `LoginView`).
- **Avoid hard-coded layout dimensions.** For text-relative sizes, use `.scaledFrame(width:height:)` (it gates `@ScaledMetric` behind iOS 14 internally — see *ScaledFrame helper* below). Visual specs (corner radii, divider thickness, drag-handle pip dimensions) are fine fixed.

## Concurrency rules (project)

- **async/await only.** No GCD, no Combine, no closure callbacks for new code.
- **Exception**: a few types are deliberate Combine bridges — see *Triaged decisions* below.
- **Sendable** conformance throughout.
- `@MainActor` for UI; `nonisolated` for cross-actor access where needed.

## Triaged decisions — DO NOT "fix"

These look like bugs/violations but are kept on purpose. Don't refactor unless the user explicitly asks.

### Combine that's staying

- `ObservableValue` — by-design bridge from `Publisher` to SwiftUI `ObservableObject`. Removing it = removing the type.
- `PublisherView` — same, view variant.
- `DeSync.Publisher.asynchronize()` — Combine→async bridge for legacy callers.
- `Keychain.{lastResultCode,accessGroup,keyPrefix,synchronizable}Subject` — **public** `CurrentValueSubject`s; replacing breaks callers.
- `Subscribers.Sink` helpers in `Publishers.swift` (`onCompletion`/`onSuccess`/`onFailure`) — leak under endless publishers, but fixing requires returning `AnyCancellable`, an API break.
- `NotificationObserver` keeps `import Combine` for its public `Notification.Name.publisher()` extension.
- `Reachability` uses `NWPathMonitor` (no async API in Network framework) — not actually Combine.

### Deprecated APIs that stay

- `NavigationView` / `OptionalNavigationLink` / `ContainedContentNavigationLink` (`SwiftUI/Extensions/NavigationView.swift`) — pre-iOS 16 back-compat. Replace only after dropping iOS 15.
- Single-arg `onChange` — call sites already pair the deprecated form with an `if #available(iOS 17, *)` companion. Pattern is intentional.
- `UIScreen.main` — 5 sites (`WidgetFamily`, `CurrentDevice`, `UIView.screenScale`). Modern API needs a `UIWindowScene` argument; switching changes API shape.
- `kIOMasterPortDefault` (Gestalt) — value identical to `kIOMainPortDefault` at runtime; deprecation is cosmetic.

### Hard-coded dimensions kept

- `Font.buttonImage` (`.system(size: 32)`) — there's no `Font.system(size:relativeTo:)` for *system* fonts (only `Font.custom`); making this scale needs a structural refactor.
- `SlideUpSheet` 40×5 drag handle, 1pt divider; `BottomSheetView` 16pt corner radius — fixed visual specs, not text-relative.

### Files that look unsplittable but have been considered

- `Types/SFSymbol.swift` (~1800 lines) — Swift can't split an enum's cases across files; converting to a struct breaks `CaseIterable` + exhaustive `switch`.
- `Combine & Async/AsyncSemaphore.swift` (~242 lines) — single thread-safety-critical class; splitting fragments lock discipline.

## Build- and test-time pitfalls

- **SourceKit diagnostics are often stale right after edits.** Symbols you just added are flagged as missing. **Always verify with `swift build`** before believing a SourceKit error.
- **Tests must use deterministic barriers, not yield heuristics.** Patterns like `for _ in 0..<50 { await Task.yield() }` flake under load. See `Tests/SuiteTests/TestSupport.swift::ReadyFlag.waitUntilWaiters(count:)` for the deterministic-barrier pattern, and `ReadyFlagTests.swift` for usage. For completion synchronization, use `await task.value` or `withTaskGroup` — both deterministic.
- **`@ScaledMetric` requires iOS 14 / macOS 11 / watchOS 7 / tvOS 14.** For iOS 13-compatible scaling, use `View.scaledFrame(width:height:)` (`SwiftUI/Extensions/ScaledFrame.swift`), which splits internally on availability and falls back to fixed `.frame()` on older OS. Don't gate the *containing struct* with `@available` unless you mean to break iOS 13 callers.
- **Pre-existing flakes**: none currently. The ReadyFlag flake was fixed in `3b9e868`.

## Key infrastructure to know about

- `Foundation/ThreadsafeMutex.swift` + `Property Wrappers/NonIsolatedWrapper.swift` — runtime backing for the `@NonisolatedContainer` macro. Internally uses `OSAllocatedUnfairLock` (iOS 16+) with an `NSRecursiveLock` fallback.
- `Types/Gestalt.swift` (and `Gestalt+DeviceType.swift`) — platform/distribution/device detection. Extending the device tables: also update `UIKit/ScreenSize.swift` and `Widgets/WidgetFamily.swift` if widget sizes are affected.
- `Utilities/JSON/JSON.swift` + sibling files — type-safe JSON enum with full Codable integration.
- `Combine & Async/AsyncSemaphore.swift` and `Property Wrappers/ReadyFlag.swift` — async coordination primitives.
- `Foundation/StableMD5.swift` — deterministic hash for cache keys; do not "optimize" the canonicalization (the dict-vs-array hash bug was fixed in `fab966b` and matters for cross-version stability).
- `SwiftUI/Extensions/ScaledFrame.swift` — Dynamic-Type-aware frame helper, gated for iOS 13 compatibility.

## Macros

- `@GeneratedPreferenceKey` and `@NonisolatedContainer` are the only two macros. `CLAUDE.md` once listed `@AppSettings`, `@AppSettingsProperty`, `@GeneratedEnvironmentKey` — those never had implementations and the doc references were removed in `74ce1eb`.
- Updating a macro: edit `Sources/SuiteMacrosImpl/`, then `Sources/Suite/SuiteMacros.swift`, then `Tests/SuiteTests/MacroTests.swift` (which uses `SwiftSyntaxMacrosGenericTestSupport` to assert expansion output). CLAUDE.md previously claimed these tests were placeholders — that's stale.

## When you find something that looks wrong

1. Check `Misc/CODE_REVIEW_RESOLVED.md` for the file. The disposition (`[FIXED]`, `[FALSE-POSITIVE]`, `[KEPT-AS-IS]`, `[OUT-OF-SCOPE]`) tells you whether to act.
2. Check this file's *Triaged decisions* section for cross-cutting patterns.
3. If still unclear, ask the user before "fixing."

## Commit/PR conventions

- Don't mention Claude / LLM / AI in commit messages or PR bodies.
- Don't push (`git push`) unless the user asks.
- Co-authored-by trailer is set automatically via the user's commit template — don't manually add or remove it.
- Prefer new commits over `--amend`.
