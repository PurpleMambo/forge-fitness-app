# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Use the Xcode MCP tools — not the command line — for all build and run operations:

- **Build**: `BuildProject`
- **Run**: `RunProject`
- **Quick compiler check**: `XcodeRefreshCodeIssuesInFile` (fast, no full build needed)
- **Run a snippet**: `RunCodeSnippet`

There are no tests yet.

## Architecture

### App entry & global state

`ContentView.swift` is the entry point (`@main MyApp`). It creates three root-level singletons injected via `.environment()`: `AppState`, `StoreVM`, and `ProgramService`.

`RootView` has a four-state gate:

1. `!appState.sessionCheckComplete` → blank `AppBackground()` (splash while checking Supabase session)
2. `!appState.welcomeSeen` → `WelcomeView`
3. `appState.onboardingComplete` → `MainTabView` (also triggers `programService.loadAll()`)
4. otherwise → `NewOnboardingFlowView`

`AppState` (`Models.swift`) is an `@Observable` class — the only shared mutable state. Key fields:
- `welcomeSeen`, `onboardingComplete` — persisted to `UserDefaults` via `didSet`; `checkSession()` sets both to `true` when a valid Supabase session exists
- `isAuthenticated`, `sessionCheckComplete` — set by `checkSession()` on every cold launch
- `selectedDate` — drives the week strip and which workout is shown
- `showActiveWorkout: Bool` — triggers the `.fullScreenCover` for the active workout from `MainTabView`
- `remoteWorkout: WorkoutDay?` — set by `DashboardView.loadTodayExercises()`; takes priority in `todayWorkout`
- `todayWorkout: WorkoutDay?` — computed: returns `remoteWorkout` if set, otherwise falls back to hardcoded `WorkoutDay.weekSchedule`
- `workoutStore: WorkoutStore` — persists `[LoggedSetEntry]` to `UserDefaults` (key `workout_logged_sets_v1`)

### Supabase / live data (`ProgramService.swift`)

`ProgramService` is an `@Observable @MainActor` class injected at the root. It owns:
- `userProgram: RemoteUserProgram?` — the user's enrolled program and current week
- `templates: [RemoteWorkoutTemplate]` — all workout templates for that program
- `exerciseCache: [UUID: [RemoteWorkoutExercise]]` — in-memory cache keyed by template ID

**Bootstrap:** `loadAll()` is called from `ContentView` when `MainTabView` appears. It fetches programs, user program, and templates in parallel.

**Dashboard data flow:**
1. `DashboardView.loadTodayExercises()` calls `programService.todayTemplate(for: selectedDate)` to get today's template
2. Then `programService.exercises(for: template.id)` to get exercises (cached)
3. Maps `RemoteWorkoutExercise → Exercise` via `RemoteWorkoutExercise.toExercise()` in `RemoteModels.swift`
4. Sets `appState.remoteWorkout` so `todayWorkout` picks it up

`DashboardView` re-runs this whenever `selectedDate` or `programService.userProgram?.id` changes.

### Remote models (`RemoteModels.swift`)

Codable structs that mirror the Supabase schema. Key types:
- `RemoteWorkoutTemplate` — a single day's workout within a week (`dayOfWeek`, `weekNumber`)
- `RemoteWorkoutExercise` — join table row; embeds `RemoteExercise` via `select("*, exercise:exercises(*)")`
- `RemoteExercise.videoUrl` — HTTPS URL to Supabase Storage; nil if no video uploaded yet
- `RemoteWorkoutExercise.toExercise()` — only converts rows where `exerciseType == "exercise"` (skips warmups/cardio/cooldowns)

### Onboarding flow (`NewOnboardingFlowView.swift`)

`NewOnboardingFlowViewModel` (`@Observable`) drives all navigation via a `Phase` enum:

```
.questions(Int) → .goalSpeed → .sleep → .supplements
→ .questions(…) → .calculating → .plan → .socialProof
→ .signUp → .featureShowcase → .commit
```

- 26-step questionnaire defined in `newOnboardingSteps: [NewOnboardingStep]` (keyed by stable `id: Int`)
- Skips the World Class location step (id 13) when a different gym is chosen
- Inserts `.goalSpeed`, `.sleep`, `.supplements` custom screens at fixed branch points
- `isGoingBack` flips the slide transition direction
- `vm.selectedProgramId` computes the correct program UUID from the gender answer (step id 25) and is passed directly to `SignUpView(programId:)`
- `NewOnboardingFlow_CommitStepView` closes onboarding by setting `appState.onboardingComplete = true`

`OnboardingView.swift` is an older chat-bubble onboarding — **no longer used**.

### Auth (`SignUpView.swift`)

Apple Sign In and Google Sign In (native SDK, no browser popup) both flow into `supabase.auth.signInWithIdToken`. After success:
1. `appState.isAuthenticated = true`
2. `programService.assignProgram(programId:)` is called (upserts a `user_programs` row)
3. `onComplete()` advances the onboarding phase

`SignUpView` takes a `programId: UUID` parameter — wired from the onboarding VM's gender answer:
- Male: `a0000000-0000-0000-0000-000000000001`
- Female: `a0000000-0000-0000-0000-000000000002`

### Main app flow (`DashboardView.swift`)

`MainTabView` has four tabs; only "Workout" (`DashboardView`) is implemented. The others are `PlaceholderTabView`.

`MainTabView` hosts a `WorkoutAccessoryView` in `.tabViewBottomAccessory` (music-player mini-bar pattern) that collapses inline when scrolling.

Dashboard exercise tap flow:
1. Tap exercise row → sets `setupExercise`, shows `ExerciseSetupView` as a sheet
2. In `ExerciseSetupView`, tap "How-To" → `ExerciseDetailView` sheet (video + instructions)
3. Tap "Start Workout" → dismisses setup sheet, waits 350ms, sets `appState.showActiveWorkout = true`

The week strip uses hardcoded `WorkoutDay.weekSchedule` for the workout-day dots (not live data).

### Active workout flow (`WorkoutExecutionView.swift`)

`ActiveWorkoutView` is a full-screen cover presented from `MainTabView`. Key interactions:
- `xmark` button and floating stop button (red circle) both set `showFinishSheet = true`
- `WorkoutFinishOverlay` slides up: backdrop/X resumes; "Log Workout" → sets `showSummary = true`
- `WorkoutSummaryView` is a `.fullScreenCover` inside `ActiveWorkoutView`; its `onDone` dismisses the whole cover

### ExerciseSetupView dual modes

Controlled by which optional params are provided:
- **Setup mode** (`onStartWorkout` provided): warmup + working sets grid, "Start Workout" CTA
- **Active mode** (`workoutStore` provided): per-set logging, reps/weight fields, rest timer overlay, "Log Set" / "Log All Sets" CTA

### Video playback (`ExerciseDetailView.swift`)

`LoopingVideoPlayer` is a `UIViewRepresentable` wrapping `AVPlayer`. It loops via `AVPlayerItemDidPlayToEndTime`.

`Exercise.videoResource` holds either:
- A **local filename** (without extension) for bundled `.mov` files — load with `Bundle.videoURL(named:)` which handles Unicode NFC/NFD normalization for Icelandic filenames
- An **HTTPS URL string** for Supabase Storage videos — detected by the `https://` prefix

Always use `Bundle.videoURL(named:)` for local files, never `Bundle.main.url(forResource:withExtension:)`.

### In-app purchases (`StoreVM.swift` / `PaywallView.swift`)

`StoreVM` is an `@Observable @MainActor` class. Two auto-renewable subscriptions:

| Product ID | Plan |
|---|---|
| `themuscleclub.subscription.yearly` | Annual |
| `themuscleclub.subscription.weekly` | Weekly |

A background `Task` listens to `StoreKit.Transaction.updates` for the app's lifetime. `MuscleClubPaywallView` calls `storeVM.purchase(_:)`; completion is guarded by a `didComplete` flag to prevent double-firing from both the return value and `onChange(of: storeVM.hasActiveSubscription)`.

### Design system

iOS 26 app built entirely around **Liquid Glass**. Key patterns:

- `.glassEffect()` / `.glassEffect(.regular.tint(.appAccent))` — containers and cards
- `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)` — standard button styles
- `GlassEffectContainer(spacing:)` — required wrapper for morph/matchedGeometry between sibling glass elements
- `.glassEffectID(_:in:)` with a `@Namespace` — animated selected-day pill in the week strip
- `AppBackground` — reusable gradient view; use as the base `ZStack` layer in every screen

The app is dark-only (`.preferredColorScheme(.dark)` at root).

### Colors (`Models.swift`)

| Name | Value | Usage |
|---|---|---|
| `appAccent` | Crimson red | Primary interactive tint |
| `appGold` | Golden yellow | Section headers, focus labels |
| `appBg` | Dark purple-black | Background reference (use `AppBackground` instead) |

### Supabase project

- URL: `https://neomyrexkfgrsrcqvnsb.supabase.co`
- Client singleton: `supabase` in `SupabaseClient.swift`
- Storage bucket: `exercise-videos` — HTTPS URLs stored in `exercises.video_url`
