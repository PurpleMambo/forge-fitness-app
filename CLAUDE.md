# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Use the Xcode MCP tools — not the command line — for all build and run operations:

- **Build**: `BuildProject`
- **Run**: `RunProject`
- **Check for compiler errors quickly**: `XcodeRefreshCodeIssuesInFile` (fast, no full build needed)
- **Run a snippet**: `RunCodeSnippet`

There are no tests yet.

## Architecture

### App entry & global state

`ContentView.swift` is the entry point (`@main MyApp`). It creates a single `AppState` and `StoreVM` instance, both injected via `.environment()`. `RootView` has a three-state gate:

1. `!appState.welcomeSeen` → `WelcomeView`
2. `!appState.onboardingComplete` → `NewOnboardingFlowView`
3. otherwise → `MainTabView`

`AppState` (in `Models.swift`) is an `@Observable` class — the only shared mutable state. Key fields:
- `welcomeSeen`, `onboardingComplete` — navigation gates
- `userInitials`, `planName`, `selectedDate` — user context
- `showActiveWorkout: Bool` — drives the full-screen workout cover from `MainTabView`
- `workoutStore: WorkoutStore` — the persistence layer
- `todayWorkout: WorkoutDay?` — computed from `selectedDate` weekday → `WorkoutDay.weekSchedule`

### Data model

`Exercise` and `WorkoutDay` are plain structs. All workout data is hardcoded as static properties on `WorkoutDay` (`pushDay`, `pullDay`, `legDay`, `weekSchedule`). `WorkoutStore` persists `[LoggedSetEntry]` to `UserDefaults` (key `workout_logged_sets_v1`). There is no networking layer.

### Onboarding flow (`NewOnboardingFlowView.swift`)

`NewOnboardingFlowView` is the active onboarding. It owns a `NewOnboardingFlowViewModel` (`@Observable`) which drives all navigation via a `Phase` enum:

```
.questions(Int) → .goalSpeed → .sleep → .supplements
→ .questions(…) → .calculating → .plan → .socialProof
→ .signUp → .featureShowcase → .commit
```

The 25-step questionnaire is defined in `newOnboardingSteps: [NewOnboardingStep]` (keyed by stable `id: Int`). The VM skips the World Class location step (id 13) when a different gym is chosen, and inserts `.goalSpeed`, `.sleep`, and `.supplements` custom screens at fixed branch points. `isGoingBack` flips the slide transition direction. `NewOnboardingFlow_CommitStepView` closes onboarding by setting `appState.onboardingComplete = true`.

`OnboardingView.swift` is an older chat-bubble onboarding — it is **no longer used** (replaced by `NewOnboardingFlowView`).

### Main app flow (`DashboardView.swift`)

`MainTabView` has four tabs; only "Workout" (`DashboardView`) is implemented. The others are `PlaceholderTabView`. The active workout is launched via `appState.showActiveWorkout = true`, which triggers a `.fullScreenCover` at the `MainTabView` level — this means the workout can be dismissed by setting `appState.showActiveWorkout = false` from anywhere.

`MainTabView` also hosts a `WorkoutAccessoryView` in `.tabViewBottomAccessory` (the music-player mini-bar pattern): it collapses to an inline bar when the user scrolls down.

`DashboardView` workout card flow:

1. Tap exercise row → sets `setupExercise`, shows `ExerciseSetupView` as a sheet
2. In `ExerciseSetupView`, tap "How-To" → `ExerciseDetailView` sheet (video instructions)
3. Tap "Start Workout" from dashboard → dismisses setup sheet, waits 350ms, sets `appState.showActiveWorkout = true`

### Active workout flow (`WorkoutExecutionView.swift`)

`ActiveWorkoutView` is a full-screen cover. Key interactions:

- Top-left `xmark` button and floating stop button (red circle at bottom) both set `showFinishSheet = true`
- `WorkoutFinishOverlay` slides up: tapping the backdrop or X resumes; tapping "Log Workout" cancels the timer, sets `showSummary = true`
- `WorkoutSummaryView` is a `.fullScreenCover` presented from within `ActiveWorkoutView`; its `onDone` calls `isPresented = false` which closes the whole active workout cover

### ExerciseSetupView dual modes (`ExerciseSetupView.swift`)

`ExerciseSetupView` serves two contexts controlled by which optional params are provided:

- **Setup mode** (`onStartWorkout` provided, `workoutStore` nil): shows warmup + working sets grid, "Start Workout" CTA
- **Active mode** (`workoutStore` provided): shows per-set logging with editable reps/weight fields, rest timer overlay, "Log Set" / "Log All Sets" CTA

### Video playback (`ExerciseDetailView.swift`)

`LoopingVideoPlayer` is a `UIViewRepresentable` wrapping `AVPlayer` with `AVPlayerLayer`. It loops via `AVPlayerItemDidPlayToEndTime` notification.

`Bundle.videoURL(named:)` is a custom helper that handles Unicode NFC/NFD filename normalization — needed because the bundled `.mov` files have Icelandic names. Always use this helper instead of `Bundle.main.url(forResource:withExtension:)` when loading video.

### In-app purchases (`StoreVM.swift` / `PaywallView.swift`)

`StoreVM` is an `@Observable @MainActor` class injected at the root alongside `AppState`. It manages two auto-renewable subscriptions:

| Product ID | Plan |
|---|---|
| `themuscleclub.subscription.yearly` | Annual |
| `themuscleclub.subscription.weekly` | Weekly |

Key state: `hasActiveSubscription: Bool`, `hasLoadedEntitlements: Bool`, `isLoading: Bool`. A background `Task` listens to `StoreKit.Transaction.updates` for the lifetime of the app.

`MuscleClubPaywallView` reads `StoreVM` from the environment and calls `storeVM.purchase(_:)`. Completion is detected two ways — the `purchase()` return value and an `onChange(of: storeVM.hasActiveSubscription)` observer — guarded by a `didComplete` flag to prevent double-firing.

### Design system

This is an iOS 26 app built entirely around **Liquid Glass**. Key patterns used throughout:

- `.glassEffect()` / `.glassEffect(.regular.tint(.appAccent))` — on containers and cards
- `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)` — standard button styles
- `GlassEffectContainer(spacing:)` — required wrapper for morph/matchedGeometry effects between sibling glass elements
- `.glassEffectID(_:in:)` with a `@Namespace` — for the animated selected-day pill in the week strip

The app is dark-only (`.preferredColorScheme(.dark)` set at the root).

### Colors (`Models.swift`)

Three app-wide colors defined as `Color` extensions:

| Name | Usage |
|---|---|
| `appBg` | Dark purple-black background |
| `appAccent` | Crimson red — primary interactive tint |
| `appGold` | Golden yellow — section headers, focus labels |

`AppBackground` is a reusable `View` that applies the standard gradient; use it as the base `ZStack` layer in every screen.
