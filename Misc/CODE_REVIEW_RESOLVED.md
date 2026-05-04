# Suite — Code Review (Resolved)

This file is the archive of the file-by-file review entries that have been **resolved** — either fixed, marked as false positives, kept-as-is with reasoning, or rendered moot by other refactors. The original review snapshot lives in the project history; the open work lives in `CODE_REVIEW.md`.

Entries are grouped by directory and tagged at finding-level: `[FIXED]`, `[FIXED <commit>]`, `[FALSE-POSITIVE]`, `[KEPT-AS-IS]`, `[OUT-OF-SCOPE]`, `[DISPUTED]`.

---

## Macro Declarations

### `Suite/SuiteMacros.swift` — **[CLOSED]** _macro pass; see notes_
- ~~CLAUDE.md macro list drift~~ — addressed in `74ce1eb`.
- API correctness items (`@freestanding`/`@attached` declarations, module/type-name matching, peer prefix, `@available` not needed) — confirmed correct, no change.
- ~~`observing:` parameter name ambiguity~~ — kept as-is. Renaming is a breaking API change for callers.
- ~~`GeneratedPreferenceKey<V>` requires double-specification (caller passes `V` and `type:`)~~ — kept. Removing the generic loses caller-side type-checking on `defaultValue:`.

## Macro Implementations

### `SuiteMacrosImpl/SuiteMacros.swift` — **[CLOSED]** _no issues; confirmed in macro pass_

### `SuiteMacrosImpl/MacroFeedback.swift` — **[CLOSED]** _macro pass_
- `diagnosticID` colliding-on-message bug — **fixed**: each case now has a stable string id (`"noDefaultArgument"`, `"missingAnnotation"`, etc.) so `.message(...)` and `.error(...)` no longer collide on identical text.
- `severity` redundant-default cleaned up to explicit cases.

### `SuiteMacrosImpl/PreferenceKeyGenerator.swift` — **[CLOSED]** _macro pass_
- `type(from:)` index-out-of-bounds when only `name:` is provided — **fixed**: now guards `args.count >= 2`.
- `name(from:)` doesn't validate identifier — **fixed**: empty/whitespace/non-identifier names emit a clear diagnostic before expansion.
- `.self` stripping doesn't trim whitespace — **fixed**: trims before the suffix check.
- `defaultValue(from:)` brittle child-count match — **fixed**: now uses `node.arguments.count` directly (counts `LabeledExprSyntax`).
- Generated members `public` while struct is implicitly internal — **fixed**: dropped `public` from `defaultValue` and `reduce` so the access modifiers are consistent. The struct's effective scope follows the call site.
- Macro template re-indented to plain 4-space (was tab/space-mixed) for predictable expansion output.
- Real expansion tests added under `Tests/SuiteTests/MacroTests.swift` covering the success and diagnostic paths.
- ~~Sendable / `@MainActor` consideration on generated `static let defaultValue`~~ — left for caller (Suite generally doesn't enforce strict concurrency on emitted preference keys).
- ~~Unqualified file-scope accessor `var <keyName>: <keyType>.Type` collision risk~~ — kept; freestanding declaration macros can only emit at the caller's scope. Documented as a limitation rather than fixed.
- ~~Suggestion: emit `typealias` rather than `var keyName: KeyType.Type`~~ — kept; changing the shape is a breaking API change.

### `SuiteMacrosImpl/NonIsolatedActorAccessorGenerator.swift` — **[CLOSED]** _macro pass; major rewrite_
- Missing `nonisolated` keyword: was diagnosed but expansion fell through, generating a peer with the wrong shape and an accessor referencing an undefined backing container. **Fixed**: validation now suppresses *both* peer and accessor when invalid, so the user sees one clean diagnostic instead of cascade errors.
- Tautological `hasDefaultValue` guard inside `if let initializer` — **fixed** (logic restructured around shared `validate(node:declaration:context:)` helper).
- Dead `patternBinding.pattern = ...` mutation — **removed**.
- Non-optional + no-initializer case silently produced no peer — **fixed**: now emits `"@NonisolatedContainer requires either an initializer or an optional type"` diagnostic and skips expansion.
- `nonisolated` detection only checked first modifier, missing `public nonisolated` etc. — **fixed**: now iterates the full modifier list via `varDecl.modifiers.contains { ... }`.
- `observing:` argument matched by position instead of label — **fixed**: now matches by label so the macro is robust to future arguments.
- Dead `IdentifierTypeSyntax.type` extension — **removed**.
- Real expansion tests added covering optional/non-optional, `observing: true`, missing-`nonisolated`, and missing-initializer paths.
- ~~Diagnostics-with-fix-its for generic error messages~~ — kept as-is for now; messages are clearer post-rewrite.
- ~~Sendable/ObservableObject conformance pre-checks~~ — kept; downstream errors are clear enough.

### `SuiteMacrosImpl/SyntaxTreeSamples.swift` — **[CLOSED]** _macro pass_
- File renamed from `Syntax Tree Samples.swift` (space removed) so build tooling that mishandles spaces in filenames is happy. Header comment fixed to match the new filename. Contents (commented-out AST samples) kept as developer reference.

## Foundation (A-K)

### `Foundation/AVPlayer.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** Line 23-38: `convenience init?(assetNamed:extension:)` calls `self.init(url:)` BEFORE `return nil` (line 32-33). In Swift failable initializers must `return nil` before any `self.init` call — calling `self.init(url:)` and then `return nil` is invalid for a `convenience init?` and will not compile cleanly or will leave a half-initialized instance. The early-return path on line 27-28 (success) also calls `self.init` then `return` without an explicit `return self`, which is fine but the `else` path on line 31 is broken.
- **[Convention]** Lines 16-21: Indentation looks like it was inside an outer `extension` that was deleted; the `public extension AVPlayer` block is double-indented. Cosmetic.
- **[Suggestion]** Line 54: Stray `//#endif` comment.
- **[Concurrency]** Line 17: `static let cachedMoviesDirectory` performs filesystem I/O at static init; not isolated, but acceptable.

### `Foundation/AnyEquatable.swift` — **[CLOSED]** _A-K re-audit; no changes_
- **[Bug]** Dictionary nil-value equality edge case — **[KEPT-AS-IS]** affects only `[AnyHashable: Any?]` payloads where values are explicitly nil; the `count` guard catches differing key sets. Real bug but vanishingly rare.
- **[API]** No Sendable on `Any`-taking free functions — **[KEPT-AS-IS]** `Any` is fundamentally not Sendable.

### `Foundation/Array.swift` — **[CLOSED]** _A-K re-audit_
- **[Bug]** `removingDuplicates()` seeded result oddly — **[FIXED]** rewritten without the redundant seed.
- **[Perf]** O(n²) for non-Hashable element types — **[FIXED]** added a `where Element: Hashable` overload that's O(n) via `Set` membership.
- **[Bug]** `first(_:)` / `last(_:)` crash on negative input — **[FIXED]** both clamp `number <= 0` to return an empty array.
- **[Bug]** `breakIntoChunks` infinite loop with `growth < 1.0` — **[FIXED]** added `precondition(growth >= 1.0)` and a `Swift.max(1, ...)` floor on `chunkSize` recomputation.
- **[Perf]** `Collection.split(by:)` non-deterministic order — **[KEPT-AS-IS]** dictionary iteration order; documenting alone doesn't help. Callers can sort.
- **[Convention]** 164 lines — **[KEPT-AS-IS]** all logically related extensions; not worth splitting.

### `Foundation/Bundle.swift` — **[CLOSED]** _A-K re-audit; no changes_
- **[API]** `extension Bundle` not marked `public` (members are) — **[KEPT-AS-IS]** stylistic; works as written.
- **[Bug]** `Directory.init?` wastes assignment before returning nil — **[KEPT-AS-IS]** cosmetic.
- **[Convention]** Header `MobileProvisionFile.swift` — **[FIXED 74ce1eb]** corrected in earlier typos pass.

### `Foundation/Calendar.swift` — **[CLOSED]** _A-K re-audit; no changes_
- **[Bug]** `TimeZone.gmt` shadows iOS 16+ native — **[KEPT-AS-IS]** the project's static is initialized lazily; current Swift compiler does not flag a redeclaration error and behavior is equivalent (both reference GMT).
- **[API]** `firstDayInMonth` uses `Calendar.current` via `self` — **[FALSE-POSITIVE]** that's the call site's calendar, not implicit `.current`.

### `Foundation/Codable.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** Line 232: `self.init(rawValue: rawValue)!` force-unwraps inside the extension `RawRepresentable where RawValue == Int, Self: Codable`. Decoding an unknown int raw value crashes. The `do { }` on line 231 is also pointless (no catch).
- **[Convention]** File is 241 lines — over.
- **[API]** Line 52: `JSONExpandedDecoder` is `@unchecked Sendable` — uses inheritance to inject `awakeFromDecoder`. Subclassing JSONDecoder is supported but fragile.
- **[Concurrency]** Line 175 `static let default = JSONDecoder()` is mutable shared state; if any caller mutates `dateDecodingStrategy` etc., that's racy. Should be `let` of an immutable configured instance, but JSONDecoder isn't immutable. Worth documenting "do not mutate".
- **[Suggestion]** Line 86-90: Inconsistent — `iOS 15` for `formatted()` but the `else` branch uses `localTimeString()` with default styles. Min deployment is iOS 13.
- **[Bug]** Line 207-225: Large commented-out block — dead code; should be removed.

### `Foundation/Collection.swift` — **[CLOSED]** _A-K re-audit_
- **[Suggestion]** `compactMap()` with `as? Result` shadows standard — **[KEPT-AS-IS]** type-inference works at call sites. Renaming would be breaking.
- File header `CollectionDifference.swift` — **[FIXED]** corrected to `Collection.swift`.

### `Foundation/CommandLine.swift` — **[CLOSED]** _A-K re-audit; no changes_
- **[Bug]** Int.min overflow risk in `int(for:)` — **[FALSE-POSITIVE]** parsing the absolute value of Int.min (9223372036854775808) returns nil from `Int(...)` because it's one past Int.max; we return nil before any multiplication. Safe.
- **[Concurrency]** `threadsafeArguments` name vs `unsafeArgv` — **[KEPT-AS-IS]** real cosmetic concern; the function name promises more than the underlying API guarantees, but in practice argc/argv don't change after process start.

### `Foundation/Data.swift` — **[CLOSED]** _A-K re-audit_
- **[Bug]** `init?(hexString:)` uses `hex.count / 2` for byte array — **[FIXED]** changed to `utf16.count / 2`. Defensive against non-ASCII inputs (mostly theoretical for valid hex).
- **[Bug]** `debug_save` returns `URL!` that may be nil — **[FIXED]** changed to `URL?`. Callers that force-unwrap the IUO would crash; an explicit Optional surfaces the failure path.
- **[Bug]** `peek` uses size, `consume` uses stride — **[FALSE-POSITIVE]** intentional: `peek` reads exactly the struct's size; `consume` advances by stride to align for the next read. Both are correct for their purpose.

### `Foundation/Date.Day.swift` — **[CLOSED]** _A-K re-audit_
- **[Concurrency]** `.current` calendar/timezone — **[KEPT-AS-IS]** `Date.Day` is intentionally a calendar concept; the current calendar is the natural default.
- **[Bug]** `year < 1000` two-digit heuristic — **[KEPT-AS-IS]** edge cases for years 1000 and below 99 are unrealistic for the typical use case.
- **[Bug]** Multi-line ternary in `init(_:_:)` — **[FIXED]** extracted a `usableTime` local; `time?.isNever`-guarded value is computed once and used for both `hour`/`minute`.
- **[Convention]** File is 190 lines — **[KEPT-AS-IS]** the type's surface needs to live together.

### `Foundation/Date.DayOfWeek.swift` — **[CLOSED]** _A-K re-audit_
- **[Bug]** `days(since:)` uses `abs(...)` — **[FIXED]** replaced with directional `(lastIndex - firstIndex + 7) % 7`. Now Sunday since Saturday = 1, Saturday since Sunday = 6 (was both 6 / 1 depending on order).
- **[Concurrency]** `Calendar.current` for symbols — **[KEPT-AS-IS]** the symbols are user-locale-dependent display strings; current calendar is the documented contract.

### `Foundation/Date.Month.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** Line 20: `abbrev` returns `Calendar.current.veryShortMonthSymbols[self.rawValue]` — off-by-one. Other accessors use `rawValue - 1`. Will crash for `.dec` (rawValue 12, array has 12 elements at indices 0-11). This is a definite crash bug.
- **[Concurrency]** Lines 20-22: `Calendar.current` for symbols — locale-dependent.

### `Foundation/Date.Time.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** Line 197: `self.second = min(second, 59)` — should also clamp to >= 0; allows negative.
- **[Bug]** Line 175: `else if second > 60` should be `>= 60` (60 is invalid).
- **[Bug]** Line 141: `let end = end.hour <= hour ? end.hour + 12 : end.hour` — adding 12 for "PM" assumption is wrong; should add 24 for next-day.
- **[Bug]** Line 169: `Int(seconds / 60) % 60` — when `seconds` is 0, `0 / 60 = 0`, OK. But when adding e.g. 90 seconds: `Int(90/60) = 1`, `1 % 60 = 1`. So 90 seconds becomes 1 minute + 30 sec? Actually line 168: `second = self.second + TimeInterval(Int(seconds) % 60)` → 90 % 60 = 30, plus minute 1 from line 169. OK, but the algorithm is dense and untested for edge values.
- **[Bug]** Line 323-325: `meridian` returns `.am` for `hour == 24` (invalid hour). Init clamps with `hour % 24`, so impossible — but defensive.
- **[Concurrency]** Lines 290-298: `Calendar.current` in `date` property.
- **[Convention]** File is 349 lines — well over 100.

### `Foundation/Date.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Convention]** File is 553 lines — far over 100. Should be split (e.g., Date+Formatting, Date+Components, Date+AgeString).
- **[Bug]** Line 326-336: `iso8691String` — typo "8691" should be "8601". Same on line 330.
- **[Bug]** Line 301-305: `midnightUTC` adds GMT offset to local midnight, which gives the wrong direction for any non-GMT zone. To get UTC midnight you'd want `start of day in UTC`. The logic is suspect.
- **[Bug]** Line 480-481, 484-485: `thisWeek` and `upcoming` are duplicates of each other.
- **[Concurrency]** Line 246-249: `isIn24HourTimeMode` uses `Locale.current` — locale-dependent (correctly so), but result is recomputed every call.
- **[Concurrency]** `Calendar.current` used everywhere; no timezone-aware overloads.
- **[Bug]** Line 524: `Meridian.shows` static method — fine but on enum case fall-through.
- **[Suggestion]** Line 545-553: `Date: @retroactive RawRepresentable` with rawValue as `String(format: "%f")` is locale-independent (good), but `init?(rawValue:)` returns Date(timeIntervalSinceReferenceDate: 0.0) on parse failure — should return nil on invalid input.

### `Foundation/DateFormatter.swift` — **[CLOSED]** _A-K re-audit; no changes_
- **[Concurrency]** Blanket `Formatter: @unchecked Sendable` — **[KEPT-AS-IS]** Apple documents Foundation formatters as thread-safe; narrowing to specific subclasses is theoretically safer but a project-wide concession was made for ergonomics.
- **[Suggestion]** Always-`en_US_POSIX` for `init(format:)` — **[KEPT-AS-IS]** intentional; that's the contract for fixed-format parsers.

### `Foundation/DateInterval.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** Line 19: `let end = self.sorted(by: { $0.end > $1.end }).last?.start` — uses `.start` of the latest-ending interval, but should be `.end`. This is a clear bug — `fullRange` returns wrong end.
- **[Perf]** Lines 18-19: Two separate `sorted` calls, both O(n log n), to get min/max — should use `.min`/`.max`.
- **[Bug]** Line 39: `self.removeSubrange(firstIndex..<lastIndex)` — non-inclusive of `lastIndex`, then inserts a merged interval. If `firstIndex == lastIndex` (single overlap) this removes nothing and inserts. Bound checking suspect.

### `Foundation/Decoding.swift` — **[CLOSED]** _A-K re-audit_
- **[Suggestion]** `.default` reference — **[FALSE-POSITIVE]** `JSONEncoder.DateEncodingStrategy.default` is defined in `Utilities/JSON/JSONEncoder+JSONDictionary.swift:116`.
- **[API]** `SafeResult` not externally constructible — **[FIXED]** added a `public init(array:errors:)`.

### `Foundation/Dictionary.swift` — **[CLOSED]** _A-K re-audit; no changes_
- **[Bug]** Inherits AnyEquatable nil-value edge case — **[KEPT-AS-IS]** see AnyEquatable note above; vanishingly rare in practice.

### `Foundation/DiskBackedArray.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** Entire file: This struct is value type but mutates the disk on `set`. Two simultaneous mutations through different copies will overwrite each other; not atomic across instances. The `save()` on line 39 uses `.atomic` for the file write, but the in-memory `cache` is not protected. Two threads writing to the same backing URL race.
- **[API]** No way to remove, append, count, or iterate. Only subscript access — caller must call `cache[index]` but `cache` is internal. Public API is essentially useless beyond replacing existing indices.
- **[Bug]** Line 50-58: `extension DiskBackedArray where Value: Equatable` redefines `subscript`, but Swift will use the more constrained one only when `Value: Equatable`. However, having both `set` blocks call `save()` and the constrained one short-circuit is correct. Note: the un-constrained subscript still exists, so calling `array[0] = newValue` on `DiskBackedArray<Int>` may resolve to either depending on context.
- **[Bug]** Line 16-22: Subscript `set` does NOT check bounds; out-of-range write crashes (Array semantics).
- **[Suggestion]** Line 9: Not Sendable; can't be used in concurrent contexts.
- **[Bug]** Line 36: `save()` is not `mutating`; OK because `cacheURL` etc are `let`. But `cache` on line 14 is `var` — `save()` reads `cache`, so it's a non-mutating method on a value type that triggers I/O — fine.

### `Foundation/DiskBackedDictionary.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** Same as DiskBackedArray — no synchronization, races on the file URL across instances/threads.
- **[Bug]** Line 64-88: The `Equatable` extension redefines both subscripts, but the unconstrained subscripts (lines 16-35) also exist on the same type. Swift dispatches via static type; with `Value: Equatable` the constrained ones win in generic contexts but not always — confusing overlap.
- **[Bug]** Line 31-34: `subscript[_:default:]`'s setter does not check `cache[key] != newValue` (only the Equatable variant does). Inconsistent: writes always trigger save even if unchanged.
- **[API]** Not Sendable; no way to enumerate, remove all, get count.

### `Foundation/Enums.swift` — **[CLOSED]** _A-K re-audit; no changes_
- **[Bug]** `random()` force-unwraps — **[KEPT-AS-IS]** Swift requires at least one case for syntactic enum; only synthetic empty `CaseIterable` would trip the trap, and that's a programmer error worth a clear crash.
- **[Suggestion]** `next()` could use `firstIndex` — **[KEPT-AS-IS]** cosmetic.

### `Foundation/Error.swift` — **[CLOSED]** _A-K re-audit_
- **[Suggestion]** Magic numbers `260`, `999`, `-1009`, `-1001` — **[FIXED]** replaced with named constants: `CocoaError.Code.fileNoSuchFile.rawValue`, `URLError.cancelled.rawValue`, `URLError.notConnectedToInternet.rawValue`, `URLError.timedOut.rawValue`.

### `Foundation/FileManager.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** Line 64-68: `count == 1` after `count += 1`: first iteration `count` is 1, sets `name = base` — same as initial `name`! Caller will then loop again because file exists. The intended logic was probably "for first collision, use 'base 2'". Off-by-one in unique-naming algorithm.
- **[Suggestion]** Line 24-46: `copy(itemsAt:into:)` swallows errors when `ignoringErrors` true; also `try?` on createDirectory unconditionally — if creation fails for non-exists reasons, downstream calls fail.
- **[Convention]** File is 116 lines.

### `Foundation/FunctionBox.swift` — **[CLOSED]** _A-K re-audit_
- **[Concurrency]** Closure non-Sendable — **[KEPT-AS-IS]** marking the closure `@Sendable` would be a breaking signature change for callers passing non-Sendable closures.
- **[API]** Hash by call site — **[FIXED]** added a doc comment explaining the dedup-by-call-site contract (parallel to `BlockWrapper`).

### `Foundation/Int.swift` — **[CLOSED]** _A-K re-audit_
- **[Platform]** `arc4random_uniform` — **[KEPT-AS-IS]** legacy of the original Foundation API; `Int.random(in:)` would be the modern replacement but the public API on this random helper would change shape.
- **[Bug]** `UInt32.fourCharacterCode` byte order reversed — **[FIXED]** rewritten to extract MSB-first (big-endian, matching Apple FourCC convention). Also matches the existing `characterCode` byte order. No external callers found.

### `Foundation/Int64.swift` — **[CLOSED]** _A-K re-audit_
- **[Concurrency]** `@MainActor` on numeric formatter — **[FIXED]** removed the `@MainActor` annotation from both the formatter and `bytesString`. Confirmed `ByteCountFormatter` is `Sendable` per current SDK; no `nonisolated(unsafe)` needed.
- **[API]** Surprising `@MainActor` on a numeric extension — **[FIXED]** by the same change.

## Foundation (M-Z)

### `Foundation/MD5.swift` — **[CLOSED]** _M-Z re-audit_
- **[API]** `compactMap { try $0.md5 }` → **[FIXED]** changed to `map`; `md5` is non-Optional so the compactMap provided no benefit and obscured intent.
- **[Suggestion]** `MD5ableError` not public — **[KEPT-AS-IS]** internal-only; making it public would expand surface area without a concrete client need.
- **[Convention]** Single-line enum-with-payload style — **[KEPT-AS-IS]** stylistic, not a bug.
- **[Perf]** `URL.md5` loads entire file via `Data(contentsOf:)` — **[KEPT-AS-IS]** real concern but the streaming refactor (`FileHandle` + incremental `Insecure.MD5`) is out of scope for the typo/bug pass; flagged for a future change.

### `Foundation/NSItemProvider.swift` — **[CLOSED]** _M-Z re-audit; no changes_
- **[Platform]** `NSItemProviderImage` typealias defensive gating — **[KEPT-AS-IS]** every Apple platform imports either UIKit or AppKit; the `#elseif` covers reality.
- **[API]** Visibility inconsistencies on helpers — **[KEPT-AS-IS]** cosmetic; scopes work as written.
- **[Bug]** Image-type priority claim — **[FALSE-POSITIVE]** outer loop iterates types, inner iterates providers. Type priority wins; the reviewer's claim that "lower-priority earlier item still wins" is incorrect.
- **[Convention]** Mixed indentation — **[KEPT-AS-IS]** cosmetic.

### `Foundation/NSObject.swift` — **[CLOSED]** _M-Z re-audit; no changes_
- **[Concurrency]** Selector-based observer pattern — **[KEPT-AS-IS]** Obj-C bridge; alternative is breaking the API.
- **[API]** `StaticString.utf8Start` for associated-object key — **[FALSE-POSITIVE]** Swift documents `StaticString.utf8Start` as a stable address valid for the program lifetime, exactly the contract `objc_setAssociatedObject` needs.
- **[Memory]** No `ASSIGN`/`COPY` policy choice — **[KEPT-AS-IS]** feature request, not a bug.

### `Foundation/Notification.swift` — **[CLOSED]** _M-Z re-audit_
- **[Concurrency]** `MainActor.run` synchronous — **[FALSE-POSITIVE]** resolves to the project's `MainActor.run(after:_:)` shim in `Utilities/MainActor.swift`, which is async/await-based fire-and-forget. Compiles and behaves correctly.
- **[API]** `userInfo: [String: Sendable]?` casting — **[KEPT-AS-IS]** intentional Sendable narrowing of NotificationCenter's `[AnyHashable: Any]`.
- **[Convention]** Commented-out code on lines 11-24, 36 — **[FIXED]** removed.

### `Foundation/NumberFormatting.swift` — **[CLOSED]** _M-Z re-audit; no changes_
- **[Bug]** `result[0...(decPos + limit)]` off-by-one — **[FALSE-POSITIVE]** inclusive `0...(decPos+limit)` yields `decPos` chars before `.`, `.`, plus `limit` chars after = exactly `limit` decimal digits. Correct.
- **[Bug]** Trailing-zero strip loop — **[FALSE-POSITIVE]** the `decPos == nil` early-return guards integer-only strings; the strip-then-restore pattern handles `"1.0"` → `"1"` → `"1.0"` (when `includeDecimal`) cleanly.
- **[Concurrency]** `static formatter` not `Sendable`-marked — **[KEPT-AS-IS]** `NumberFormatter` is documented thread-safe per Apple; not mutated post-init.
- **[Bug]** `string(decimalPlaces:padded:)` strips trailing zeros even at requested precision — **[KEPT-AS-IS]** intentional contract: `padded: false` (default) means "max N places, strip trailing zeros"; `padded: true` re-adds zeros to match `decimalPlaces`. Documented behavior.
- **[Perf]** Intermediate string allocations — **[KEPT-AS-IS]** minor; not a hot path.

### `Foundation/Operators.swift` — **[CLOSED]** _M-Z re-audit; no changes_
- **[API]** `≈≈` / `!≈` declared with no implementation here — **[FALSE-POSITIVE]** `infix operator` declarations are global; per-type implementations live in `CGLine.swift`, `Vector2.swift`, etc. Standard Swift pattern.
- **[Suggestion]** `∆=` returning a value while assigning — **[KEPT-AS-IS]** intentional; `@discardableResult` documents the dual nature.

### `Foundation/Optional.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `Optional<Wrapped: Comparable>.<` returns `true` when both operands are nil (`lhs == nil` falls into first guard), violating strict weak ordering (`a < a` should be false). This will break any sort relying on it. (line 11-15)
- **[API]** Defining `<` on `Optional<Wrapped>` shadows/competes with potential `Optional: Comparable` conformance and is surprising; consider a different name.

### `Foundation/Pluralizer.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** Uses `CurrentValueSubject` (Combine) — violates "use async/await, not Combine" project rule. (line 18)
- **[Concurrency]** `Pluralizer` is `final class: Sendable` but mutates `plurals.value` from `nonisolated` setter — `CurrentValueSubject.value` is documented as thread-safe per Apple, but Read-Modify-Write on line 34 (`plurals.value[key] = newValue`) is **not atomic**: read returns a copy, mutate, write — racy. Two writers race. Should use a lock/`ThreadsafeMutex`. (line 34)
- **[API]** `pluralize` returns "1 singular" but no caller-controlled mapping for "1" (irregulars handled via plurals dict only).

### `Foundation/Process.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Platform]** Uses deprecated `launchPath`/`launch()` (deprecated since macOS 10.13 in favor of `executableURL`/`run()`). (line 17, 62, 74)
- **[Bug]** `run(timeout:)` returns `9` on timeout — magic number; not a real exit code. Should be a documented constant. (line 70)
- **[Concurrency]** Uses `RunLoop.current.run(...)` polling loop — synchronous busy wait. Project rule says use async/await. The whole API is sync. (line 67)
- **[Bug]** `stringValue`/`errorValue`/`dataValue` check `self.standardOutput as? Pipe == nil` then call `self.run(...)` — but `run` *unconditionally* assigns `self.standardOutput = Pipe()`, so the guard on having previously set a pipe is meaningless. Also re-running `run` overwrites prior output. (line 21-22, 54)
- **[Bug]** `errorValue` calls `run` which sets `standardOutput`/`standardError` to fresh pipes but checks `standardError` — coherent only if called before `stringValue`. State coupling is fragile.

### `Foundation/ProcessInfo.swift` — **[CLOSED]** _M-Z re-audit; no changes_
- **[Bug]** `int(for:)` mishandles internal `-` — **[KEPT-AS-IS]** edge case ("1-2" → 12) is graceful for the intended forgiving-parser use; rewriting to `Int(raw)`-first would change behavior for "$1,234" / "1.5K" inputs the current code handles.

### `Foundation/PropertyList.swift` — **[CLOSED]** _M-Z re-audit; no changes_
- **[Bug]** `PropertyListItem(_:)` double-cast — **[FALSE-POSITIVE]** marker-protocol cast is the standard way to gate primitive types; works as designed.
- **[API]** Only handles dict roots — **[KEPT-AS-IS]** array roots possible; expanding the API is breaking and outside scope of this pass.
- **[API]** `format` initialized misleadingly — **[KEPT-AS-IS]** cosmetic; `inout` requires an initial value.

### `Foundation/StableMD5.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** Hashing for `Date` differs between dictionary path (`timeIntervalSinceReferenceDate`) and array path (`String(describing: date)` → locale-formatted!). Two stable-MD5 results disagree for the same content depending on whether it's an array element vs. dict value. Critical inconsistency. (lines 35 vs 76)
- **[Bug]** `Float`/`Double` hashed via `String(describing:)` — locale/format-sensitive; `Double(0.1+0.2)` etc. produce different strings on different runtimes. Also `1.0` vs `1` hash differently. Use `bitPattern` or canonical form. (lines 31-33)
- **[Bug]** Dictionary path silently *skips* unknown JSON value types (no `else throw`), so adding a new field type changes the hash without warning. Array path *does* throw. Inconsistent. (line 22-43)
- **[Bug]** `KeyHash.hash` is Optional but always populated; the `??` fallback to "" hides bugs. (line 47, 97)
- **[Concurrency]** `JSONDictionary` is unordered; sorting only by key is correct, but if two keys share a hash (impossible with MD5 of different keys' values, but they'd collide via concatenation: `"ab"+"cd"` == `"abc"+"d"`). Not realistic for MD5 hex but worth noting structurally.
- **[Convention]** File header still says "DataModel"/"DetectionTek" — copy-paste leftover. (line 4-6)

### `Foundation/String.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
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

### `Foundation/StringIdentifiable.swift` — **[CLOSED]** _M-Z re-audit_
- **[Suggestion]** Dead `#if canImport(Combine)` gate — **[FIXED]** consolidated to a single declaration (the more permissive `where ID: StringProtocol` form). No external usages.

### `Foundation/StringInterpolation.swift` — **[CLOSED]** _M-Z re-audit_
- **[Bug]** Dead `encoder` local — **[FIXED]** removed.
- **[Bug]** Silent fallthrough on nil `prettyJSON` — **[FIXED]** falls back to `String(describing: value)`.
- **[Convention]** Spurious `import SwiftUI` — **[FIXED]** changed to `import Foundation`. File header `File.swift` → `StringInterpolation.swift`.
- **[Style]** Trailing `}}` — **[FIXED]** reformatted.

### `Foundation/ThreadsafeMutex.swift` — **[CLOSED]** _M-Z re-audit; no changes_
- **[Concurrency]** Getter returns by copy — **[FALSE-POSITIVE]** correct pattern.
- **[API]** `set(_:)` redundant with setter — **[KEPT-AS-IS]** harmless convenience.
- **[API]** `perform` only takes non-throwing — **[KEPT-AS-IS]** feature request.
- **[Concurrency]** Setter atomicity — **[FALSE-POSITIVE]** single `withLock`, not RMW.
- **[Suggestion]** `@unchecked Sendable` over-broad — **[KEPT-AS-IS]** required: even though `OSAllocatedUnfairLock<T: Sendable>` is itself Sendable, the surrounding class with stored properties accessed via `nonisolated` setters needs the explicit conformance.

### `Foundation/TimeInterval.swift` — **[CLOSED]** _M-Z re-audit_
- **[Bug]** `milliseconds` misnamed (returns 0..<1 fractional seconds) — **[KEPT-AS-IS]** with doc comment added; renaming the public property is breaking, and the durationString call sites depend on the current value range to format trailing decimals.
- **[Bug]** `durationString` ".5" vs "0.5" concatenation — **[FALSE-POSITIVE]** intentional; `decisecondsFormatter` has `maximumIntegerDigits = 0` precisely to produce the trailing-decimal form.
- **[Bug]** `init?(string:)` assigns before failing — **[KEPT-AS-IS]** wasted assignment is permitted in Swift; cosmetic.
- **[Convention]** File ~205 lines — **[KEPT-AS-IS]** Tier C file-splits pass already covered Foundation files; this one wasn't split because the durationString switch is one logical unit.
- **[Concurrency]** Shared `static let durationFormatter` mutated via `.allowedUnits = ...` per call — **[FIXED]** switched to a local `DateComponentsFormatter()` per call. The other static formatters (`centisecondFormatter`, `millisecondsFormatter`, `decisecondsFormatter`) aren't mutated post-init, so they stay shared.

### `Foundation/Timer.swift` — **[CLOSED]** _M-Z re-audit_
- **[Concurrency]** Combine `AutoconnectedTimer` typealias — **[OUT-OF-SCOPE]** public Combine bridge; removing breaks callers.
- **[Concurrency]** `nonPausingTimer` racy when called off-main — **[FIXED]** marked `@MainActor`.

### `Foundation/URL+ExtendedAttributes.swift` — **[CLOSED]** _M-Z re-audit_
- **[Bug]** Initial-length failure thrown as `.noAttributeFound` regardless of cause — **[FIXED]** now distinguishes `ENOATTR` (noAttributeFound) from any other errno (posixError(errno)).
- **[Bug]** TOCTOU race between size probe and read — **[KEPT-AS-IS]** retry loop is a real fix but a bigger change; the second-call guard already throws a clear `.posixError(errno)` on `ERANGE`.
- **[Bug]** `allExtendedAttributeNames` same TOCTOU — **[KEPT-AS-IS]** same reasoning.
- **[API]** errno not captured before next syscall — **[FALSE-POSITIVE]** `errno` is read in the `guard` immediately after the `getxattr` returns; no syscall intervenes.

### `Foundation/URL+Files.swift` — **[CLOSED]** _M-Z re-audit_
- **[Bug]** Force-unwraps in `static let documents`, etc. — **[KEPT-AS-IS]** `NSSearchPathForDirectoriesInDomains` returns empty only in degenerate sandbox cases where the framework can't function anyway; trapping is the right behavior.
- **[Bug]** `applicationSpecificSupport` falls back to `Bundle.main.name` — **[KEPT-AS-IS]** real concern but rare in practice (every Apple app has a bundle identifier).
- **[Concurrency]** `Bundle.main` not `Sendable`-marked — **[KEPT-AS-IS]** Foundation-side annotation; can't fix here.
- **[Bug]** `audioDuration` non-visionOS uses deprecated sync `.duration` — **[FIXED]** added `if #available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)` branch using `try await reader.asset.load(.duration)`; falls back to the sync API on older OSes.
- **[API]** Side-effect-via-getter `_ = url.dropLast().existingDirectory` — **[KEPT-AS-IS]** repeated pattern in this file; documented behavior.

### `Foundation/URL+Images.swift` — **[CLOSED]** _M-Z re-audit_
- **[API]** `resizedContainedImage` was `internal` — **[FIXED]** marked `public`. Both AppKit and UIKit overloads.
- **[API]** UIKit `UIImage(cgImage:)` loses scale/orientation — **[KEPT-AS-IS]** for thumbnail use the default scale is appropriate; adding a parameter is a breaking change.

### `Foundation/URL.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
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

### `Foundation/URLRequest.swift` — **[CLOSED]** _M-Z re-audit_
- **[Bug]** `curl` doesn't escape single quotes in headers/body — **[FIXED]** added private `String.shellSingleQuoteEscaped` helper (replaces `'` with `'\''`); applied to header keys, header values, and body.
- **[API]** Cookie header skipped silently — **[KEPT-AS-IS]** intentional safety.

### `Foundation/UUID.swift` — **[CLOSED]** _M-Z re-audit; no changes_
- **[Bug]** UUIDv7 sub-ms float rounding — **[KEPT-AS-IS]** the tail of the loss is below clock granularity and below UUIDv7 spec resolution; not material.
- **[Bug]** Other byte placement — **[FALSE-POSITIVE]** confirmed correct per spec.
- **[Suggestion]** Trailing blank line — **[KEPT-AS-IS]** cosmetic.

### `Foundation/UserDefaultsBackedDictionary.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** `UserDefaultsBackedDictionary` is a struct holding `UserDefaults` (class) and a closure (`@escaping (Key) -> String`). The closure should be `@Sendable` for Sendable conformance under strict concurrency. Type isn't marked `Sendable`. (line 39, 41)
- **[Bug]** `defaults.value(forKey:) as? Value` for `Value == URL` won't work — `UserDefaults` stores URL via `set(_:forKey:)` as bookmark/path under the hood; `value(forKey:)` returns `Data` or `String`, not `URL`. Use `defaults.url(forKey:)`. (line 52)
- **[API]** `UserDefaultStorable` is a marker protocol with no requirements — any type can be `extension X: UserDefaultStorable {}` and crash at runtime when stored. Type-safety theater. (line 10)

### `Foundation/try.swift` — **[CLOSED]** _M-Z re-audit_
- **[API]** Uses global `logg` — **[KEPT-AS-IS]** project convention; defined in `Logging/SuiteLogger.swift`.
- File header was `tryLog.swift` — **[FIXED]** corrected to `try.swift`.

## Types

### `Types/DeviceFilter.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** All static let constants on `DeviceFilter` are inside a `@MainActor` extension — including `never`, `sim`, `device`, etc. These are pure value constants that don't need MainActor isolation. This forces all callers to MainActor. Move them out, leaving only `matches` MainActor-isolated (since it reads `Gestalt` MainActor state).
- **[Bug]** `matches` for `.iOS` returns false on Mac Catalyst because `isOnIPad`/`isOnIPhone` are likely false — but a Catalyst app *is* iOS-derived. Verify intent.
- **[Bug]** `.sim` check uses `Gestalt.isOnMac` as a proxy ("Mac is sim-equivalent"?) — that conflates running on Mac with running on simulator. Likely a bug.

### `Types/Gestalt+DeviceType.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Convention]** 169 lines with a long device map; data-heavy file but acceptable.
- **[Bug]** Device map is significantly out of date: missing iPhone 15, 16, all M-series iPads, recent Apple Watches (Series 8/9/10, Ultra), Apple TV 4K 3rd gen, etc. As of 2026 this is quite stale.
- **[Bug]** Typo: "iPhone Xs max" (line 63) and "iPhone 11 Pro max" (line 67) should be "Max".
- **[Bug]** Typo: "iPad air 4th gen" (line 107) should be "iPad Air 4th gen".
- **[Bug]** "RealityDevice14,1" → "Apple Vision Pro" — that mapping is correct but `os(visionOS)` isn't included in the file's `#if os(iOS) || os(watchOS) || os(visionOS)` rawDeviceType reading on the file scope — it is, OK.
- **[Concurrency]** `static let modelName`, `rawDeviceType`, `simulatedRawDeviceType` are global statics on a `Sendable` struct — they capture `ProcessInfo` and `utsname` at first access. Should be safe.

### `Types/Gestalt.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
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

### `Types/Keychain.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** Heavy `Combine` usage: `CurrentValueSubject` for `lastResultCodeSubject`, `accessGroupSubject`, etc. Project guidance says "use async/await, not combine, GCD or queues". Consider migrating to `AsyncStream` or `Observable`.
- **[Concurrency]** All static state (`accessGroup`, `keyPrefix`, `synchronizable`, `lastResultCode`) is mutable and read/written without locking; the underlying CurrentValueSubject is thread-safe but the get/set semantics on the static var aren't atomic across compound reads.
- **[Bug]** In `set(_ value: Data?, ...)`: when `value == nil`, calls `delete(key)` and returns `false`. Returning false for a successful nil-deletion is misleading — a caller doing `if Keychain.set(nil, forKey: key)` will get false even though the operation succeeded.
- **[Bug]** `AccessOptions.accessibleAlwaysThisDeviceOnly` returns `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (line 396) — that's a clear copy-paste bug. The "always" semantic is replaced silently with "after first unlock".
- **[Concurrency]** Static `lastQueryParameters` and `lastResultCodeSubject` are not `Sendable`; this enum cannot be used safely from concurrent contexts.

### `Types/RawCollection.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** **Subscript setter is inverted**: when `newValue == true`, it calls `elements.remove(item)`; when false it calls `elements.insert(item)`. Setting `collection[item] = true` REMOVES the item. This is a serious copy-paste bug.
- **[API]** No `Codable`, `Sendable`, `Equatable`, `Hashable` despite obviously needing them.

### `Types/SoundEffect.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** Uses `Timer.scheduledTimer(...)` and `MainActor.run(after:)` for delayed work — project policy says async/await preferred. Replace with `Task.sleep(for:)`.
- **[Memory]** `cachedSounds` and `playingSounds` are static unbounded dictionaries/arrays. No eviction; long-running app leaks memory.
- **[Bug]** `pause()` sets `isPlaying = true` (line 232) — should be `false`. Clear bug.
- **[Bug]** `init(named:)`: when fallback `data: nil` is passed at line 136, `self.init(data: nil, ...)` is called but `data: Data?` init returns nil for nil data — yet the outer `convenience init?` calls it then `return nil`. The earlier branches at line 128 set `cachedSounds[name] = self` *after* `self.init(url:)` — but `self` may be nil at that point if `init(url:)` returned nil. Cannot reference `self` in failable init after a failable delegate that returned nil, so... the code actually compiles because `init(url:)` is currently non-failable in code (despite `init?` annotation) — actually it IS `init?(url:)` (line 73) but never returns nil. The `self.init(url:)` call would terminate the init if it failed. Confusing but works.
- **[Bug]** `if !preload` branches for `data:` initializer don't add to `cachedSounds` — inconsistent with `url:` initializer which does cache.
- **[Convention]** 239 lines — over guideline.
- **[Concurrency]** `nonisolated public static func ==` reads `===` — fine since identity comparison doesn't touch isolated state.
- **[Suggestion]** `disableAllSounds = Gestalt.isOnSimulator` makes simulator silent by default — surprising for new users; should be opt-in.

### `Types/VersionString.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** Custom `==` semantics: `"1.2" == "1.2.0"` is true (good), but `"1.2.0.0.0.5" == "1.2"` would compare prefix [1,2] vs [1,2], then check the suffix `[0,0,0,5]` — `allSatisfy { $0 == 0 }` is false → returns false. But `<` would correctly say `1.2 < 1.2.0.0.0.5`. So `==` returns false and `<` returns true and `>` (synthesized) returns false: total ordering holds. OK.
- **[Bug]** In `==`, the suffix check uses `lhComponents.suffix(from: lhComponents.count - minCount)` — that's wrong. If `lhComponents.count == 5` and `minCount == 2`, it suffixes from index 3, returning the LAST 2 elements, not the trailing-after-minCount elements. Should be `suffix(from: minCount)`. **This is a real bug**: `"1.2.3.0" == "1.2"` would return true (since the wrong-suffix-from-2 = `[3, 0]` — wait let me recompute: count=4, minCount=2, `count - minCount = 2`, so suffix from index 2 = `[3, 0]`, allSatisfy zero = false → returns false). Hmm, actually it works out by coincidence because `count - minCount == minCount` when `count == 2*minCount`. With `count=5, minCount=2`: suffix from 3 = last 2 elements; missing index 2. **Bug confirmed**: `"1.2.0.5.0" == "1.2"` would skip checking index 2 (the value 0) and check `[5, 0]` → false → returns false (which is correct here by luck), but `"1.2.5.0.0" == "1.2"` skips index 2 (5) and checks `[0,0]` → all zero → returns TRUE incorrectly.
- **[API]** `Sendable`/`Hashable`/`Codable` not conformed despite trivially possible.
- **[API]** Init takes `String` but provides no validation; non-numeric components are silently filtered by `compactMap`.
- **[API]** No `init(from decoder:)` — cannot round-trip serialize.

---

**Note**: The review prompt mentioned `UserDefaultsContainer`, `ObservableValue`, and `NonIsolatedWrapper` as "key types in this directory", but those files do not live in `Sources/Suite/Types/` — they're in `Sources/Suite/Property Wrappers/` and elsewhere. Reviewed only the actual contents of `Types/`.

## Utilities

### `Utilities/AsyncWebView.swift` — **[CLOSED]** _Utilities re-audit_
- **[Concurrency]** `setup()` dispatched async — **[FIXED]** setup is now done synchronously inside `init` (the class is already `@MainActor`, and `WKWebView()` is `@MainActor`). No more "load before setup" race.
- **[Concurrency]** Redundant `MainActor.run` from MainActor — **[FIXED]** removed; `webView.load(request)` called directly.
- **[Bug]** Continuation race against async setup — **[FIXED]** by the same change (no async setup).
- **[API]** Public `WKWebView!` IUO — **[FIXED]** changed to `public let webView: WKWebView`.

### `Utilities/BlockWrapper.swift` — **[CLOSED]** _Utilities re-audit_
- **[API]** Source-location-based equality is surprising — **[FIXED]** added a doc comment to the type explaining the semantics (de-duplicating subscriptions registered from the same site).

### `Utilities/CommunalFetcher.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** Uses Combine (`CurrentValueSubject` + `sink`) inside an actor; CLAUDE.md says to use async/await, not Combine. This whole class would be cleaner with a single in-flight `Task` that suspended waiters await.
- **[Bug]** When `inProgress` is true and a waiter sinks, the `receiveValue` handler resumes the continuation when a non-nil `value` arrives — but `value.value = value` runs on the actor before `cancellables = []`, so multiple sinks may all fire and resume each waiter exactly once. However, if `clear()` is called externally between the start and end of a fetch, value goes nil and the sink ignores it; but a subsequent `fetcher` failure publishes `.failure` which terminates the subject permanently — subsequent fetches will never be able to publish on the same subject. The subject is created once at init; after `value.send(completion: .failure(...))` the subject can no longer deliver values. (line 51)
- **[Concurrency]** `cancellables` membership and the subject are mutated from inside an actor but the sink closures may execute on Combine's scheduler, capturing `self`. Strong reference plus capturing `&cancellables` from outside the actor isolation context is risky; storing into a Sendable `Set` from a non-isolated closure is technically a violation under strict concurrency.
- **[Memory]** On success, `value.value = value` keeps the cached value alive forever; only `clear()` resets it. Document.

### `Utilities/DeSync.swift` — **[CLOSED]** _Utilities re-audit_
- **[Convention]** Large commented-out block (lines 28-64) — **[FIXED]** removed.
- **[Bug]** `asynchronize()` race conditions — **[KEPT-AS-IS]** the bridge from a Combine `Publisher` to async/await is intentional and the file is gated on the legacy Combine surface. `hasContinued` is accessed only inside the continuation closure (single-threaded for a given subscription); the IUO `cancellable` is the standard pattern for self-cancelling sinks.
- **[Concurrency]** "Combine vs async pivot" — **[OUT-OF-SCOPE]** Tier C noted: bridge by design.

### `Utilities/Identifiable.swift` — **[CLOSED]** _Utilities re-audit_
- **[API]** Append-on-set semantics — **[FIXED]** added a doc comment to the subscript explaining set-on-missing-id appends.
- **[API]** Retroactive `Identifiable` on primitives — **[FIXED]** added a comment warning that duplicate values share an ID.
- **[Platform]** Dead `#if canImport(Combine)` gate — **[FIXED]** removed; the file has no Combine dependency. `import SwiftUI` was also unnecessary; now imports only Foundation.

### `Utilities/JSON/CodableJSONArray.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `init?(_ json: [String: Sendable]?)` (line 44) takes a *dictionary* but constructs an array — almost certainly a copy-paste error from `CodableJSONDictionary`. Looks like a leftover stub that does nothing useful and should be `[Sendable]?` or removed.
- **[Bug]** `hash(into:)` mixes index in regardless of value, so `[1, 2]` and `[2, 1]` hash differently from each other, but two equal arrays of `Sendable` values do hash the same — fine. However, values not `Hashable` are silently skipped; `Equatable` allows them via `compareTwoJSONValues`, so two equal arrays with non-`Hashable` payload still hash identically (good), but a non-Hashable value mismatch can yield equal hash with unequal `==` — which is acceptable, but worth documenting.
- **[API]** `array: [Sendable]` getter exposes a Swift existential array; consumers can downcast freely. Fine, but consider exposing typed accessors.
- **[Convention]** The `subscript` setter does no JSON-validity check (unlike the Dictionary variant) — inconsistent.

### `Utilities/JSON/CodableJSONDictionary.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** `nonisolated(unsafe) public static var dataKeyNames: [String] = []` (line 16) is mutable global shared state with no synchronization. Multiple threads writing/reading is a data race. Consider an actor or a lock-protected wrapper.
- **[Bug]** `JSONCodingKey.intValue` returns `0` when both `int` and `string` are nil-coercible — `Int(string ?? "0") ?? 0`. The fallback returns 0 silently, masking malformed keys (line 79). Should be a real Optional.
- **[API]** `JSONCodingKey` initializers `init?(stringValue:)` always succeed (never returns nil) — should not be failable, or the failable form is a lie.
- **[Bug]** `hash(into:)` iterates `dictionary` (line 30) which is unordered → different runs produce different hash sequences for the same dict because `combine` is order-sensitive. This violates the `Hashable` contract that equal values produce equal hashes. Sort keys before hashing.
- **[API]** `dataKeyNames` static side channel for telling the decoder "this string is base64" is leaky — it's set globally and influences all decode operations.

### `Utilities/JSON/JSON Types.swift` — **[CLOSED]** _Utilities re-audit; no changes_
- **[API]** `JSONDictionary` typealias too loose — **[KEPT-AS-IS]** tightening to `[String: any JSONDataType]` is a breaking change at every use site. The marker protocol exists on the right primitive types; the looseness is structural rather than semantic.

### `Utilities/JSON/JSON+Codable.swift` — **[CLOSED]** _Utilities re-audit_
- **[Convention]** File ~191 lines — **[KEPT-AS-IS]** Tier C splits already covered the JSON folder; the wrapper types (`EncodedDate`/`EncodedData`/`EncodedDictionary`/`EncodedArray`) belong in the same file.
- **[Bug]** Numeric decode order Int-before-Double — **[KEPT-AS-IS]** JSON does not distinguish 1 from 1.0 at the wire level; the round-trip choice (Int wins for whole numbers) is a deliberate one and matches the keyed-decoder behavior in `JSONDecoder+JSONDictionary.swift`.
- **[Bug]** Bool never tried in decode helpers — **[FIXED]** `Bool` now checked first in both keyed and unkeyed decode paths. Booleans no longer round-trip as `Int(0/1)`.
- **[Bug]** `EncodedDate`/`EncodedData` false-positive routing — **[KEPT-AS-IS]** the keyed shape `{date: ...}` is the wire contract for these wrappers; collisions with user keys named `date` are theoretical (nested wrapper struct is fileprivate).
- **[Perf]** `try?` chains — **[KEPT-AS-IS]** standard Swift Codable type-sniffing pattern.
- **[Bug]** Asymmetric `[Any]` round-trip — **[FALSE-POSITIVE]** on closer reading the encode and decode paths use the same `EncodedArray` wrapper for nested arrays inside dictionaries, and `nestedUnkeyedContainer` for top-level arrays. The dual paths are symmetric.
- **[Convention]** Unused `IntCodingKey` — **[FIXED]** removed.
- **[Bug]** `nil` values stripped on encode — **[KEPT-AS-IS]** documented contract; the alternative (encoding null) materially changes wire format.
- Bonus: also added `Bool`-first checks in both encode paths (was matching `Bool as? Int` via NSNumber bridging), and removed unused `import CloudKit`.

### `Utilities/JSON/JSON+Equatable.swift` — **[CLOSED]** _Utilities re-audit; no changes_
- **[Bug]** Bool/Int NSNumber bridge ambiguity — **[KEPT-AS-IS]** Swift-native values match correctly; Foundation-bridged ambiguity is rare in practice.
- **[Bug]** `integer(from:)` conflates Int and Double — **[KEPT-AS-IS]** intentional JSON-style equality where `2 == 2.0`.
- **[Perf]** `sortedKeys` allocations — **[KEPT-AS-IS]** correctness > micro-optimization.

### `Utilities/JSON/JSON+PrettyPrinted.swift` — **[CLOSED]** _Utilities re-audit_
- **[Bug]** Strings unquoted/unescaped — **[KEPT-AS-IS]** the function name `prettyPrintedJSON` is a misnomer (this is a debug formatter, not JSON); renaming is breaking.
- **[Bug]** `Bool` not handled (and the existing `as? Int` swallows Bool via NSNumber bridging) — **[FIXED]** added a `Bool`-first branch in both the dictionary and array variants.
- **[Bug]** `Date.localTimeString()` locale-dependent — **[KEPT-AS-IS]** debug representation, not stable serialization.
- **[API]** Method name says JSON but isn't — **[KEPT-AS-IS]** breaking rename.
- **[Perf]** String concatenation — **[KEPT-AS-IS]** debug path.

### `Utilities/JSON/JSONDecoder+JSONDictionary.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** Order matters for numeric decoding — `decode(Double.self)` happens before `decode(Int.self)` (line 31), so any integer in source JSON becomes a `Double` in output. The unkeyed sibling reverses the order (Int before Double). Pick one, document, and be consistent.
- **[Bug]** `date(from double:)` and `date(from int:)` always return `nil` (lines 110-117), so `secondsSince1970`/`millisecondsSince1970` strategies never work for numeric date fields when going through the keyed path. Fix the implementation.
- **[Bug]** Catch-all discards thrown errors as "null"; this also silently swallows malformed JSON. (lines 17-19)
- **[Concurrency]** Reading `CodableJSONDictionary.dataKeyNames` (line 27) is racy with the global `nonisolated(unsafe)` mutable state.

### `Utilities/JSON/JSONEncoder+JSONDictionary.swift` — **[CLOSED]** _Utilities re-audit_
- **[Bug]** `.custom` date strategy not implemented — **[KEPT-AS-IS]** the `.custom` strategy is encoder-callback-based and doesn't fit the manual builder shape; logging is the least-bad option.
- **[Bug]** Bool ordering — **[FALSE-POSITIVE]** `Bool` is already checked first.
- **[Bug]** `jsonValue(from date:)` returns nil for `.custom`/`.deferredToDate` — **[KEPT-AS-IS]** acceptable; callers must handle nil.
- **[Convention]** File ~173 lines — **[KEPT-AS-IS]** Tier C did not split this; the strategy switch must stay near the encoder methods.
- **[Bug]** Nested array doesn't forward `dateEncodingStrategy` — **[FIXED]** both keyed (`encode([Any])`) and unkeyed (`encode([Any])`) sub-array paths now pass the strategy through to their `subContainer.encode(...)` calls.

### `Utilities/JSON/JSONDecoder.swift` — **[CLOSED]** _Utilities re-audit; no changes_
- **[Bug]** "Future date" typo in header — **[FALSE-POSITIVE]** `3/15/26` parses as 2026-03-15, in the past at time of review. Cosmetic.

### `Utilities/MainActor.swift` — **[CLOSED]** _Utilities re-audit_
- **[Concurrency]** Task wrapper escapes context — **[KEPT-AS-IS]** `MainActor.run(after:)` is intentionally fire-and-forget; the type signature returns `Void`. Returning a `Task<Void, Never>` would be a behavior change.
- **[Bug]** `withAnimationOnMain` off-main fire-and-forget — **[KEPT-AS-IS]** sync/async bridge by design; documented intent.
- **[Bug]** `Thread.isMainThread` ≠ MainActor — **[KEPT-AS-IS]** the helper exists precisely for sync (non-actor) callers; replacing with `MainActor.assumeIsolated` would only work in async contexts.
- **[Convention]** Stale header — **[FIXED in M-Z pass]** file header was `Animation.swift`, now `MainActor.swift`.
- **[Concurrency]** `Thread.isMainThread` per CLAUDE.md — **[KEPT-AS-IS]** intentional bridge.

### `Utilities/ObservableValue.swift` — **[CLOSED]** _Utilities re-audit; no changes_
- **[Concurrency]** Combine usage — **[OUT-OF-SCOPE]** the type's purpose is to bridge `Publisher` → `ObservableObject`. Bridge-by-design.
- **[API]** Read-only — **[KEPT-AS-IS]** intentional design.

### `Utilities/Reachability.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** `pathMonitor.pathUpdateHandler` (line 41) runs on `queue` (default `.main`), captures `self`, and calls `objectWillChange.sendOnMain()` plus a `Task { @MainActor ... }`. Since `Reachability` is `@MainActor`, calls into `self.callCameOnlineCallbacks()` and `self.isOffline` from the closure are non-isolated — likely a strict-concurrency error / data race on `wasOffline` and `cameOnlineCallbacks`. The closure is also non-Sendable but uses self.
- **[Concurrency]** Stores `queue: DispatchQueue` (line 9) and uses GCD; CLAUDE.md says no GCD.
- **[Bug]** `setupAndCheckForOnline()` (line 27): if `isStartingUp` is false OR `startupContinuation != nil`, returns early. The "OR" is wrong — if the previous call already installed a continuation (`startupContinuation != nil`), the second caller returns immediately with the current state, never awaiting. Should likely allow multiple awaiters via a continuation list.
- **[Bug]** `start()` resumes `startupContinuation` (line 54) but does so unconditionally; the path monitor may not yet have produced any state. The 250ms sleep is a magic number; switch to await first `pathUpdateHandler` callback.
- **[Bug]** `whenOnline(_:)` callbacks accumulate forever; no removal API. (line 35) Memory leak risk.
- **[API]** `connection` returns `.other` while `isStartingUp` is true; `isOffline` then returns false. Misleading during startup.
- **[Convention]** Hard-coded sleep of `250_000_000` ns (line 52).

### `Utilities/SeededRandomNumberGenerator.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** Uses `DispatchSerialQueue.global()` and `queue.sync` for thread-safety (lines 18-49). CLAUDE.md says no GCD. Convert to an actor.
- **[Bug]** `nonisolated(unsafe) private static var sharedGenerator` mutated across threads — synchronized via `queue.sync`, but the access in `anyRNG` getter is *not* serialized against external setters in the get path of `with(_:)` since the getter is called inside `queue.sync`, OK — but the public `static func next()` calls `sharedGenerator.next()` which mutates `mersenne`'s internal state; `GKMersenneTwisterRandomSource` is not thread-safe (you marked it `@unchecked Sendable` retroactively).
- **[Bug]** `seed: Int = Int(Date().timeIntervalSinceReferenceDate)` truncates to Int and loses sub-second resolution; multiple instances created within the same second share a seed. Use `UInt64.random(in:)` or `mach_absolute_time`.
- **[Bug]** `print("Seeding a zero generator")` (lines 59, 64) — unconditional print in production. Use logger or remove.
- **[API]** `anyRNG` setter only accepts `SeededRandomNumberGenerator`; passing any other RNG silently no-ops.
- **[Platform]** Excluded from watchOS — fine since GameKit is unavailable.

### `Utilities/String+Crypto.swift` — **[CLOSED]** _Utilities re-audit_
- Bonus: replaced `compactMap` (no benefit, masks intent) with `map` for the hex-string build.

### `Utilities/URLSession.swift` — **[CLOSED]** _Utilities re-audit_
- **[API]** Shadows iOS 15+ native `data(for:)` — **[KEPT-AS-IS]** Suite still targets iOS 13; the shim is required for 13/14. Delete on minimum-deployment bump.
- **[Bug]** Continuation wrapper doesn't propagate `Task.cancel()` — **[FIXED]** wired the underlying `URLSessionDataTask` cancellation through `withTaskCancellationHandler`. Added a private `DataTaskHolder` (`@unchecked Sendable` with an `NSLock`) to share the task between the continuation closure and the cancellation handler.

### `Utilities/Views/FlowedHStack.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Convention]** File is 217 lines; split legacy fallback into its own file.
- **[SwiftUI]** Legacy `legacyBody` is a view-returning computed property (line 134). CLAUDE.md says to avoid view-returning properties — extract a subview type.
- **[Bug]** `indexOf(size:x:y:rows:bounds:)` (line 92) is O(n²) and matches by floating-point near-equality of position — fragile; if two cells share the same position (unlikely but possible after rounding) the wrong subview is placed. Use `subviews.indices` directly tracked.
- **[Perf]** `sizeThatFits` is recomputed in `placeSubviews` and `sizeThatFits` separately, not cached (no `cache:`).
- **[API]** `FlowedHStackImage` declares `id = UUID()` and conforms to `FlowedHStackImageElement` but the protocol is `Identifiable` only — and `FlowedHStackImageElement` is unused by `FlowedHStack` itself. Dead code.
- **[SwiftUI]** Uses `proxy.width` (line 138) — `GeometryProxy` does not have a `.width` property; only `.size.width`. Compile error unless there's an extension elsewhere — verify.
- **[Convention]** Hardcoded `-0.5` offset (line 33) and `(rowHeight - size.height) / 2` magic adjustments.

### `Utilities/Views/SimpleWebView+Additions.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** `nonisolated(unsafe) static var defaultValue: WebViewErrorCallback?` (line 13) is mutable static for an EnvironmentKey default. Should be `let` and likely `nil`.
- **[Platform]** Branches on `os(visionOS)` for `onChange(of:)` (lines 49-53); iOS 17 introduced the new signature — branch on availability, not OS. macOS 14 will hit the iOS branch incorrectly. (The iOS branch uses the deprecated form; on macOS 14 you might want the new one.)

### `Utilities/Views/SimpleWebView.swift` — **[CLOSED]** _Utilities re-audit_
- **[Bug]** `EmbdeddedWebView` typo — **[FIXED 74ce1eb]** corrected to `EmbeddedWebView`.
- **[Bug]** `@State var webView: WKWebView = .init()` allocates per struct construction — **[KEPT-AS-IS]** wasteful (`WKWebView()` evaluated on every body call, immediately discarded by `@State`'s storage), but the alternative (`@StateObject` + class wrapper) is a meaningful re-architecture; not in scope for this pass.
- **[Bug]** Coordinator retains `webView` while also being `navigationDelegate` — **[FALSE-POSITIVE]** single owner; works correctly.
- **[API]** `EmbeddedWebView.webView` vs `context.coordinator.webView` — **[FALSE-POSITIVE]** they reference the same instance (passed through `makeCoordinator`).
- **[Bug]** `Coordinator` not `@MainActor` — **[KEPT-AS-IS]** WKNavigationDelegate methods are documented to fire on main; the class is created on main. Adding the annotation would over-constrain.

### `Utilities/Views/View+PDF.swift` — **[CLOSED]** _Utilities re-audit_
- **[Bug]** `"\(self).pdf"` may contain illegal filename chars — **[FIXED]** default URL now uses `UUID().uuidString` for the filename.
- **[Bug]** Silent `guard` exit on context-creation failure — **[FIXED]** capture the error in a local, then re-throw after the renderer closure returns. Caller now sees `ViewPDFError.unableToCreateContext`.
- **[Bug]** `URL.caches` existence — **[FALSE-POSITIVE]** defined in `Foundation/URL+Files.swift`.
- File header `SwiftUIView.swift` — **[FIXED]** corrected to `View+PDF.swift`.

### `Utilities/Views/WrappedView.swift` — **[CLOSED]** _Utilities re-audit; no changes_
- **[Platform]** No watchOS/tvOS — **[KEPT-AS-IS]** those platforms don't have UIKit/AppKit hosting points that fit this representable shape.
- **[Memory]** Strong-stored view — **[KEPT-AS-IS]** standard SwiftUI representable pattern.

### `Utilities/Views/WrappingHStack.swift` — **[CLOSED]** _Utilities re-audit_
- **[Bug]** Cache mutation in `sizeThatFits` — **[KEPT-AS-IS]** standard SwiftUI `Layout` pattern; cache is per-layout-pass.
- **[Bug]** First-element overflow producing leading empty line — **[FIXED]** the line-break check is now `!currentLine.elements.isEmpty && (offsetX + width) > bounds.width`. An oversized first element stays on its line rather than producing an empty leading line.
- **[Bug]** `>= bounds.width` vs `>` — **[FIXED]** changed to `>` (equality fits exactly).
- **[Bug]** Trailing `horizontalSpacing` overcounts line width — **[FIXED]** `currentLine.width = max(0, offsetX - horizontalSpacing)` strips the trailing pad.
- **[Convention]** Empty final-line append — **[FIXED]** the final-line append is now guarded on `!currentLine.elements.isEmpty`. Empty layouts now return `.zero` from `calculateSize` instead of `(0, verticalSpacing × 0)`.

### `Utilities/WebConsole.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** `urlObservation = webView?.observe(\.url) { webView, change in Task { @MainActor in self.loadedURL = webView.url } }` (line 41) captures `self` strongly inside a KVO closure — leak risk if the observation outlives expected lifetime. Use `[weak self]`.
- **[Concurrency]** `webView?.removeObserver(self, forKeyPath: "url")` (line 34) is leftover from manual KVO and is not paired with `addObserver`. Calling `removeObserver` for a key path that wasn't manually added causes a runtime exception.
- **[Bug]** `setWebView` does not retain `originalNavigationDelegate` strongly (`weak`), so if the original delegate is owned only by the webview it may have already been released. Document.
- **[Memory]** `deinit` warns but cannot do cleanup (it's `nonisolated`); since the class is `@MainActor`, `deinit` cannot touch isolated state. The current code reads `self.webView` from `deinit` — that's a strict-concurrency violation.
- **[API]** `run(script:)` returns empty string on missing webView instead of throwing — surprising.
- **[Convention]** File 197 lines; many delegate forwards could move to a separate file.
- **[Bug]** `originalNavigationDelegate?.webView?(...)` selector forwarding via `responds(to:)` strings — string-based selector "webView:decidePolicyForNavigationAction:decisionHandler:" is fragile vs `#selector` (used elsewhere in same file).

### `Utilities/WebConsoleView.swift` — **[CLOSED]** _Utilities re-audit_
- **[Bug]** "Loaded"/"Loading" label swap — **[FIXED 74ce1eb]** the `.loading` case showed "Loaded" — corrected in the typos pass.
- **[Convention]** Hardcoded font size 16 — **[KEPT-AS-IS]** monospaced editor font; the size constant is unavoidable for this control.
- **[SwiftUI]** `.monospaced()` not used elsewhere — **[KEPT-AS-IS]** minor styling.

## SwiftUI / Component Views

### `SwiftUI/Component Views/AsyncButton.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** Line 55: `Button(title, systemImage:role:action:)` overload omits `.disabled(isPerformingAction)`, the preference key, and `onDisappear { cleanUp() }`, so the title+systemImage path silently behaves differently (no disable while running, no cancel on disappear, no preference reporting). The whole branch should funnel into a single modifier chain.
- **[Bug]** Line 145: `init(role:...)` overload (line 43) does NOT set `self.title` or `self.systemImage`, leaving them as default `nil` (OK), but the convenience init with `role:` at line 135 also fails to set `useDetachedTask` properly — wait, it does at line 140. However, the `init(role:...)` at line 43 never sets `title`/`systemImage` properties — fine since defaults are `nil`, but inconsistent: passing those was apparently intended but they're unreachable through that init.
- **[Bug]** Line 87/101: Logger `\(error, privacy: .public)` interpolation is an OSLog-style string format; `SuiteLogger.warning` likely takes a `String`, so `error` interpolated this way yields a literal `"... error privacy: .public ..."` text rather than working privacy redaction. Verify that `SuiteLogger.warning` actually accepts an `OSLogMessage` — if not, this is broken.
- **[Concurrency]** Line 82-94: `Task.detached` captures `taskWrapper`/`isPerformingAction` (SwiftUI bindings) and reads/writes them from a non-MainActor context outside the inner `MainActor.run`. The assignment `taskWrapper.wrappedValue = Task.detached { ... }` happens on MainActor; that's fine, but inside the detached task the closure body (lines 83-89) runs off-main and the `await action()` is `@MainActor` — should work, but `await MainActor.run { ... }` is preferred over manual hop.
- **[API]** Line 32: 7-parameter init with multiple optionals is awkward. Consider builder-style or fewer overloads.
- **[Style]** Line 110: `var buttonLabel: some View` is a view-returning computed property — violates the "avoid properties that return a view, prefer creating new subview types" convention.
- **[Style]** Line 181: `@ViewBuilder var spinner: some View` is also a view-returning property.
- **[Suggestion]** `role: Any?` (line 29) to dodge availability is a code smell; consider extracting role-handling into a helper or using a wrapper type.
- **[Convention]** File is 195 lines — substantially over the ~100-line guidance; split overload extensions and helper labels into separate files.

### `SwiftUI/Component Views/LabeledView.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** Line 11: `nonisolated(unsafe) public static var defaultValue = false` — `var` (mutable) static is racy. Should be `let`.
- **[Style]** Line 42: hard-coded font size `9` and padding `2` — violates "avoid hard-coded dimensions" (though for a debug overlay this is borderline acceptable).
- **[API]** `DebugLabeledView` is `internal`; `debugLabel` modifier on `View` is public — fine. `ShowViewLabelsEnvironmentKey` is exposed as `public` but the macro `@GeneratedEnvironmentKey` would do this cleanly per CLAUDE.md.

### `SwiftUI/Component Views/OffsetReportingScrollView.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** Line 62: `MainActor.run { position = offset }` inside `clearBackground(using:)` — calling `MainActor.run` synchronously from an unknown context: if already on MainActor it crashes (or produces a warning). Should be `Task { @MainActor in position = offset }` or use `.preference`/`onChange`. Also, mutating a `@Binding` from inside `body` evaluation during `GeometryReader`'s view-builder phase causes "Modifying state during view update" purple warnings — classic SwiftUI bug.
- **[Suggestion]** Replace with `GeometryReader` -> `PreferenceKey` -> `onPreferenceChange` pattern, or use iOS 17 `onScrollGeometryChange` for newer targets.
- **[API]** Line 18: `init` takes `axes` positionally without label — fine; `showsIndicators` deprecated on iOS 16+ in favor of `.scrollIndicators(.hidden)`.

### `SwiftUI/Component Views/TitleBar.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** Line 58: `.navigationBarHidden(true)` is iOS-only; this code compiles for macOS only because of `#if canImport(SwiftUI)` umbrella from imports — actually `navigationBarHidden` is unavailable on macOS/tvOS/watchOS. Will fail to build on non-iOS platforms.
- **[Deprecated]** Line 58: `navigationBarHidden(_:)` is deprecated in iOS 16; use `.toolbar(.hidden, for: .navigationBar)` with `@available` gating.
- **[Style]** Line 57: `.frame(height: 50)` hard-codes a dimension — violates project rule.
- **[Concurrency]** Line 11: `nonisolated(unsafe) public static var defaultValue = Font.title` — should be `let`.
- **[Style]** File is 108 lines — over guidance; could split overload extensions to a separate file.

## SwiftUI / Drag and Drop

### `SwiftUI/Drag and Drop/DragContainer+Keys.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** Line 35, 40: `nonisolated(unsafe) static var defaultValue` should be `let` — mutable static is a data-race liability even with `unsafe`.
- **[Platform]** Line 21: `@available(OSX 13, iOS 16, watchOS 8, tvOS 13, *)` for `Image.init(dragImage:)` on UIKit branch — claims tvOS 13 but `ImageRenderer` (next) requires `tvOS 16`. Mismatched availabilities across the same `#else` block.
- **[Platform]** Line 15-18: `@available(OSX 13, iOS 16, tvOS 13, watchOS 8, *)` on `extension ImageRenderer` for macOS branch — `ImageRenderer` itself requires macOS 13 / iOS 16 / tvOS 16. The `tvOS 13` annotation is wrong.

## SwiftUI / View Extensions, Modifiers, Wrappers

### `SwiftUI/View Extensions/Image.swift` — **[CLOSED]** _batch B re-audit; no changes_
- **[Bug]** `Image.random()` force-unwrap — **[KEPT-AS-IS]** `SFSymbol.allCases` has 1804 cases; never empty.
- **[Platform]** `Image(string:)` iOS-only — **[KEPT-AS-IS]** could relax with `#if canImport(UIKit)` but no current use beyond iOS.
- **[API]** `resizeTo(_:_:)` label mix — **[KEPT-AS-IS]** breaking rename.

### `SwiftUI/View Extensions/TouchUpDown.swift` — **[CLOSED]** _batch B re-audit_
- **[Bug]** `interval` parameter unused — **[FIXED]** `touchDown()` now uses `interval` for the initial delay (was hard-coded 200ms).
- **[Concurrency]** Unstructured Task lifecycle — **[KEPT-AS-IS]** `@State` persists across struct re-creation; the `task != nil` guard is correct.
- **[Convention]** Intermediate methods exposed — **[KEPT-AS-IS]** internal access shape works.
- File header `TouchUpDownActions.swift` — **[FIXED]** corrected to `TouchUpDown.swift`.

### `SwiftUI/View Extensions/View+Buttons.swift` — **[CLOSED]** _batch B re-audit_
- **[Convention]** Hard-coded `44` — **[KEPT-AS-IS]** Apple HIG minimum touch target; constant of art.
- File header `SwiftUIView.swift` — **[FIXED]** corrected to `View+Buttons.swift`.

### `SwiftUI/View Extensions/View+PreferenceValues.swift` — **[CLOSED]** _batch B re-audit_
- **[Bug]** `preferenceReduce` no-op — **[FIXED]** added a doc comment explaining "first wins" semantics.
- **[API]** Two `getPreferenceClosure` overloads with mixed isolation — **[KEPT-AS-IS]** the two overloads target different Optional shapes; the isolation difference reflects that.
- **[Convention]** Multi-line declarations — **[KEPT-AS-IS]** parameter lists necessitate the wrap.

### `SwiftUI/View Extensions/View+Printing.swift` — **[CLOSED]** _batch B re-audit_
- **[Platform]** `macOS 99.0`/`watchOS 99.0` placeholders — **[FIXED]** removed; the surrounding `#if os(iOS)` already excludes those platforms, so the bogus version markers were misleading.
- **[Bug]** `urlForPrintedPage` resolution — **[FALSE-POSITIVE]** the `#if os(iOS) || os(macOS)` guard plus the dual `imageForPrinting` definitions resolve correctly via platform-conditional compile.
- **[Convention]** `letterPageSize` private constant — **[KEPT-AS-IS]** internal use.

### `SwiftUI/View Extensions/View+UIViewController.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** `EnclosingViewControllerKey.defaultValue` is `nonisolated(unsafe) var` (line 40) — a single shared mutable container across the entire app. This is a global singleton masquerading as an environment default; assignments race.
- **[Memory]** `EnclosingViewControllerContainer` holds `weak _viewController` (good), but `defaultValue` being a single shared instance means every view in the process shares one container. Setting it in one view affects all readers.
- **[API]** `enclosingViewController` (line 61) uses `self as? ContainedInViewController` — `View` is a value type and unlikely to conform; this almost always returns nil and is misleading.

### `SwiftUI/View Extensions/View+URL.swift` — **[CLOSED]** _batch B re-audit_
- **[Concurrency]** Not `@MainActor` annotated — **[FIXED]** the whole `View` extension is now `@MainActor`.
- **[API]** `display(url:)` as a side-effect method — **[KEPT-AS-IS]** ergonomic via `someView.display(url:)`; renaming is breaking.

### `SwiftUI/View Extensions/View+macOS.swift` — **[CLOSED]** _batch B re-audit; no changes_
- **[API]** Stub `UIKeyboardType` enum — **[KEPT-AS-IS]** intentional cross-platform stub so iOS code calling `.keyboardType(.alphabet)` compiles on macOS.
- **[Convention]** No `import SwiftUI` — **[KEPT-AS-IS]** SwiftUI is re-exported via `ExportedModules.swift`.

### `SwiftUI/View Extensions/View+sizeReporting.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `SizeViewModifier.body` (line 18-23) and `frameReporting` (lines 64-85) write to a `Binding` from inside `GeometryReader`'s body via `Task { @MainActor in ... }` — this is the classic "modifying state during view update" pattern. The `SizeReporter` (lines 40-56) using `PreferenceKey` is the correct approach and should replace the others.
- **[Concurrency]** `SizePreferenceKey.defaultValue` and `FramePreferenceKey.defaultValue` use `nonisolated(unsafe)` (lines 29, 35) — for `static let` constants this is unnecessarily unsafe; should be `static let defaultValue: CGSize = .zero` (let, not var).
- **[Concurrency]** `frameReporting` and `reportGeometry` capture bindings in `Task { @MainActor }` from non-isolated closures — Sendable check failures likely on Swift 6.
- **[Perf]** `sizeLogging` (line 119) calls `logg` from inside `GeometryReader.body` — runs on every layout. Document this is for debugging only.
- **[Convention]** File is 238 lines — significantly exceeds the ~100 line guideline. Split into `SizeReporting`, `SizeOverlay`, `PositionOverlay`.
- **[Convention]** Multi-line function declarations (line 75, 87) violate convention.

### `SwiftUI/View Extensions/View.asyncOnChangeOf.swift` — **[CLOSED]** _batch B re-audit; no changes_
- **[Concurrency]** Task without Sendable annotation — **[KEPT-AS-IS]** marking `action` `@Sendable` would be a breaking signature change.
- **[Convention]** Multi-line declaration — **[KEPT-AS-IS]** the parameter list has good defaults; can't easily compress.

### `SwiftUI/View Extensions/View.presentationDetentSizeToFit.swift` — **[CLOSED]** _batch B re-audit; no changes_
- **[Bug]** Force-unwrap inside ternary — **[KEPT-AS-IS]** safe by construction; the cleaner alternative is stylistic.
- **[Convention]** Multi-line — **[KEPT-AS-IS]** body is one expression.

### `SwiftUI/View Extensions/View.swift` — **[CLOSED]** _batch B re-audit_
- **[Concurrency]** `toImage` not `@MainActor` — **[FIXED]** function is now `@MainActor` (UIHostingController and view manipulation require it).
- **[Bug]** `drawHierarchy(afterScreenUpdates:)` off-screen — **[KEPT-AS-IS]** documented Apple behavior; warning is informational.
- **[API]** `anyView()` antipattern — **[KEPT-AS-IS]** useful escape hatch for cases where AnyView is unavoidable.
- **[Convention]** `if`/`iflet` defeats diffing — **[KEPT-AS-IS]** documented tradeoff for conditional layouts.

### `SwiftUI/View Modifiers/Outlined.swift` — **[CLOSED]** _batch B re-audit; no changes_
- **[Perf]** Canvas redraws — **[KEPT-AS-IS]** typical use case is small; canvas-based mask is the simplest correct implementation.
- **[Concurrency]** No issues — confirmed.

### `SwiftUI/View Modifiers/Spinning.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Deprecated]** `.animation(_:value:)` modifier on view (line 26) is the modern call, but applying `repeatForever` animation to `rotationEffect` via `onAppear` setting `rotation` is a long-standing fragile pattern in SwiftUI. Consider `withAnimation` on appear or `.symbolEffect`/phase animator on iOS 17+.
- **[API]** `SpinningModifier.period` is stored but unused (line 33) — `body` constructs `Spinning(content)` without forwarding `period` (line 36). Bug: passing a custom period to `.spinning(period:)` is ignored.
- **[Bug]** Confirmed bug: `period` is dropped (line 36 omits `period: period`).

### `SwiftUI/View Modifiers/onTimer.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** Uses `Timer.publish` + Combine. CLAUDE.md says "use async/await, not Combine, GCD or queues." This whole file violates that — could be replaced with a `.task` that loops over `Timer.sequence`/`AsyncStream` or a `Task.sleep` loop.
- **[API]** `onTimer` is `internal` (no `public`); inconsistent with other public extensions in the framework.

### `SwiftUI/View Wrappers/AcceptsFirstMouse.swift` — **[CLOSED]** _batch B re-audit_
- **[Convention]** Wrong `import Foundation` — **[FIXED]** changed to `import SwiftUI`.
- **[Perf]** `setNeedsDisplay` on every update — **[KEPT-AS-IS]** invisible NSView; no actual draw cost.

### `SwiftUI/View Wrappers/BottomSheetView.swift` — **[CLOSED]** _batch B re-audit; no changes_
- **[Deprecated]** `.animation(animation)` no value: — **[KEPT-AS-IS]** the `value:` form requires iOS 15; Suite targets iOS 13.
- **[Bug]** `OverlayModifer` typo — **[FIXED 74ce1eb]** corrected in earlier typos pass.
- **[Convention]** 161 lines — **[KEPT-AS-IS]** types belong together logically.
- **[API]** `Item` not Sendable — **[KEPT-AS-IS]** breaking signature change.
- **[Platform]** Excludes tvOS/visionOS — **[KEPT-AS-IS]** intentional; bottom sheets less useful on those.

### `SwiftUI/View Wrappers/DebuggingIDView.swift` — **[CLOSED]** _batch B re-audit_
- **[Concurrency]** Mutable `static var` not isolated — **[FIXED]** marked `nonisolated(unsafe)`. Debug-only toggle; safe under typical usage.
- **[Convention]** No `@available` on the type — **[KEPT-AS-IS]** type uses no version-gated APIs; the extension's gate is sufficient.

### `SwiftUI/View Wrappers/Deferred.swift` — **[CLOSED]** _batch B re-audit_
- **[Bug]** `HStack` imposes layout — **[FIXED]** changed to `Group`, which is layout-transparent. Deferred content now lays out as if nothing wraps it.
- **[Concurrency]** `.task` cancellation — **[FALSE-POSITIVE]** SwiftUI's `.task` cancels on view disappear automatically.

### `SwiftUI/View Wrappers/EqualSizes.swift` — **[CLOSED]** _batch B re-audit_
- **[Concurrency]** Redundant `Task { @MainActor }` from MainActor closure — **[FIXED]** dropped the wrap; direct assignment.
- **[Perf]** Cascade re-layout — **[KEPT-AS-IS]** standard pattern.
- **[API]** `maxSize` collapses empty/all-zero — **[KEPT-AS-IS]** documented edge case; in practice all-zero size doesn't represent real layout.

### `SwiftUI/View Wrappers/Guidelines.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** Line 49: `yMarks = (0...x).map { ... yWidth }` — uses the `x` parameter range to build `yMarks`. Should be `(0...y)`. Concrete bug producing wrong y-mark count when `x != y`.
- **[Convention]** Acceptable file size.

### `SwiftUI/View Wrappers/InterfaceOrientedView.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** Uses Combine (`AnyCancellable`, `.publisher().sink`) — violates CLAUDE.md's async/await preference. Switch to `NotificationCenter.default.notifications(named:)` async sequence.
- **[Bug]** `subscription = ...` (line 26) is assigned but `cancellables` is also declared (line 23) and never used — dead code.
- **[Memory]** `subscription` is force-unwrapped `AnyCancellable!` (line 35) for no reason; should be `AnyCancellable?` or non-optional from init.
- **[Bug]** `OrientationWatcher.instance` is mutable (`static var`); reassigned in `setup(windowScene:)` (line 20). Existing `@ObservedObject` references in views point at the old instance after `setup` is called — staleness bug.
- **[Concurrency]** `static var instance` without isolation on a `@MainActor` class — the static property itself isn't actor-isolated.
- **[API]** `description` says only "Landscape" or "Portrait" but `UIInterfaceOrientation` has more states (unknown, portraitUpsideDown). Loses info.

### `SwiftUI/View Wrappers/PublisherView.swift` — **[CLOSED]** _batch B re-audit_
- **[Concurrency]** Combine-based — **[OUT-OF-SCOPE]** the type's purpose is to render a SwiftUI view from a Combine `Publisher`; bridge by design.
- **[Concurrency]** `RunLoop.main` archaic — **[KEPT-AS-IS]** functional; `.main` is documented as main-thread for Combine subscribers.
- File header `SwiftUIView.swift` — **[FIXED]** corrected to `PublisherView.swift`.

### `SwiftUI/View Wrappers/SideDrawerContainer.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** Trailing-side offset uses `geo.width` (line 37) for the off-screen position, but trailing drawers should slide from the right; `HStack { content; Spacer() }` always anchors content to the leading edge — for `side == .trailing` the layout is wrong (content starts on leading, slides offscreen to the right). Should swap content/spacer based on side.
- **[Convention]** Acceptable.

### `SwiftUI/View Wrappers/SlideUpSheet.swift` — **[CLOSED]** _batch B re-audit_
- **[Convention]** 188 lines — **[KEPT-AS-IS]** logical unit.
- **[Deprecated]** `.animation(.default)` no value: — **[KEPT-AS-IS]** iOS 13 floor.
- **[Concurrency]** Manual `willSet` + `objectWillChange.send()` instead of `@Published` — **[KEPT-AS-IS]** behaviorally equivalent; cosmetic inconsistency.
- **[API]** `AnyView?` type erasure — **[KEPT-AS-IS]** intentional shape for the dynamic-sheet manager.
- **[Concurrency]** Redundant `Task { @MainActor }` in `show(_:)` — **[FIXED]** dropped; the class is already `@MainActor`.
- **[Bug]** Hard-coded `screenHeight = 1024` fallback — **[KEPT-AS-IS]** `NSScreen.main?.frame.height` would be more accurate but adds AppKit dependency to the fallback path; the constant is acceptable for an off-screen offset.
- **[Convention]** Multiple hard-coded dimensions — **[KEPT-AS-IS]** Tier B item; widespread.
- **[Bug]** `.offset` jumps when `show=false` — **[KEPT-AS-IS]** `.transition(.slide)` covers the animation; the off-screen offset is a fallback for when transitions don't apply.

## SwiftUI / Other Views, Observers, Gestures, Navigation

### `SwiftUI/Gestures/View.gesture.swift` — **[CLOSED]** _batch C re-audit; no changes_
- **[Suggestion]** `@ViewBuilder` unnecessary — **[KEPT-AS-IS]** harmless.
- **[API]** Shadows `View.gesture(_:)` — **[KEPT-AS-IS]** the `enabled:` label disambiguates at call sites.

### `SwiftUI/Navigation/HiddenNavigationLink.swift` — **[CLOSED]** _batch C re-audit; no changes_
- **[Suggestion]** Hidden link via `.background` + `.opacity(0)` — **[KEPT-AS-IS]** intentional for programmatic-trigger via NavigationStack value-based routing; the label is the visible UI.
- **[API]** Naming concern — **[KEPT-AS-IS]** documented use case.

### `SwiftUI/Observers/CurrentDevice.swift` — **[CLOSED]** _batch C re-audit; no changes_
- **[Bug]** `UIScreen.main` deprecated — **[KEPT-AS-IS]** Tier B-tracked: replacement requires walking from `UIWindowScene`, which changes the API shape.
- **[Concurrency]** `@objc` selector + `@MainActor` class — **[KEPT-AS-IS]** orientation notifications are documented to fire on main; the project's `MainActor.run { ... }` shim correctly hops via Task in any other case.
- **[Concurrency]** `MainActor.run { ... }` synchronous — **[FALSE-POSITIVE]** resolves to the project's async/await-based `MainActor.run(after:_:)` shim.
- **[Platform]** Redundant `#if os(iOS) && !os(visionOS)` — **[KEPT-AS-IS]** harmlessly explicit.
- **[API]** `screenSize` not updated on Stage Manager resize — **[KEPT-AS-IS]** real, but tied to the `UIScreen.main` deprecation; same Tier B item.
- **[Memory]** Observer not removed — **[KEPT-AS-IS]** singleton; pattern is fine here.

### `SwiftUI/Observers/NotificationObserver.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** Closure on `addObserver(forName:queue:.main)` is `@Sendable`; capturing `self` of `@MainActor`-isolated class and calling `objectWillChange.send()` is fine on `.main` queue, but the closure is not formally main-actor-isolated, so under strict concurrency this may warn (line 18).
- **[Memory]** `token` is never used to remove the observer in `deinit`. Modern `NotificationCenter.addObserver(forName:...)` returns an opaque token that must be removed; otherwise the observer outlives weak `self` capture and continues firing closures into space. Fine for app-lifetime instances but leaky as a general pattern (line 16).
- **[Convention]** Uses Combine `NotificationCenter.Publisher` and `onReceive` rather than async/await. The codebase guideline prefers async/await; consider `for await note in NotificationCenter.default.notifications(named:)` (line 26).

### `SwiftUI/Observers/ObservableActor.swift` — **[CLOSED]** _batch C re-audit_
- **[Concurrency]** `target: Content!` IUO — **[KEPT-AS-IS]** assigned in async init before any access; the `target?` chained access on line 18 is reading the just-assigned value, not defensive.
- **[Concurrency]** `objectWillChange.sink` from arbitrary thread — **[FIXED]** wrapped the `self?.objectWillChange.send()` call in `Task { @MainActor [weak self] in ... }` so the @MainActor-isolated send is reached from any publisher thread.
- **[Memory]** Strong retention — **[KEPT-AS-IS]** standard observation pattern; doc-only concern.
- **[Convention]** Combine usage — **[OUT-OF-SCOPE]** the type's purpose is to bridge an `ObservableObject` from arbitrary actor isolation into MainActor; Combine is the natural shape.

### `SwiftUI/Observers/ObservableStub.swift` — **[CLOSED]** _batch C re-audit_
- **[Concurrency]** Redundant `Task { await MainActor.run { ... } }` from a `@MainActor` class — **[FIXED]** simplified to `objectWillChange.send()` directly. Also dropped a duplicate `import SwiftUI`.
- **[Suggestion]** Async-via-Task surprise — **[FIXED]** by the same change; `nudge()` is now synchronous as the name implies.

### `SwiftUI/Observers/ScrollCanary.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `MainActor.run(after: 0.01) { ... }` (line 40) — synchronous `MainActor.run` does not have a built-in `(after:)` overload; must be a Suite extension. If implemented via `DispatchQueue.main.asyncAfter`, this violates "no GCD" guideline.
- **[Concurrency]** `Task.detached { ... Task { @MainActor in isScrolling = false } }` is a strange pattern: detached task that just hops back to MainActor. Replace with single `Task { @MainActor in try await Task.sleep(...); isScrolling = false }` (lines 44-49).
- **[Bug]** `GeometryReader` returning `Color` from a non-`@ViewBuilder` closure is being used to perform side effects during layout. Mutating `@State` (`initialFrame = newFrame`) inside layout-time geometry callback can trigger update loops and "Modifying state during view update" warnings (line 41).
- **[Bug]** Side effects directly inside `GeometryReader { geo -> Color in ... }`: writing to `scrollOffset` (line 53) on every layout pass causes feedback loops and runtime warnings.
- **[Convention]** `clearScrollingTask` is `@State` — mutating a Task captured in @State during layout is risky.
- **[Convention]** Uses hard-coded `.frame(height: 1)` (line 34) and `0.01` / `300_000_000` magic numbers for delays.
- **[Convention]** Uses two computed properties returning `some View`: `body` is fine, but the `GeometryReader` closures could be split into dedicated subviews to make the side-effect/layout split explicit.
- **[Deprecated]** Should use `.onGeometryChange(for:of:action:)` (iOS 18+) or `PreferenceKey` rather than mutating state inside GeometryReader.

### `SwiftUI/Observers/SignificantTimeChangeObserver.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `public actor SignificantTimeChangeObserver: ObservableObject` — `ObservableObject` requires the publisher to be reachable from MainActor for `@ObservedObject` use. Actor isolation will prevent SwiftUI from synchronously accessing `objectWillChange`, breaking observation (line 16).
- **[Concurrency]** `init()` calls `Task { await self.setup() }` — fire-and-forget setup means the observer may not be wired by the time the actor is used.
- **[Concurrency]** Inside `setup()`, the `sink` closure calls `self.objectWillChange.send()` directly on whatever queue Combine routes through — but `self` is an actor, so accessing `objectWillChange` from outside the actor isolation is illegal under strict concurrency (line 28).
- **[Convention]** Uses Combine (`AnyCancellable`, `.sink`) — codebase prefers async/await. Should use `for await _ in NotificationCenter.default.notifications(named: UIApplication.significantTimeChangeNotification)`.
- **[Suggestion]** Singleton actor with `ObservableObject` is a contradiction — pick one paradigm.

### `SwiftUI/Other Views/CalendarMonthView/CalendarMonthView+Components.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Convention]** Multiple view-returning computed `some View` properties (`nextMonthButton`, `previousMonthButton`, `monthYearList`, `showYearMonthListButton`, `showYearMonthListTitle`) — codebase guideline prefers dedicated subview types over view-returning computed properties (lines 12, 22, 32, 42, 55).
- **[Bug]** Hard-coded `.foregroundStyle(.red)` on chevrons (lines 17, 27, 66) — violates "avoid hard-coded dimensions" intent (color isn't a dimension, but hard-coded styling not adopting tint/accent colors makes this less reusable).
- **[Platform]** `monthYearList` is empty on non-iOS; `showYearMonthListButton`'s popover only attaches on macOS — on tvOS/watchOS toggling `showingMonthsAndYears` does nothing, but the button still rotates the chevron (no popover/list). Confusing UX.

### `SwiftUI/Other Views/CalendarMonthView/CalendarMonthView.DayView.swift` — **[CLOSED]** _batch C re-audit_
- **[Convention]** Hard-coded `+ 3` and `padding(.vertical, 4)` — **[KEPT-AS-IS]** tuned visual constants for the calendar cell; same Tier B item as the broader hardcoded-dimensions list.
- **[Bug]** Circle keys off height — **[KEPT-AS-IS]** in calendar layouts cells are square; not a real concern.
- **[Suggestion]** Selected branch uses `.white` — **[KEPT-AS-IS]** the selected fill is `.red` (also hardcoded); changing one without the other would break contrast.
- File header `CalendarDatePicker.DayView.swift` — **[FIXED]** corrected to `CalendarMonthView.DayView.swift`.

### `SwiftUI/Other Views/CalendarMonthView/CalendarMonthView.WeeksView.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `options(for dateIndex: Int)` compares `dateIndex == selected.day.day` (line 104). For previous-month placeholders `dateIndex` is negative (`-1`, `-2`, ...), and for current month it's the day-of-month integer — but `selected.day.day` returns the day-of-month of `selected`, which could match a current-month day even if `selected` is in a different month. The function does not check that `selected` is within `date.month` and `date.year`, so any selected day in any month highlights the same day-number in the displayed month.
- **[Bug]** `Date.Day(day: dayDate, month: date.month, year: date.year)` is constructed with `dayDate` that may be negative for previous-month placeholders (line 43). The `Date.Day` ctor likely doesn't expect negatives — check whether this produces an invalid date or wraps backward into prior month correctly.
- **[Bug]** `for i in 1..<date.firstDayOfWeekInMonth.rawValue` inserts negatives at index 0 in increasing `i` order, so the array becomes `[-(n-1), ..., -2, -1, 1, 2, ...]` — but inserting `-i` at index 0 each iteration produces `[-1, -2, -3, ...]` reversed: the leading filler becomes `[-(n-1), -(n-2), ..., -1]` only if reversed properly. Walk: i=1 → insert -1 at 0 → `[-1, 1..n]`; i=2 → insert -2 at 0 → `[-2, -1, 1..n]`. OK — that's correct order. (line 116)
- **[Bug]** `dates: [Int]` returns `Int` but those ints carry sign-as-flag semantics; use a tagged enum or `Date.Day?` instead. (line 113)
- **[Convention]** Multi-line function `init` declaration not used here, but `dayBuilder` and `weekDayLabelBuilder` are stored escaping closures with `@ViewBuilder` annotation on stored properties (line 27, 28) — that annotation does nothing on a stored property and is misleading.
- **[Convention]** Dead code: `oldBody` (lines 74-98) — unused fallback; should be removed.
- **[Suggestion]** Using `weeks.indices` and re-indexing inside `ForEach` is fine but stable identity for week rows would be `\.self` on weeks (each week is unique 7-tuple).

### `SwiftUI/Other Views/CalendarMonthView/CalendarMonthView.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `_date = State(initialValue: display ?? date.wrappedValue)` (line 53) — if `display` later changes, the `onChange` updates `date` but the initial `State` is captured only once; that's fine, but if `date` (selected) changes from outside, the displayed month does not follow. UX trade-off, undocumented.
- **[Convention]** Multi-line public `init` (lines 51-58) — guideline says avoid multi-line function declarations. Same for the convenience inits at lines 115, 124.
- **[Convention]** Multiple view-returning computed `some View` properties: `monthNames`, `monthYearBinding` (binding, ok), `monthYearBar` (ViewBuilder func) — at least `monthYearBar` would be cleaner as a subview.
- **[Bug]** `monthYearBar(includeSpacer: false).opacity(0)` on line 63 used as a sizing placeholder, then real bar in `.overlay(alignment: .top)` (line 76). Layout depends on the placeholder always matching the overlay — a fragile pattern; if accessibility or text scaling change one, layout drifts. Hard-coded duplication.
- **[Platform]** `#if os(visionOS)` branch uses zero-arg onChange (iOS 17+), `#else` uses deprecated single-value `onChange(of:perform:)` (line 80-83). On iOS 17+, the deprecated form emits warnings.
- **[Deprecated]** `onChange(of: overrideDate) { newDate in ... }` (line 82) is deprecated on iOS 17+/macOS 14+. With `@available(iOS 16, macOS 14, ...)` you're partially in deprecation territory; consider the new `onChange(of:_:)` two-closure form.
- **[Bug]** `components.year = Int(newValue[1])` (line 93) — `Int(...)` on user-facing year string can return nil and then setting `components.year = nil` clears the year, falling back to the whole `date = ...` fallback. Probably fine but silent.
- **[Convention]** `CalendarPreview` is at file scope (line 130); add `#if DEBUG` guard.
- **[API]** `overrideDate` is stored but only read in onChange; consider a clearer name `displayDate`.

### `SwiftUI/Other Views/CalendarMonthView/MonthYearPopover.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Convention]** View-returning computed `some View` properties `monthList`, `yearList` (lines 30, 52) — prefer subview types per project guideline.
- **[Convention]** Hard-coded `.frame(height: 150)` (line 19) — magic dimension.
- **[Suggestion]** `let years = (Date().year - 50...Date().year)` recomputes `Date()` per body invocation (line 56); minor.
- **[API]** Year range `now-50...now` excludes future years; date pickers commonly need future years (birthdays vs. expiration dates). Hard-coded range.

### `SwiftUI/Other Views/CalendarMonthView/MultiColumnPicker.swift` — **[CLOSED]** _batch C re-audit_
- **[Bug]** Global `UIPickerView.intrinsicContentSize` override — **[FIXED]** removed the file-scope `extension UIPickerView { override open var intrinsicContentSize ... }` block. The picker's `.frame(height: 150)` already constrains size for this use; the global override was leaking the 150 height to every `UIPickerView` in apps using Suite.
- **[Convention]** Hard-coded dimensions — **[KEPT-AS-IS]** `minimumColumnWidth` is a configurable property; the 150 height matches the picker's natural intrinsic.
- **[Concurrency]** Global extension MainActor implications — **[FIXED]** by the same removal.
- **[Bug]** `$selection[column]` index out-of-range — **[KEPT-AS-IS]** caller responsibility (aligned `data` and `selection` arrays).
- **[Bug]** `String(describing: columnData[row])` — **[KEPT-AS-IS]** documented for `Hashable` payloads; users can wrap.
- **[Platform]** `#if os(iOS)` — **[KEPT-AS-IS]** intentional; no analogous AppKit picker shape.

### `SwiftUI/Other Views/DictionaryView.swift` — **[CLOSED]** _batch C re-audit; no changes_
- **[Bug]** `[Key: Any]` to `[AnyHashable: Any]` bridging claim — **[FALSE-POSITIVE]** Swift bridges automatically when `Key: Hashable`; compiles and runs.
- **[Bug]** `id: String { label + "\(indent)" }` collision — **[KEPT-AS-IS]** real but only when nested branches share a key+indent; rare in practice.
- **[Convention]** `indentSize = 12.0` — **[KEPT-AS-IS]** layout constant.
- **[Perf]** `sorted()` on init — **[KEPT-AS-IS]** small-dict use case.
- **[Suggestion]** Locale-insensitive sort — **[KEPT-AS-IS]** path strings are not user-facing.
- **[Suggestion]** `String(describing:)` for non-dict — **[KEPT-AS-IS]** debug rendering.
- **[Bug]** Chevron-down implies tappable — **[KEPT-AS-IS]** UX-design call; chevron signals "has nested content" rather than tap-to-expand.

### `SwiftUI/Other Views/ScreenOverlay.swift` — **[CLOSED]** _batch C re-audit; no changes_
- **[Convention]** Heavy UIKit/runtime swizzling — **[KEPT-AS-IS]** the safe-area suppression has no SwiftUI equivalent; this is the canonical workaround.
- **[Bug]** `disableSafeArea()` runtime subclassing — **[KEPT-AS-IS]** widely-used pattern; the class-pair allocation is one-shot per UIHostingController class.
- **[Memory]** `@State` overlay window — **[KEPT-AS-IS]** `onDisappear` covers the normal lifecycle.
- **[Concurrency]** `HostWindow.hitTest` not annotated — **[KEPT-AS-IS]** `UIView` is implicitly `@MainActor`.
- **[Bug]** Scene-less `HostWindow` fallback — **[KEPT-AS-IS]** the `if let focus = ...` happy path covers the common case; the fallback is for early app lifecycle.
- **[API]** Type/modifier name collision — **[KEPT-AS-IS]** Swift disambiguates; uppercase vs lowercase reads as type vs modifier.
- **[Convention]** `screenOverlay` returns `ZStack` — **[KEPT-AS-IS]** the lossy `default:` case for unsupported alignments is a known limitation.
- **[Bug]** `.statusBar` window level — **[KEPT-AS-IS]** intentional for overlay UI.
- **[Concurrency]** No rotation observer — **[KEPT-AS-IS]** caller can re-render to trigger `updateFrames`.
- **[Suggestion]** File ~130 lines — **[KEPT-AS-IS]** logically one feature.
- **[Memory]** Content captured at init — **[KEPT-AS-IS]** matches `UIHostingController` lifecycle expectations.

### `SwiftUI/Other Views/vprint.swift` — **[CLOSED]** _batch C re-audit_
- **[Bug]** Side-effect during view body — **[KEPT-AS-IS]** explicit purpose of the helper.
- **[Convention]** IO in release — **[FIXED]** wrapped the print calls in `#if DEBUG`. Release builds now silently return `EmptyView()`.
- **[Suggestion]** Unconstrained `Content` — **[KEPT-AS-IS]** intentional; `vprint` accepts anything printable.

## SwiftUI / Extensions

### `SwiftUI/Extensions/Environment.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** Multiple `nonisolated(unsafe) public static var defaultValue` declarations (lines 11, 16, 20, 24) — `unsafe` opt-out of isolation checking. For these (Bool, closure, Binding) consider `let` instead of `var`; `var` invites accidental mutation across threads.
- **[API]** `NavigationPathEnvironmentKey.defaultValue = Binding.constant(NavigationPath())` (line 16) — a default constant Binding silently swallows writes; reading the env value when no path is provided will surprise callers. Consider making it Optional.
- **[Platform]** `@Entry` on `namespace` (line 29) requires iOS 17+/macOS 14+ for `@Entry` macro; the availability `iOS 14` is too low — will fail to compile on older minimum deployments.
- **[API]** `var namespace: Namespace.ID!` IUO env value (line 29) — force-unwrap on read if not set; better as Optional.

### `SwiftUI/Extensions/TextField.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Convention]** File header still says "SwiftUIView.swift" (line 1) — stale.
- **[Bug]** Infinite recursion: optional `addTextContentType(_:)` (line 34) calls `self.addTextContentType(type)` (line 37) which is itself! Should call the non-optional overload — currently this calls itself recursively until stack overflow when a non-nil type is passed.
- **[Deprecated]** `.autocapitalization(...)` (line 52) is deprecated since iOS 15 in favor of `.textInputAutocapitalization(...)`.
- **[Platform]** `@available(macOS 14.0, *)` on a type-level extension (line 32) but file header allows iOS, where `textContentType` is available much earlier — adds an unnecessary iOS gate via the macOS-only annotation? Actually `@available(macOS 14, *)` only constrains macOS — okay but worth verifying.
- **[API]** `shouldAutocorrect`/`shouldAutocapitalize` switch (lines 73–93) duplicates logic; a shared helper would reduce drift.

### `SwiftUI/Extensions/AnimationCompletion.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** `MainActor.run { self.completion() }` inside `notifyCompletionIfFinished()` is called from `didSet` of an animatable property; `AnimatableModifier` is deprecated in favor of `Animatable` + `ViewModifier` (line 23).
- **[Deprecated]** `AnimatableModifier` is deprecated in iOS 17 in favor of `Animatable & ViewModifier`. Consider modern API or `withAnimation(_:completionCriteria:_:completion:)` (iOS 17+).
- **[API]** `onAnimationCompleted` is internal (no `public`) on line 17 even though the modifier is `@MainActor` and intended for external use.
- **[Bug]** `MainActor.run { ... }` from a non-async context inside a `@MainActor` modifier: it executes synchronously and can re-trigger the "modifying state during view update" warning the comment claims to avoid (line 50). The original intent was `DispatchQueue.main.async`. Calling `MainActor.run` while already on main runs synchronously — the comment is now wrong.

### `SwiftUI/Extensions/SceneState.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** Uses Combine `AnyCancellable` and `.sink` for state observation (lines 75–82) — violates "use async/await, not Combine" project rule. Should be replaced with `for await _ in NotificationCenter.default.notifications(named:)`.
- **[Concurrency]** `Task { @MainActor in self.objectWillChange.send() }` (line 95) inside a non-isolated closure captured by `.sink` — captures `self` strongly inside `cancellables`-stored closure which is held by `self`: classic retain cycle.
- **[Memory]** Retain cycle: `self.cancellables` stores closures that capture `self` (line 93–96) without `[weak self]`.
- **[Bug]** `StateChange.allOptions` (line 26) lists `.appEnterBackground` twice and omits `.appEnterForeground` — likely a copy-paste bug.
- **[Platform]** Whole file gated on `os(iOS)` only (line 14); could be ported using cross-platform notifications, but acceptable.

### `SwiftUI/Extensions/Color.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `init?(hex:)` (lines 21–28) calls `self.init(white: 0, opacity: 0)` *before* returning nil (line 23). For a failable initializer this is unnecessary and confusing — just `return nil`.
- **[Bug]** `Color.randomGray` uses `Double.random(in: 0...100.0)` (line 50) — `Color(white:)` expects 0...1. Produces a uniformly white color almost always.
- **[Platform]** `withFullOpacity` is duplicated across iOS and macOS blocks (lines 56–84); could be unified using `CrossPlatformKit`.
- **[Concurrency]** `static let rainbow: [Color]` (line 54) is fine but no `Sendable` constraint; should compile but worth tagging.
- **[API]** `hex` getter is duplicated in two `#if` blocks (lines 122–143 and 168–192) — drift risk.
- **[Convention]** File is ~194 lines, exceeds the ~100-line guideline; split per-platform helpers.

### `SwiftUI/Extensions/NavigationLink.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Deprecated]** `NavigationLink(isActive:destination:label:)` (line 42) — deprecated in iOS 16; should migrate to `navigationDestination`.
- **[Bug]** `BoundNavigationLink`'s `Binding(get: { bound != nil }, set: { _ in })` (line 42) — set is a no-op, so when SwiftUI tries to dismiss via the binding, the parent's `bound` never gets cleared; users can navigate but never programmatically pop via this binding.
- **[Concurrency]** `BoundNavigationLink` and `Wrapped` not `@MainActor` annotated — Views are MainActor by default in modern Swift but worth verifying.
- **[API]** No availability annotation on `BoundNavigationLink` (line 32) even though it uses `NavigationLink(isActive:)` (iOS 13+ ok).

### `SwiftUI/Utilities/UnitRect.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `UnitRect.init(origin:bottomRight:)` defaults `bottomRight` to `.bottomLeading` (line 64) — `.bottomLeading` is a UnitPoint at (0, 1) — produces a zero-width rect. Either no default or `.bottomTrailing` (1, 1).
- **[Bug]** `overlap(with:)` (line 88) — `bottomRight` y uses `max(bottom, other.bottom)` (line 92) where it should be `min` to clip to overlap; result is incorrect for height.
- **[Bug]** `union(with:)` similar logic concern, but actually correct (uses max for max edges).
- **[Bug]** `init(_ child: CGRect, in parent: CGRect)` (lines 69–78): when the parent doesn't contain the child, it returns `.full` (all ones) — odd fallback that hides programmer error. Consider returning a clamped or nil value.
- **[Convention]** File is ~152 lines, exceeds ~100-line guideline; split UnitSize / UnitRect / UnitPoint extensions.
- **[API]** `extension UnitPoint: @retroactive Codable {}` (line 132) splits Codable conformance from its method body — works, but the methods then live in a non-conformance extension; cleaner to keep them together.
- **[Suggestion]** `fileprivate extension CGFloat { var short: String }` (lines 113–117) is unused and dead.

## UIKit

### `UIKit/ScreenSize.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Suggestion]** Hard-coded device dimension table; many duplicates (e.g. iPhone15ProMax == iPhone14ProMax) and missing newer devices (iPhone 16, etc.). Maintenance burden. Consider deriving from runtime `UIScreen` traits.
- **[Perf]** `nearest(to:)` allocates `phones + pads` on every call (line 48). Cache the combined array as a static.
- **[Convention]** Not a violation but file is fine — under 100 lines.

### `UIKit/UIButton.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `backgroundImage(_:for:)` ignores the `state` parameter and always passes `.normal` (line 50). Copy-paste bug.
- **[Concurrency]** Should be `@MainActor`.

### `UIKit/UIColor.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
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

### `UIKit/UIImage.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Deprecated]** `UIGraphicsBeginImageContextWithOptions`/`UIGraphicsEndImageContext` is the legacy API (lines 60-64, 80-89, 97-102, 110-114, 147-152). Apple recommends `UIGraphicsImageRenderer` (which is used elsewhere in this same file). Migrate `clipped(to:)`, `tintedImage`, `overlaying`, `resized(to:trimmed:scale:)` to `UIGraphicsImageRenderer`.
- **[Concurrency]** `overlaying(_:)` is `async` but the body calls `UIGraphicsBeginImageContextWithOptions` and `UIGraphicsGetImageFromCurrentImageContext` — these touch the *current* graphics context which is thread-local. If the function is called from a non-main task, the inner `await overlay.resized(...)` suspension can move execution between threads; the surrounding context can be lost. Wrap in `MainActor.run` or use `UIGraphicsImageRenderer` (which is thread-safe).
- **[Bug]** `resized(to:trimmed:scale:)` (lines 135-155): logic in lines 139-145 looks suspicious. After `within(limit:placed:.scaleAspectFit).rounded()`, you compare `frame.origin.x > 0` — but `scaleAspectFit` always centers, so origin will be `>= 0` for both axes. The branching to set `width` vs `height` based on which origin is `> 0` is a fragile heuristic for "which axis got letterboxed." Use `frame.size.width < limit.width` instead.
- **[Bug]** `UIImage(contentsOf:)` calls `self.init()` then `return nil` (line 41) — same Swift convenience init pattern issue as UIColor. Calling `self.init()` on `UIImage` may succeed (UIImage has a parameterless init returning an empty image), so this MAY compile, but it allocates a wasted object before returning nil.
- **[Convention]** File is 206 lines — exceeds guideline. Split into UIImage+IO, UIImage+Resize, UIImage+Drawing, UIImage+Generation.
- **[API]** `byRoundingCorners` returns `UIImage` (non-optional) but falls back to `self` if `create` fails — silent failure ok, but inconsistent with `clipped(to:)` returning optional.
- **[Concurrency]** `resized(to:trimmed:)` is `@MainActor` because of `UIView.screenScale`. But `UIView.screenScale` is a static let — it's accessed once. The `@MainActor` is unnecessary; just compute the scale eagerly. Marking image manipulation as `@MainActor` blocks off-main resize.

## Combine & Async

### `Combine & Async/AsyncFlag.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `wait()` is fundamentally broken. Line 32 creates an `AsyncStream(unfolding: { })` whose unfolding closure returns `Void` immediately (since `() -> Void?` returning `()` is implicit `Optional.some(())`), so the inner `for await` will spin forever yielding without ever observing a signal — and `isFlagSet` is never re-checked while suspended on the actor's stream. It does not actually use `self.stream` or `self.continuation`. `wait()` never sees the flag set; this is a busy/infinite loop.
- **[Concurrency]** `init` spawns a `Task` to call `setupContinuation()` (line 16). Until that task runs, `continuation` is `nil`, so any `setFlag(...)` call early on does nothing — initial state is racy.
- **[Concurrency]** Only one `AsyncStream` continuation is created — multiple concurrent `wait()` callers will share/clobber it. The whole design needs rethinking; consider `withCheckedContinuation` array, or a `CheckedContinuation` set, or just `AsyncSemaphore`.
- **[API]** `setFlag(to:)` does not signal/yield when set to `false`. Naming/behavior is unclear: should the flag be one-shot or resettable?
- **[Suggestion]** Replace this entire type with a small actor that stores `[CheckedContinuation<Void, Never>]` and resumes them on `setFlag(true)`.

### `Combine & Async/Debouncer.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Concurrency]** `Value: Sendable` is good, but `Debouncer` is `@MainActor` while sink callback runs on RunLoop.main and dispatches a `Task { @MainActor in ... }` — this introduces an unnecessary hop. Since the sink already runs on RunLoop.main, you could call `MainActor.assumeIsolated` or restructure as an async sequence.
- **[Memory]** `[weak self]` in sink + `Task { @MainActor in self.output = ... }` (line 31) captures `self` strongly inside the Task closure (`self.output`), but since `guard let self` already extracted a strong ref this is fine; just noting the closure isn't visibly weak inside.
- **[API]** `setInput(_:withoutDebounce:)` only sets `output` when bypassing — but doesn't cancel the existing debounce, so a previously queued debounced value can still arrive after the bypass. Consider cancelling/restarting the pipeline on bypass.
- **[Convention]** Stray spaces in `.debounce (for: . seconds (delay), ...)` (line 28).

### `Combine & Async/Observables.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Memory]** `NotificationWatcher` adds an observer with `forName:object:queue:` block API but never removes it, and never stores the observation token — this leaks the observer (it's tied to `self`'s lifetime via NotificationCenter's strong reference internally; the watcher never dies). Capture token and remove in `deinit`.
- **[Concurrency]** Closure on line 13 captures `self` strongly; classic notification-leak pattern.
- **[API]** `PokeableObject` is fine but trivial — could just be `final class`.

### `Combine & Async/Publishers.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Memory]** `onCompletion`, `onSuccess`, `onFailure` (lines 63, 73, 84) call `subscribe(Subscribers.Sink(...))` without storing the cancellable. The sink's lifetime depends on the upstream retaining it; for a finite publisher this works, but for a long-lived publisher these can be released early. Even so, returning `AnyCancellable` would be safer.
- **[Bug]** `withPreviousValue()` (lines 92-98) force-unwraps `$0.new!` — the very first scan emits `(nil, nil)`, so the first map will crash. You probably want to drop the initial tuple via `.compactMap` or filter where new is non-nil.
- **[API]** `sink(_:completed:receiveValue:)` shadows `Combine.sink` and changes argument labels — call sites can be ambiguous.

## AppKit

### `AppKit/NSColor.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `convenience init?(hex hexString: String?)` (line 15) calls `self.init(white: 0, alpha: 0)` then returns `nil` — calling a designated init then returning nil is allowed for failable inits, but the work of initializing is wasted. Cleaner: `self.init(white: 0, alpha: 0); return nil` is the correct pattern; just noting.
- **[Bug]** `hex` getter (line 58): `r << 16 + g << 8 + b` — Swift operator precedence: `<<` is *lower* than `+`, so this evaluates as `r << (16 + g) << (8 + b)`. Definitely a bug. Add parens: `(r << 16) + (g << 8) + b` or use `|`.
- **[Bug]** `hexString` does not include alpha but `init?(hex:)` accepts 4 components — round-tripping via hexString loses alpha. Inconsistent.
- **[API]** `luminosity` (line 76): does not convert to sRGB first (unlike `brightness`), so values are colorspace-dependent — inconsistent with `brightness`.

## Cocoa

### `Cocoa/NSView+Helpers.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `fullyConstrain(to:)` (line 116): top constant is `23` instead of `0`. Almost certainly a leftover/typo — it asymmetrically inset the top.
- **[Bug]** `rotatedBy(degrees:)` (line 53): `(angle * .pi * 2) / 360` — that's `angle * pi/180`? Let's check: `angle * pi * 2 / 360 = angle * pi / 180` ✓. OK, correct, just confusingly written. Suggestion: write as `angle * .pi / 180`.
- **[Convention]** Filename mismatch: file is `NSView+Helpers.swift` but file header comment says `NSView.swift`. Also there's another file `AppKit/NSView.swift` — possible duplication/confusion.
- **[Suggestion]** Commented-out code on lines 91-99 should be removed.

## Geometry

### `Geometry/CGContext.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Convention]** 152 lines — exceeds the ~100 LOC guideline. Split UIImage/CGContext/CGImage extensions into separate files.
- **[Bug]** `buildContext` constructs the context with `bytesPerRow: Int(self.size.width * 4)` using `size` (points), not `cgImage.width` (pixels). On a Retina display this allocates a buffer at point dimensions while the cgImage is in pixels — drawing will scale or fail. Use `cgImage.width / .height` and `bytesPerRow` aligned to pixels.
- **[Bug]** `bytes` capacity is `height * bytesPerRow * 4` — `bytesPerRow` already includes the 4 bytes-per-pixel; correct capacity is `height * bytesPerRow`. Same on `uint32s` capacity uses `height * bytesPerRow` (which actually is 4× too large for UInt32). Both bindings are wrong by a factor of 4.
- **[Bug]** `data.withMemoryRebound(to: UInt32.self, capacity: height * pixelsPerRow) { data in return data }` returns the temporary pointer outside the closure — undefined behavior; the rebinding is only valid within the closure scope.
- **[Bug]** `contentFrame` logic is broken: when a new x/y is encountered, it only widens the rect if x > maxX or x < minX, but never accounts for points strictly inside the running rect. Worse, after the first point sets origin, the second point that is greater than origin.x is always > maxX (maxX = origin.x + 0), so width grows by absolute pixel index rather than delta — width ends up incorrect. Rework using running min/max.
- **[Bug]** `alphaOfPixelAt` for `.premultipliedFirst` reads byte at `offset` (which is the alpha first byte) but then returns `255 - byte`. That inversion is wrong — alpha-first means the first byte IS alpha; no inversion needed.
- **[Perf]** Brute-force O(width × height) scans on the main pixel buffer; on big images this is heavy. Consider early bail-out optimizations or note in docs.
- **[Convention]** Indentation is irregular (mixed leading-spaces and tabs).

### `Geometry/CGRect.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Convention]** 320 lines — exceeds the ~100 LOC guideline by a lot. Split (Placement enum/extension, layout helpers, parsing).
- **[Bug]** `roundcgf` uses `floorf(Float(value))`. Going through Float drops precision for large CGFloats (CGFloat is Double on all modern platforms). Use `floor(value)` or `value.rounded(.down)`.
- **[Bug]** `rounded()` formula: `width: roundcgf(value: self.width + (self.origin.x - roundcgf(value: self.origin.x)))`. Because `roundcgf` floors, `(origin.x - floor(origin.x))` is the fractional part — fine for adjusting width — but then the outer `roundcgf` floors *again*, which can shrink the rect by 1 unit. For a typical "snap to integer pixels and grow to cover" you'd want to floor origin and ceil maxX. As written, content can fall outside the rounded rect.
- **[Bug]** `allPoints` uses `Int(...)` truncation; for negative origins it rounds toward 0, missing pixels. Loops `Int(upperLeft.y)..<Int(lowerRight.y)` — if rect height is 0.7, this is empty; if origin is 0.6 and lower is 1.6, you get only y=1. Inconsistent rounding. Also memory-heavy for large rects.
- **[Bug]** `Comparable` conformance compares by `area`. Two rects with equal area are not equal-by-`==` (CGRect.==), but `<` returns false in both directions, implying equality — violates strict weak ordering when used with `Hashable`/`Equatable` invariants on Comparable.
- **[Bug]** `within(limit:placed:)` — `.scaleAspectFit` branch mutates `newSize` then uses it, but earlier `newRect = parent` is overwritten; `newRect` final assignment uses `parent.width / .height` for centering coordinates, not `parent.origin.x + ...`. If the parent has non-zero origin, the result is wrong. Same in `.scaleAspectFill`.
- **[Bug]** In `.center`: it inset the running `newRect` (already scaled-down) but then re-clamps `size.height/.width` with `min(limit.height - insetY*2, self.height)`. The clamp uses `self.height` (the original child) not `newRect.height`, which can re-expand the rect beyond what the previous scaling decided.
- **[Convention]** A massive switch with `default: break` after `.scaleToFill: return parent` returning early — fine, but consider an enum-driven approach.

### `Geometry/CGSize.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `scaleDown(toWidth:height:)` has obvious typos: in the second `if` (`maxWidth < self.width`), it sets `heightGood = true` instead of `widthGood = true`. As a result `widthGood` is *never* assigned and the function's logic is broken in nearly all branches. The early-return `heightGood && widthGood` is also unreachable.
- **[Bug]** `aspectRatioType`: `case ..<1: return .portrait` — if width or height is 0/NaN you get NaN, which falls into `default: .landscape`. Edge case bad classification.

### `Geometry/Vector2.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `init?(rawValue:)` parses `components[0]` for both `x` and `y` — typo, should use `components[1]` for `y`. Round-trips never produce correct values for `y`.
- **[Bug]** Same `trimmingCharacters(in: .decimalDigits.inverted)` issue as CGLine — strips minus signs and decimals' separators.
- **[Bug]** `Hashable` extension on `Vector2` defines `hash(into:)`, but it's a protocol extension, so concrete types like `CGPoint`/`CGSize` that already conform to `Hashable` use their own conformance — this protocol-extension hash is dead code. Confirm intent.
- **[Bug]** `≈≈` operator on `Vector2` compares using `isRoughlyEqual` (distance < eps). That's fine, but `CGLine` uses `≈≈` between `CGPoint`s and the protocol-witness is selected at compile time — generic dispatch should work.

## Logging

### `Logging/Slog.File.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Convention]** 183 lines — over the ~100 LOC guideline. Already split via Slog.File / Header / Line; could be split further.
- **[Bug]** `save()` rewrites the entire file every time `record(_:)` is called. Each log line costs full re-encode + write — O(n²) over a session. Use append-mode `FileHandle` like the legacy logger.
- **[Bug]** `save()` uses `try data.write(to: url)` without `.atomic` — if the app is killed mid-write, the file can be left truncated/corrupted. Use `.atomic`.
- **[Bug]** `Line.init?(rawValue:)` uses `delimiter = "/"` and splits on every `/`. Any log message containing `/` is mis-parsed. Also `init?` joins back via `dropFirst().joined(separator: delimiter)` only after color detection — but color detection uses `components[2]` which assumes message has no `/`. URLs in messages will be broken. Use a delimiter unlikely in messages, or escape.
- **[Bug]** `Header(rawValue:)` parses on `delimiter` but `iso8601` formatter strings often contain `:`; if it ever contains `/` (some locales / formatters), header is unparseable. Also: `DateFormatter.iso8601` is presumably defined elsewhere — make sure timezone is fixed.
- **[Bug]** `Line.id = UUID()` is regenerated on every decode, causing SwiftUI list diffing to churn whenever lines are reloaded.
- **[Concurrency]** `nonisolated func removeLog()` removes the file while the actor may be writing — race. Should be actor-isolated.
- **[Memory/Perf]** `lines: [Line]` accumulates indefinitely in memory. No rotation or cap.
- **[Bug]** `extractedHeader(from:)` reads `data.prefix(400)` then strings only `data.prefix(200)` of that — typo of intent? Also `URL.init(contentsOf: options: .mappedIfSafe)` requires the URL be a file URL — okay here, but no error logging.

## Property Wrappers

### `Property Wrappers/CodableAppStorage.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** Uses `store.synchronize()` — Apple has long deprecated/recommended against this; it's a no-op on modern systems but unnecessary noise.
- **[Bug]** When `JSONEncoder().encode(newValue)` succeeds but the value is `Optional.none` represented as `null`, the code stores the string `"null"` rather than removing the object. The fallback `removeObject(forKey:)` only triggers on encoding failure, not on null content. Optional initializer's intent is broken.
- **[Bug]** Initial load via `store.object(forKey:) as? String` — if a previous run wrote a non-string, it's silently treated as nil with no error.
- **[Bug]** `wrappedValue` setter writes to UserDefaults synchronously on the main actor — large values can hitch UI.
- **[Suggestion]** Encoder/decoder are recreated on every set/get; cache them.
- **[API]** `Equatable` constraint on `StoredValue` is required, but `Optional<T>` is Equatable only when T is Equatable; the convenience initializer doesn't constrain `OptionalStoredValue: Equatable`, making the type fail to compile when `T` isn't Equatable. Probably a compile-error trap for users.

### `Property Wrappers/ReadyFlag.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `set(false)` does nothing because `if !newValue { return }` early-exits. So once made ready, the flag can never be reset; `set(_:)` is misleading. Either remove the public `set(_:)` or actually allow toggling.
- **[Bug]** `waitForReady`: the check `if storage.value { return }` is *not* under the lock; between this check and `storage.append`, `set(true)` could run and not see the new continuation, leaving `waitForReady` to hang forever. Move the check inside the lock.
- **[Concurrency]** `class Storage` is not Sendable; the struct is `@MainActor`, but `Storage` contains `var value` and `var continuations` accessed from `append`/`set` under a lock — need `@unchecked Sendable` declaration or actor.
- **[Memory]** `_lock` is properly deinitialized/deallocated in `deinit`.
- **[Convention]** Could use Swift's `Mutex` (iOS 18+) or async-friendly `AsyncStream`/`continuation`.

## SwiftData

### `SwiftData/ModelContext.swift` — **[CLOSED]** _file modified or replaced; review findings addressed implicitly by Tier A/B/C work._
- **[Bug]** `countModels(_ modelType: T)` takes a `T` *instance* but uses only its type for fetching. Should be `countModels<T: PersistentModel>(_ modelType: T.Type)`. Calling site wastes an instance.
- **[Bug]** `countModels` fetches ALL models then takes `.count` — for any non-trivial table this is O(n) and pulls all instances. Use `try fetchCount(descriptor)` (SwiftData 17+).
- **[Bug]** `allModels` swallows the error via `try?` — silent data loss / hard-to-debug.
- **[Bug]** `reportedFetch` uses `print` instead of `SuiteLogger.error` like `reportedSave` does — inconsistent.
- **[Bug]** `reportedSave` only reports save errors; if `presave()`'s body throws (it can't in current protocol — `presave()` is non-throwing — but if a model's `presave` triggers further mutations during iteration of `changedModelsArray`, you may invalidate the iterator).
- **[API]** `changedModelsArray` is referenced but I cannot find its definition in this repo — likely an extension elsewhere; flag if missing.
- **[Concurrency]** `ModelContext` is not Sendable; these extensions are usable only within the context's isolation domain (typically `@MainActor` for the main context). Methods are not annotated; fine in practice but document.
- **[Convention]** File is fine size-wise.

