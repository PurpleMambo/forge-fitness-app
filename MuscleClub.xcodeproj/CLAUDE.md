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

`ContentView.swift` is the entry point (`@main MyApp`). It creates a single `AppState` instance and injects it via `.environment()`. `RootView` gates on `appState.onboardingComplete` to show either `OnboardingView` or `MainTabView`.

`AppState` (in `Models.swift`) is an `@Observable` class — the only shared mutable state. It holds `onboardingComplete`, `userInitials`, `planName`, and `selectedDate`.

### Data model

`Exercise` and `WorkoutDay` are plain structs. All workout data is hardcoded as static properties on `WorkoutDay` (`pushDay`, `pullDay`, `legDay`, `weekSchedule`). There is no persistence or networking layer yet.

### Onboarding flow (`OnboardingView.swift`)

Three phases driven by a `Phase` enum: `.chat` → `.plan` → `.signup`.

- `.chat`: Steps through an array of `OStep` values (question parts + answer options). Each answer is appended to `answers: [String]`. Animations use `busy` flag to prevent double-taps.
- `.plan`: `PlanSummaryView` — static summary screen.
- `.signup`: `SignUpView` — sets `appState.onboardingComplete = true` to exit onboarding.

### Main app flow (`DashboardView.swift`)

`MainTabView` has four tabs; only "Workout" (`DashboardView`) is implemented. The others are `PlaceholderTabView`.

`DashboardView` derives today's workout by mapping `appState.selectedDate` weekday → `WorkoutDay.weekSchedule` index. The workout card flow is:

1. Tap exercise row → `ExerciseSetupView` (sheet)
2. In `ExerciseSetupView`, tap "How-To" → `ExerciseDetailView` (sheet). Tapping video pauses/resumes inline.
3. Tap "Start Workout" from dashboard → `ActiveWorkoutView` (full-screen cover with live timer)

### Video playback (`ExerciseDetailView.swift`)

`LoopingVideoPlayer` is a `UIViewRepresentable` wrapping `AVPlayer` with `AVPlayerLayer`. It loops via `AVPlayerItemDidPlayToEndTime` notification.

`Bundle.videoURL(named:)` is a custom helper that handles Unicode NFC/NFD filename normalization — needed because the bundled `.mov` files have Icelandic names. Always use this helper instead of `Bundle.main.url(forResource:withExtension:)` when loading video.

`FullScreenVideoView.swift` exists but is currently commented out; tap-to-pause inline is used instead.

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
