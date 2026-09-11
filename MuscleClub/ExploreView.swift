import SwiftUI
import AVFoundation
import Supabase

// MARK: - Explore Tab (Reels-style vertical video feed for exercises)

struct ExploreView: View {
    @Environment(ProgramService.self) private var programService
    @State private var exercises: [Exercise] = []
    @State private var isLoading = false
    @State private var visibleID: UUID?
    @State private var detailExercise: Exercise?
    @State private var currentFilter: String = "All"
    @State private var filterExpanded = false
    @State private var showBrowse = false
    @State private var isMuted = false
    @Namespace private var pillNamespace

    // Ordered, deduplicated muscle groups preserving first-seen order
    var muscleGroups: [String] {
        var seen = Set<String>()
        return exercises.compactMap { seen.insert($0.muscleGroup).inserted ? $0.muscleGroup : nil }
    }

    var filteredExercises: [Exercise] {
        currentFilter == "All" ? exercises : exercises.filter { $0.muscleGroup == currentFilter }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading && exercises.isEmpty {
                loadingView
            } else if exercises.isEmpty {
                emptyView
            } else {
                feedScrollView
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { exploreHeader }
        // Vertical icon badge sidebar — commented out in favour of the title carousel
        // .overlay(alignment: .topTrailing) {
        //     if !exercises.isEmpty {
        //         filterPillRow
        //             .padding(.top, 130)
        //             .padding(.trailing, 12)
        //     }
        // }
        .sheet(item: $detailExercise) { ex in
            NavigationStack { ExerciseDetailView(exercise: ex) }
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBrowse) {
            ExploreGroupSheet(
                exercises: exercises,
                muscleGroups: muscleGroups,
                onSelectExercise: { ex in
                    showBrowse = false
                    currentFilter = ex.muscleGroup
                    Task {
                        try? await Task.sleep(nanoseconds: 250_000_000)
                        withAnimation { visibleID = ex.id }
                    }
                },
                onSelectGroup: { group in
                    showBrowse = false
                    applyFilter(group)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
        }
        .task { await loadExercises() }
    }

    // MARK: - Floating header (tap title to expand/collapse filter carousel)

    private var exploreHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                // Tappable title card — acts as the filter toggle
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                        filterExpanded.toggle()
                    }
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Explore")
                                .font(.system(size: 26, weight: .heavy))
                                .foregroundStyle(.white)
                            Text(currentFilter == "All" ? "Technique Library" : currentFilter)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(
                                    currentFilter == "All"
                                        ? AnyShapeStyle(Color.white.opacity(0.65))
                                        : AnyShapeStyle(Color.appAccent)
                                )
                                .contentTransition(.numericText())
                        }
                        Image(systemName: filterExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.top, 6)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Button { showBrowse = true } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            // Expanding filter carousel
            if filterExpanded && !exercises.isEmpty {
                filterCarousel
                    .padding(.top, 12)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.95, anchor: .top).combined(with: .opacity),
                            removal:   .scale(scale: 0.95, anchor: .top).combined(with: .opacity)
                        )
                    )
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 16)
        .background {
            LinearGradient(
                colors: [.black.opacity(0.65), .black.opacity(0.2), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        }
        // Auto-collapse when the user scrolls to a new card
        .onChange(of: visibleID) {
            if filterExpanded {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    filterExpanded = false
                }
            }
        }
    }

    // Horizontal chip carousel shown when header is expanded
    private var filterCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(["All"] + muscleGroups, id: \.self) { group in
                        let selected = group == currentFilter
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                filterExpanded = false
                            }
                            applyFilter(group)
                        } label: {
                            Text(group)
                                .font(.subheadline.weight(selected ? .bold : .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(
                            selected ? .regular.tint(.appAccent).interactive() : .regular.interactive(),
                            in: .capsule
                        )
                        .glassEffectID(selected ? "carousel-sel" : nil, in: pillNamespace)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Vertical icon badge sidebar (commented out — replaced by title carousel)
    /*
    private var filterPillRow: some View {
        ScrollView(.vertical, showsIndicators: false) {
            GlassEffectContainer(spacing: 10) {
                VStack(spacing: 10) {
                    ForEach(["All"] + muscleGroups, id: \.self) { group in
                        filterBadge(group: group)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxHeight: 420)
    }

    private func filterBadge(group: String) -> some View {
        let selected = group == currentFilter
        return Button { applyFilter(group) } label: {
            Image(systemName: badgeIcon(for: group))
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(selected ? Color.appAccent : Color.white)
                .frame(width: 52, height: 52)
        }
        .buttonStyle(.plain)
        .glassEffect(
            selected ? .regular.tint(.appAccent).interactive() : .regular.interactive(),
            in: .rect(cornerRadius: 16)
        )
        .glassEffectID(selected ? "badge-sel" : nil, in: pillNamespace)
    }

    private func badgeIcon(for group: String) -> String {
        switch group.lowercased() {
        case "all":                         return "square.grid.2x2.fill"
        case "chest":                       return "figure.arms.open"
        case "back":                        return "figure.strengthtraining.traditional"
        case "legs", "quads", "quadriceps": return "figure.run"
        case "hamstrings":                  return "figure.walk"
        case "shoulders":                   return "figure.mixed.cardio"
        case "biceps", "arms":              return "dumbbell.fill"
        case "triceps":                     return "figure.strengthtraining.functional"
        case "core", "abs":                 return "bolt.fill"
        case "glutes":                      return "figure.strengthtraining.traditional"
        case "calves":                      return "figure.walk"
        case "rear delt", "rear deltoids":  return "figure.arms.open"
        default:                            return "dumbbell.fill"
        }
    }
    */

    // MARK: - Feed

    private var feedScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(filteredExercises) { ex in
                    ExploreReelCard(
                        exercise: ex,
                        isPlaying: visibleID == ex.id,
                        isMuted: $isMuted,
                        onInfo: { detailExercise = ex }
                    )
                    .containerRelativeFrame([.horizontal, .vertical])
                    .id(ex.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $visibleID)
        .ignoresSafeArea(edges: [.top, .bottom])
        .onAppear {
            if visibleID == nil { visibleID = filteredExercises.first?.id }
        }
    }

    // MARK: - Loading / Empty

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView().tint(.white)
            Text("Loading…")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "video.slash")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.white.opacity(0.5))
            Text("No exercise videos yet")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text("Exercise tutorials will appear here once available.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func applyFilter(_ group: String) {
        // Stop any playing video before swapping the feed
        visibleID = nil
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            currentFilter = group
        }
        let first = (group == "All" ? exercises : exercises.filter { $0.muscleGroup == group }).first
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            withAnimation { visibleID = first?.id }
        }
    }

    // MARK: - Data loading

    private func loadExercises() async {
        guard exercises.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let remoteAll: [RemoteExercise] = try await supabase
                .from("exercises")
                .select()
                .execute()
                .value

            let withVideos = remoteAll
                .filter { $0.videoUrl != nil && $0.isExercise }
                .map { remote in
                    Exercise(
                        name: remote.nameEn,
                        sets: 3, reps: 10,
                        weight: 0, weightUnit: "kg",
                        muscleGroup: remote.muscleGroup,
                        isFocus: false,
                        sfSymbol: remote.sfSymbol,
                        instructionSteps: remote.instructions,
                        videoResource: remote.videoUrl
                    )
                }

            if !withVideos.isEmpty {
                exercises = withVideos
                visibleID = withVideos.first?.id
                return
            }
        } catch {}

        // Fallback: bundled sample data
        let sample = WorkoutDay.weekSchedule
            .compactMap { $0 }
            .flatMap { $0.exercises }
            .filter { $0.videoResource != nil }
        exercises = sample
        visibleID = sample.first?.id
    }
}

// MARK: - Browse / Search Sheet

private struct ExploreGroupSheet: View {
    let exercises: [Exercise]
    let muscleGroups: [String]
    let onSelectExercise: (Exercise) -> Void
    let onSelectGroup: (String) -> Void

    @State private var searchQuery = ""

    private var searchResults: [Exercise] {
        guard !searchQuery.isEmpty else { return [] }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if searchQuery.isEmpty {
                    groupList
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search exercises…"
            )
            .scrollContentBackground(.hidden)
            .background(.clear)
        }
    }

    // MARK: - Group playlist cards

    private var groupList: some View {
        List {
            Section {
                groupRowButton(
                    name: "All Exercises",
                    count: exercises.count,
                    symbol: "play.square.stack.fill",
                    tint: .appAccent
                ) { onSelectGroup("All") }
            }
            .listRowBackground(Color.clear)

            Section("By muscle group") {
                ForEach(muscleGroups, id: \.self) { group in
                    let groupExercises = exercises.filter { $0.muscleGroup == group }
                    groupRowButton(
                        name: group,
                        count: groupExercises.count,
                        symbol: groupExercises.first?.sfSymbol ?? "dumbbell.fill",
                        tint: .appAccent
                    ) { onSelectGroup(group) }
                }
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.insetGrouped)
    }

    private func groupRowButton(
        name: String,
        count: Int,
        symbol: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .glassEffect(.regular.tint(tint), in: .rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("\(count) exercise\(count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search results

    private var searchResultsList: some View {
        List(searchResults) { ex in
            Button { onSelectExercise(ex) } label: {
                HStack(spacing: 14) {
                    Image(systemName: ex.sfSymbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.tint(.appAccent), in: .rect(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(ex.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(ex.muscleGroup)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if ex.videoResource != nil {
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(Color.appAccent)
                            .font(.system(size: 20))
                    }
                }
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .overlay {
            if searchResults.isEmpty {
                ContentUnavailableView.search(text: searchQuery)
            }
        }
    }
}

// MARK: - Reel Card

private struct ExploreReelCard: View {
    let exercise: Exercise
    let isPlaying: Bool
    @Binding var isMuted: Bool
    let onInfo: () -> Void

    @State private var isPaused = false

    private var effectivelyPlaying: Bool { isPlaying && !isPaused }

    var body: some View {
        ZStack {
            // Tappable video background — tap anywhere to pause/resume
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPaused.toggle()
                }
            } label: {
                ZStack {
                    videoBackground
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.72)],
                        startPoint: UnitPoint(x: 0.5, y: 0.35),
                        endPoint: .bottom
                    )
                    if isPaused {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(.white.opacity(0.88))
                            .shadow(color: .black.opacity(0.4), radius: 12)
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .ignoresSafeArea()

            // Info overlay — buttons have independent hit testing
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(alignment: .bottom, spacing: 12) {
                    exerciseInfo
                        .frame(maxWidth: .infinity, alignment: .leading)
                    actionRail
                        .frame(width: 54)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 116)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // When this card loses focus (filter switch or scroll away), reset pause state
        // so the video is ready to play cleanly if the card becomes visible again.
        .onChange(of: isPlaying) { _, playing in
            if !playing { isPaused = false }
        }
    }

    // MARK: - Video / fallback background

    @ViewBuilder
    private var videoBackground: some View {
        if let resource = exercise.videoResource,
           let url = resource.hasPrefix("https://")
               ? URL(string: resource)
               : Bundle.main.videoURL(named: resource) {
            LoopingVideoPlayer(url: url, isMuted: isMuted, isPlaying: effectivelyPlaying)
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color.appAccent.opacity(0.35), Color.black.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: exercise.sfSymbol)
                    .font(.system(size: 100, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.12))
            }
        }
    }

    // MARK: - Exercise info (bottom-left)

    private var exerciseInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(exercise.muscleGroup.uppercased())
                .font(.caption2.weight(.heavy))
                .foregroundStyle(.white.opacity(0.9))
                .tracking(1.2)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .glassEffect(.regular.tint(.appAccent), in: .rect(cornerRadius: 10))

            Text(exercise.name)
                .font(.title2.weight(.heavy))
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("\(exercise.sets) sets · \(exercise.reps) reps")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .glassEffect(in: .rect(cornerRadius: 14))
        }
    }

    // MARK: - Action rail (bottom-right)

    private var actionRail: some View {
        VStack(spacing: 20) {
            ExploreActionButton(systemImage: "info.circle", tint: .white, action: onInfo)
            ExploreActionButton(
                systemImage: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                tint: isMuted ? .white.opacity(0.55) : .white,
                action: { isMuted.toggle() }
            )
        }
    }
}

// MARK: - Action button

private struct ExploreActionButton: View {
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
                .glassEffect(.regular, in: .circle)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ExploreView()
        .environment(ProgramService())
        .environment(AppState())
        .preferredColorScheme(.dark)
}
