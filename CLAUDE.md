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

`ContentView.swift` is the entry point (`@main MyApp`). It creates four root-level singletons injected via `.environment()`: `AppState`, `StoreVM`, `ProgramService`, and `StreakService`.

**Debug flags at top of `ContentView.swift`** — set back to `false` before shipping:
```swift
private let debugShowRankView    = false
private let debugShowPaywall     = false
private let debugShowDashboard   = false  // ← flip to false before shipping
private let debugResetOnboarding = false  // sign out + clear flags at launch to test onboarding
```
⚠️ The three `debugShow*` flags are plain constants, **not** `#if DEBUG`-gated — a `true` value ships in Release. `debugResetOnboarding` is safe: its call site is wrapped in `#if DEBUG`, so Release ignores it. When it's on, every Debug launch signs out of Supabase and clears `welcomeSeen`/`onboardingComplete` before `checkSession()` runs, landing on `WelcomeView` for a full onboarding run.
When `debugShowDashboard` is true, `RootView` skips all gates and shows `MainTabView` directly, using `programService.loadForDebug()` (hardcoded male program UUID). The `if/else` chain checks Dashboard → Paywall → RankView, so `debugShowDashboard = true` masks the other two flags.

The debug path also seeds mock TargetView data: `loadForDebug()` fakes `currentWeek = 5` (clamped to the max seeded week so `todayTemplate()` still resolves), and `RootView` calls `streakService.loadMockData(workoutDayNames:)` (`#if DEBUG`-gated) to fake 14 logged workouts on the program's real workout days. There's no auth session in this path, so `loadStreak()` returns early and never overwrites the mock. `loadMockData` sets `currentStreak` directly instead of via `recompute()` to avoid persisting the fake streak into the real longest-streak UserDefaults value.

`RootView` normal gate (when debug flags are all false):
1. `!appState.sessionCheckComplete` → blank `AppBackground()` (splash while checking Supabase session)
2. `!appState.welcomeSeen` → `WelcomeView`
3. `appState.onboardingComplete` → `MainTabView` (triggers `programService.loadAll()`)
4. otherwise → `NewOnboardingFlowView`

`AppState` (`Models.swift`) is an `@Observable` class — the only shared mutable state. Key fields:
- `welcomeSeen`, `onboardingComplete` — persisted to `UserDefaults` via `didSet`; `checkSession()` sets both to `true` when a valid Supabase session exists
- `isAuthenticated`, `sessionCheckComplete` — set by `checkSession()` on every cold launch
- `selectedDate` — drives the week strip and which workout is shown
- `showActiveWorkout: Bool` — triggers the `.fullScreenCover` for the active workout from `MainTabView`
- `remoteWorkout: WorkoutDay?` — set by `DashboardView.loadTodayExercises()`; takes priority in `todayWorkout`
- `todayWorkout: WorkoutDay?` — computed: returns `remoteWorkout` if set, otherwise falls back to hardcoded `WorkoutDay.weekSchedule`
- `workoutStore: WorkoutStore` — persists `[LoggedSetEntry]` to `UserDefaults` (key `workout_logged_sets_v1`)
- `weekTemplateRemap: [String: UUID]` — session-only map of `dayOfWeek → overriding templateId`; cleared when program or week changes; lets the user swap today's workout without a Supabase write

### Supabase / live data (`ProgramService.swift`)

`ProgramService` is an `@Observable @MainActor` class injected at the root. It owns:
- `programs: [RemoteProgram]`
- `userProgram: RemoteUserProgram?` — the user's enrolled program and current week
- `templates: [RemoteWorkoutTemplate]` — all workout templates for that program
- `milestones: [RemoteMilestone]` — program milestones for the Target tab
- `exerciseCache: [UUID: [RemoteWorkoutExercise]]` — in-memory cache keyed by template ID

**Bootstrap:** `loadAll()` fetches programs, user program, templates, and milestones in parallel. `loadForDebug()` is the equivalent for the debug flag path.

**Dashboard data flow:**
1. `DashboardView.loadTodayExercises()` checks `appState.weekTemplateRemap` first, then falls back to `programService.todayTemplate(for: selectedDate)`
2. Calls `programService.exercises(for: template.id)` (cached)
3. Maps `RemoteWorkoutExercise → Exercise` via `RemoteWorkoutExercise.toExercise()` in `RemoteModels.swift`
4. Sets `appState.remoteWorkout`

`DashboardView` re-runs `loadTodayExercises()` whenever `selectedDate`, `programService.userProgram?.id`, or `appState.weekTemplateRemap` changes.

### Remote models (`RemoteModels.swift`)

Codable structs that mirror the Supabase schema. Key types:
- `RemoteWorkoutTemplate` — a single day's workout within a week (`dayOfWeek`, `weekNumber`)
- `RemoteWorkoutExercise` — join table row; embeds `RemoteExercise` via `select("*, exercise:exercises(*)")`
- `RemoteExercise.videoUrl` — HTTPS URL to Supabase Storage; nil if no video uploaded yet
- `RemoteWorkoutExercise.toExercise()` — only converts rows where `exerciseType == "exercise"` (skips warmups/cardio/cooldowns)

### Streak tracking (`StreakService.swift`)

`StreakService` is an `@Observable @MainActor` class. It reads the `workout_logs` Supabase table (keyed by `user_id, logged_date`) and computes:
- `currentStreak: Int` — consecutive scheduled workout days that were logged, walking backwards from today. Rest days are transparent (don't break or count). Today's workout day doesn't break the streak if not yet logged.
- `longestStreak: Int` — persisted to `UserDefaults`
- `totalWorkouts: Int` — count of distinct logged dates (used by `TargetView` for milestone status)

`workoutDayNames: Set<String>` is set by `DashboardView` from `programService.templates`; falls back to `["monday","tuesday","wednesday","friday"]` if templates haven't loaded.

`logWorkout(workoutName:durationSeconds:volumeKg:calories:)` does an optimistic local update before upserting to `workout_logs`.

### Onboarding flow (`NewOnboardingFlowView.swift`)

`NewOnboardingFlowViewModel` (`@Observable`) drives all navigation via a `Phase` enum:

```
.questions(Int) → .goalSpeed → .sleep → .supplements
→ .questions(…) → .calculating → .plan → .socialProof
→ .signUp → .featureShowcase → .commit
```

- 26-step questionnaire defined in `newOnboardingSteps: [NewOnboardingStep]` (keyed by stable `id: Int`)
- `isGoingBack` flips the slide transition direction
- `vm.selectedProgramId` computes the correct program UUID from the gender answer (step id 25) and is passed directly to `SignUpView(programId:)`
- `NewOnboardingFlow_CommitStepView` closes onboarding by setting `appState.onboardingComplete = true`

**Dead code (compiles but unreferenced):** `OnboardingView.swift` is an older chat-bubble onboarding, fully unused. `FullScreenVideoView.swift` is also dead — its only call site in `ExerciseDetailView.swift` is commented out (tap now pauses/resumes inline).

### Auth (`SignUpView.swift`)

Apple Sign In and Google Sign In (native SDK, no browser popup) both flow into `supabase.auth.signInWithIdToken`. After success:
1. `appState.isAuthenticated = true`
2. `programService.assignProgram(programId:)` is called (upserts a `user_programs` row)
3. `onComplete()` advances the onboarding phase

`SignUpView` takes a `programId: UUID` parameter — wired from the onboarding VM's gender answer:
- Male: `a0000000-0000-0000-0000-000000000001`
- Female: `a0000000-0000-0000-0000-000000000002`

**Returning users — `LoginView.swift`:** presented as a sheet from `WelcomeView` ("Already have an account?"). Same two providers, but `finishLogin()` deliberately does **not** assign a program — it runs `programService.loadAll()` and only sets `onboardingComplete = true` if `userProgram != nil`, so a sign-in without an existing account falls through to onboarding instead of an empty dashboard. It has its own local `googleiOSClientID` constant (duplicated from `SignUpView`).

**Account — `AccountView.swift`:** pushed via `.navigationDestination` from `DashboardView`'s top-leading toolbar button. Name comes from `userMetadata["full_name"]` (Google) then `["name"]` (Apple). `logOut()` resets `isAuthenticated`, `onboardingComplete`, **and** `welcomeSeen`, sending the user back to `WelcomeView`. "Delete Account" calls the `delete_account` Supabase RPC (a `SECURITY DEFINER` function defined in `/Users/gisliprufugaur/Developer/MuscleClub/delete_account.sql` — must be run in the Supabase SQL editor) which deletes the caller's `workout_logs`/`logged_sets`/`user_programs` rows and their `auth.users` row, then signs out locally. If the RPC fails, an error alert is shown and local state is left intact.

### Main app flow (`DashboardView.swift`)

`MainTabView` has four tabs: Workout (`DashboardView`), Rank (`RankView`), Targets (`TargetView`), Explore (`ExploreView`).

`MainTabView` hosts a `WorkoutAccessoryView` in `.tabViewBottomAccessory` (music-player mini-bar pattern) that collapses inline when scrolling.

**Week strip** — shows the current month broken into ISO weeks, snapping week-by-week with `.scrollTargetBehavior(.viewAligned)`. Workout-day dots are derived live from `programService.templates.map { $0.dayOfWeek }` — no hardcoded schedule. The selected day gets a Liquid Glass pill animated with `.glassEffectID("daysel", in: dayNamespace)`.

Dashboard exercise tap flow:
1. Tap exercise row → sets `setupExercise`, shows `ExerciseSetupView` as a sheet
2. In `ExerciseSetupView`, tap "How-To" → `ExerciseDetailView` sheet (video + instructions)
3. Tap "Start Workout" → dismisses setup sheet, waits 350ms, sets `appState.showActiveWorkout = true`

**Switch sheet** — `SwitchSheetView` lets the user swap today's workout template. It writes to `appState.weekTemplateRemap`, which triggers `loadTodayExercises()` to reload.

**Add exercise — `AddExerciseView.swift`** — multi-select exercise picker sheet, used from both `DashboardView` (appends to local `userAddedExercises`) and `SwitchSheetView`'s custom-workout builder. Communicates only via an `onAdd: ([Exercise]) -> Void` callback — nothing is persisted to Supabase. It fetches the `exercises` table directly (bypassing `ProgramService`, no cache) and maps picks to `Exercise` with hardcoded defaults (3×10 @ 0 kg, no video/instructions). The "By Muscle" tab classifies via hardcoded string sets — new `muscle_group` values silently land in "Other". Also defines the reusable `ExerciseThumbnailView` (still-frame from remote video via `AVAssetImageGenerator`, SF Symbol fallback).

### Active workout flow (`WorkoutExecutionView.swift`)

`ActiveWorkoutView` is a full-screen cover presented from `MainTabView`. Key interactions:
- `xmark` button and floating stop button both set `showFinishSheet = true`
- `WorkoutFinishOverlay` (defined in `WorkoutFinishView.swift` — name ≠ filename) slides up: backdrop/X resumes; "Log Workout" → sets `showSummary = true`
- `WorkoutSummaryView` is a `.fullScreenCover` inside `ActiveWorkoutView`; its `onDone` dismisses the whole cover

**The Supabase workout log write happens in `WorkoutSummaryView`'s `.task`** — it calls `streakService.logWorkout(...)`, so logging is coupled to that screen appearing. The summary's header share button opens `WorkoutShareView` (full-screen, two card styles; only the "More" `ShareLink` works — it shares plain text, and the Instagram button is a no-op) and its `···` opens `WorkoutOptionsSheet` (only "Resume" and "Delete" are wired; "Save" and "Edit duration" are no-op closures). The confetti on the summary is the hand-rolled `ConfettiView`, not the `confetti(2).lottie` file.

The `volume × 0.11` calorie heuristic is duplicated in `WorkoutFinishView`, `WorkoutSummaryView`, and `WorkoutShareView` — change all three together. The "Apple Health" toggle in `WorkoutFinishOverlay` writes to a `@State` that's never read; HealthKit isn't linked yet (see the TODO block at the top of `WorkoutFinishView.swift`).

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

### Target tab & milestone system (`TargetView.swift`)

`TargetView` is fully wired to live data via `@Environment`. It derives:
- `workoutCount` / `currentStreak` from `StreakService`
- `currentWeek` / `totalWeeks` / `programName` / milestone list from `ProgramService`
- `overallProgress = (currentWeek - 1) / totalWeeks`
- Milestone `.status` by comparing `workoutCount` against each `RemoteMilestone.workoutThreshold`

**Supabase table: `program_milestones`**

| Column | Type | Notes |
|---|---|---|
| `id` | UUID | PK |
| `program_id` | UUID | FK → `programs.id` |
| `sort_order` | INT | Display order (1-based) |
| `title` | TEXT | e.g. "Build the Habit" |
| `subtitle` | TEXT | e.g. "Weeks 3–4" |
| `sf_symbol` | TEXT | SF Symbol name, e.g. "flame.fill" |
| `detail` | TEXT | One-line description shown in the card |
| `workout_threshold` | INT | Logged workouts required to complete this milestone |

**Adding a new program — checklist:**

1. **Supabase `programs` table** — INSERT row with UUID, `name`, `name_is`, `gender`, `days_per_week`
2. **Supabase `workout_templates`** — INSERT weekly templates (`week_number`, `day_of_week`, `sort_order`) for the new `program_id`
3. **Supabase `workout_exercises`** — INSERT exercises per template, referencing `exercises` table rows
4. **Supabase `program_milestones`** — INSERT milestone rows with `workout_threshold` values and SF Symbols
5. **`NewOnboardingFlowView.swift` → `selectedProgramId`** — extend the computed property to return the new UUID based on onboarding answers (currently branches only on gender via step id 25)

No Swift model changes required — `RemoteMilestone` and `ProgramService` handle any program generically.

**Current programs:**

| UUID | Gender | Name |
|---|---|---|
| `a0000000-0000-0000-0000-000000000001` | Male | Build Muscle (Male) |
| `a0000000-0000-0000-0000-000000000002` | Female | Build Muscle (Female) |

Program assignment is currently gender-only (onboarding step id 25). When adding goal-type programs (e.g. "Get Lean", "Powerlifting"), also store the fitness goal answer from step id 0 and combine it with gender in `selectedProgramId`.

### Rank tab (`RankView.swift`)

Leaderboard with an animated podium. Data comes from a Supabase **RPC `get_leaderboard`** (server-side function — the only `.rpc()` call in the app), decoded into a file-private `LeaderboardRow`.

⚠️ **`load()` is `#if DEBUG`-gated: Debug builds never hit Supabase** — they use the hardcoded `mockEntries` with `currentUserId = "uid-me"`. Verify leaderboard changes in a Release build or by temporarily flipping the `#if`. Avatars are local asset images picked by hashing the user id (plus a hardcoded `avatarOverrides` map) — there is no remote avatar storage.

### Explore tab (`ExploreView.swift`)

Reels-style vertical video feed. `visibleID` (via `.scrollPosition`) is the single source of truth for which video plays; mute is a shared binding across cards. It loads all `exercises` rows directly from Supabase (bypassing `ProgramService`), filters to rows with a `videoUrl`, and **falls back to bundled `WorkoutDay.weekSchedule` sample videos if the query fails or returns nothing**. Loads once per view lifetime. The only screen that uses a black base instead of `AppBackground`.

### In-app purchases (`StoreVM.swift` / `PaywallView.swift`)

`StoreVM` is an `@Observable @MainActor` class. Two auto-renewable subscriptions:

| Product ID | Plan |
|---|---|
| `themuscleclub.subscription.yearly` | Annual |
| `themuscleclub.subscription.weekly` | Weekly |

A background `Task` listens to `StoreKit.Transaction.updates` for the app's lifetime. `MuscleClubPaywallView` calls `storeVM.purchase(_:)`; completion is guarded by a `didComplete` flag to prevent double-firing from both the return value and `onChange(of: storeVM.hasActiveSubscription)`.

### Design system

iOS 26 app built around **Liquid Glass**. Key patterns:

- `.glassEffect()` / `.glassEffect(.regular.tint(.appAccent))` — containers and cards
- `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)` — standard button styles
- `GlassEffectContainer(spacing:)` — required wrapper for morph/matchedGeometry between sibling glass elements
- `.glassEffectID(_:in:)` with a `@Namespace` — animated selected-day pill in the week strip
- `AppBackground` — `MeshGradient` view; use as the base `ZStack` layer in every screen. Has both dark and light mode variants — do not force dark-only at the root.

**Lottie animations** — via the DotLottie SPM package. `DotLottieAnimation` must be a `@StateObject`, so every animated element is factored into its own small wrapper struct (`AnimatedFlame`, `StreakBadgeView`, etc.) — follow that pattern for new animations. The `.lottie` files live loose in `MuscleClub/MuscleClub/` and the `fileName:` strings include the `(1)`/`(2)` download suffixes. `Flame animation.lottie` is shared by `RankView`, `DashboardView`, and `WorkoutSummaryView`; the rest are onboarding-only.

### Colors (`Models.swift`)

| Name | Value | Usage |
|---|---|---|
| `appAccent` | `Color.mint` | Primary interactive tint, buttons, highlights |
| `appGold` | `Color.mint` | Section headers, focus labels (currently same as accent) |
| `appBg` | Dark/light adaptive | Background reference (use `AppBackground` instead) |

### Supabase project

- URL: `https://neomyrexkfgrsrcqvnsb.supabase.co`
- Client singleton: `supabase` in `SupabaseClient.swift`
- Storage bucket: `exercise-videos` — HTTPS URLs stored in `exercises.video_url`
- Video URL pattern: `https://neomyrexkfgrsrcqvnsb.supabase.co/storage/v1/object/public/exercise-videos/{Folder}/{filename}.mov` (folder names are case-sensitive; spaces encoded as `%20`)
- Schema/seed SQL lives one directory up from the repo: `/Users/gisliprufugaur/Developer/MuscleClub/supabase_migration.sql`, `video_url_updates.sql`, `delete_account.sql`, `profiles.sql`
- ⚠️ `workout_logs.user_id` is **`text`**, not `uuid` (unlike every other user_id column) — any SQL comparing it to `auth.uid()` needs a `::text` cast. This has already caused one runtime-only bug in `delete_account()`.
- `public.profiles` — one row per user, populated from onboarding answers by `SignUpView.saveProfile()` at sign-up (columns mirror `ProfileUpsert` in `NewOnboardingFlowView.swift`). RLS owner-only. Skipped-sign-up and `LoginView` users don't get/update rows.

### Known pre-ship content gap

5 shoulder exercises have no `video_url` in Supabase because the `Axlir` folder was uploaded before the English renaming session (still has Icelandic filenames with spaces): Dumbbell Lateral Raise, Standing Barbell Shoulder Press, Seated Dumbbell Shoulder Press, Dumbbell Front Raise, Standing Dumbbell Shoulder Press. Fix: re-upload with English snake_case filenames and run the pending UPDATE statements in `/Users/gisliprufugaur/Developer/MuscleClub/video_url_updates.sql`.
