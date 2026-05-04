# Agents.md

README for AI agents working in this repo.

`CLAUDE.md` covers architecture in depth. `Misc/CODE_REVIEW_RESOLVED.md` has per-file dispositions for anything that looks wrong (check there before "fixing"). This file is the short orientation.

## What this is

`Suite` — multi-platform Swift utility framework. Targets in `Package.swift`: iOS 13, macOS 10.15, watchOS 6, tvOS 13, visionOS 1. Extends Apple frameworks (Foundation, SwiftUI, UIKit, AppKit, Combine, etc.) and ships two macros (`@GeneratedPreferenceKey`, `@NonisolatedContainer`).

## Build & test

```bash
swift build
swift test
swift test --filter ReadyFlagTests          # one suite
xcodebuild -scheme Suite -destination 'generic/platform=iOS' build   # iOS validation
```

Tests use **Swift Testing** (`@Test`, `#expect`, `#require`), not XCTest.

## Source layout

- `Sources/Suite/` — main module, organized by Apple framework being extended (`Foundation/`, `SwiftUI/`, `UIKit/`, `Geometry/`, `Combine & Async/`, etc.)
- `Sources/SuiteMacrosImpl/` — macro implementations (SwiftSyntax)
- `Sources/Suite/SuiteMacros.swift` — macro declarations
- `Tests/SuiteTests/` — Swift Testing suite (`TestSupport.swift` has shared helpers)
- `Misc/CODE_REVIEW.md` + `CODE_REVIEW_RESOLVED.md` — exhaustive per-file review

## Conventions

- Files ~100 lines; split larger types into per-functionality files in a per-type subdirectory (see `Foundation/Date/`, `Foundation/URL/`).
- `async`/`await` only — no GCD, no Combine, no closure callbacks for new code. (A handful of types are deliberate Combine bridges; see `CODE_REVIEW_RESOLVED.md`.)
- SwiftUI > UIKit fallbacks. Subview structs > view-returning computed properties. Full-screen views are `*Screen`, not `*View`.
- For Dynamic-Type-aware sizing, use `View.scaledFrame(width:height:)` (`SwiftUI/Extensions/ScaledFrame.swift`) — it gates `@ScaledMetric` behind iOS 14 internally so callers stay iOS 13-compatible.
- For test synchronization, use deterministic barriers (e.g. `flag.waitUntilWaiters(count:)` in `TestSupport.swift`) and `await task.value` / `withTaskGroup`. Yield-based heuristics flake under load.
- No emoji. No new markdown files unless asked. Default to no comments — only write one when the *why* is non-obvious.

## Before "fixing" something that looks wrong

1. Check `Misc/CODE_REVIEW_RESOLVED.md` for that file. Dispositions (`[FIXED]`, `[FALSE-POSITIVE]`, `[KEPT-AS-IS]`, `[OUT-OF-SCOPE]`) tell you whether to act.
2. SourceKit diagnostics are often stale right after edits. Verify with `swift build` before believing a "missing symbol" error.

## Commit conventions

- Don't mention LLM/AI assistance in commit messages or PR bodies.
- Don't `git push` unless the user asks.
- Prefer new commits over `--amend`.
