import SwiftUI
import AVFoundation

// MARK: - Explore Tab (Reels-style vertical video feed for exercises)

struct ExploreView: View {
    @Environment(ProgramService.self) private var programService
    @State private var exercises: [Exercise] = []
    @State private var isLoading = false
    @State private var visibleID: UUID?
    @State private var detailExercise: Exercise?

    var body: some View {
        NavigationStack {
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
            .sheet(item: $detailExercise) { ex in
                NavigationStack { ExerciseDetailView(exercise: ex) }
                    .presentationDragIndicator(.visible)
            }
            .task { await loadExercises() }
        }
    }

    // MARK: - Feed

    private var feedScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(exercises) { ex in
                    ExploreReelCard(
                        exercise: ex,
                        isPlaying: visibleID == ex.id,
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
            if visibleID == nil { visibleID = exercises.first?.id }
        }
    }

    // MARK: - Loading / Empty states

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
                        sets: 3,
                        reps: 10,
                        weight: 0,
                        weightUnit: "kg",
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

        // Fallback: sample data bundled in the app
        let sample = WorkoutDay.weekSchedule
            .compactMap { $0 }
            .flatMap { $0.exercises }
            .filter { $0.videoResource != nil }
        exercises = sample
        visibleID = sample.first?.id
    }
}

// MARK: - Reel Card

private struct ExploreReelCard: View {
    let exercise: Exercise
    let isPlaying: Bool
    let onInfo: () -> Void

    @State private var isMuted = true

    var body: some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                videoBackground
                LinearGradient(
                    colors: [.clear, .black.opacity(0.72)],
                    startPoint: UnitPoint(x: 0.5, y: 0.35),
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Video / fallback background

    @ViewBuilder
    private var videoBackground: some View {
        if let resource = exercise.videoResource,
           let url = resource.hasPrefix("https://")
               ? URL(string: resource)
               : Bundle.main.videoURL(named: resource) {
            LoopingVideoPlayer(url: url, isMuted: isMuted, isPlaying: isPlaying)
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
            ExploreActionButton(
                systemImage: "info.circle",
                tint: .white,
                action: onInfo
            )
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
