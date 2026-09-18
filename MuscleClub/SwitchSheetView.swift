import SwiftUI

struct SwitchSheetView: View {
    @Environment(AppState.self) private var appState
    @Environment(ProgramService.self) private var programService
    @Environment(\.dismiss) private var dismiss

    private let cal = Calendar.current
    @State private var navigateToMuscleGroups = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(alignment: .leading, spacing: 0) {
                    header
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 28) {
                            trainingSection
                            otherOptionsSection
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 48)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $navigateToMuscleGroups) {
                MuscleGroupPickerView(onDone: { dismiss() })
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Spacer()
            Text("Switch Workout")
                .font(.system(size: 18, weight: .semibold))
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
            }
            .buttonStyle(.glassProminent)
            .tint(.appAccent)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Data helpers

    private var weekTemplates: [RemoteWorkoutTemplate] {
        let week = programService.userProgram?.currentWeek ?? 1
        return programService.templates
            .filter { $0.weekNumber == week }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var selectedTemplateId: UUID? {
        let weekday = cal.component(.weekday, from: appState.selectedDate)
        let dayName = weekdayName(from: weekday)
        let week = programService.userProgram?.currentWeek ?? 1
        return programService.templates.first { $0.dayOfWeek == dayName && $0.weekNumber == week }?.id
    }

    // MARK: - Training section

    private var trainingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Within Training Split")
            if programService.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 24)
            } else if weekTemplates.isEmpty {
                Text("No workouts scheduled for this week.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(weekTemplates) { template in
                        templateRow(template)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func templateRow(_ template: RemoteWorkoutTemplate) -> some View {
        let selected = selectedTemplateId == template.id
        return Button { switchTo(template) } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(
                            selected ? Color.appAccent : Color.secondary.opacity(0.4),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)
                    if selected {
                        Circle()
                            .fill(Color.appAccent)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(template.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(selected ? .appAccent : .primary)
                    Text(template.dayOfWeek.capitalized)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: muscleSymbol(for: template))
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(selected ? 0.40 : 0.15))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .glassEffect(
                selected ? .regular.tint(.appAccent) : .regular,
                in: .rect(cornerRadius: 16)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: selected)
    }

    // MARK: - Other Options

    private var otherOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Other Options")
            VStack(spacing: 8) {
                otherOptionRow(icon: "scope",         label: "Pick muscle groups")  { navigateToMuscleGroups = true }
                otherOptionRow(icon: "bookmark.fill", label: "View saved workouts") { }
                otherOptionRow(icon: "pencil",        label: "Create a workout from scratch") { }
            }
            .padding(.horizontal, 20)
        }
    }

    private func otherOptionRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button { action() } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 28)
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .glassEffect(in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section label

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.6)
            .padding(.horizontal, 20)
    }

    // MARK: - Switching logic

    private func switchTo(_ template: RemoteWorkoutTemplate) {
        let target = weekdayInt(for: template.dayOfWeek)
        let today = Date()
        for offset in 0...6 {
            guard let d = cal.date(byAdding: .day, value: offset, to: today) else { continue }
            if cal.component(.weekday, from: d) == target {
                withAnimation(.spring(response: 0.4)) {
                    appState.selectedDate = d
                }
                break
            }
        }
        dismiss()
    }

    private func weekdayName(from weekday: Int) -> String {
        switch weekday {
        case 1: return "sunday"
        case 2: return "monday"
        case 3: return "tuesday"
        case 4: return "wednesday"
        case 5: return "thursday"
        case 6: return "friday"
        case 7: return "saturday"
        default: return "monday"
        }
    }

    private func weekdayInt(for name: String) -> Int {
        switch name.lowercased() {
        case "sunday":    return 1
        case "monday":    return 2
        case "tuesday":   return 3
        case "wednesday": return 4
        case "thursday":  return 5
        case "friday":    return 6
        case "saturday":  return 7
        default:          return 2
        }
    }

    private func muscleSymbol(for template: RemoteWorkoutTemplate) -> String {
        let n = template.name.lowercased()
        if n.contains("push") || n.contains("chest") || n.contains("shoulder") || n.contains("press") {
            return "figure.strengthtraining.functional"
        } else if n.contains("pull") || n.contains("back") || n.contains("row") {
            return "figure.arms.open"
        } else if n.contains("leg") || n.contains("squat") || n.contains("lower") {
            return "figure.run"
        } else if n.contains("arm") || n.contains("bicep") || n.contains("tricep") {
            return "figure.strengthtraining.traditional"
        } else if n.contains("full") || n.contains("cardio") || n.contains("hiit") {
            return "figure.mixed.cardio"
        }
        return "figure.mixed.cardio"
    }
}

// MARK: - Muscle Group Picker

struct MuscleGroupPickerView: View {
    @Environment(AppState.self) private var appState
    @Environment(ProgramService.self) private var programService

    let onDone: () -> Void

    @State private var allExercises: [Exercise] = []
    @State private var selectedGroups: Set<String> = []
    @State private var selectedIds: Set<UUID> = []
    @State private var isLoading = false

    private var muscleGroups: [String] {
        Array(Set(allExercises.map(\.muscleGroup))).sorted()
    }

    private var filteredExercises: [Exercise] {
        guard !selectedGroups.isEmpty else { return allExercises }
        return allExercises.filter { selectedGroups.contains($0.muscleGroup) }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            VStack(spacing: 0) {
                chipRow
                    .padding(.vertical, 12)

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if allExercises.isEmpty {
                    emptyState
                } else {
                    exerciseList
                }
            }

            if !selectedIds.isEmpty {
                confirmButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Pick Muscle Groups")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .animation(.spring(response: 0.3), value: selectedIds.isEmpty)
        .task { await loadAllExercises() }
    }

    // MARK: - Chip row

    private var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(muscleGroups, id: \.self) { group in
                    let on = selectedGroups.contains(group)
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            if on { selectedGroups.remove(group) }
                            else  { selectedGroups.insert(group) }
                        }
                    } label: {
                        Text(group)
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .glassEffect(
                                on ? .regular.tint(.appAccent) : .regular,
                                in: .capsule
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Exercise list

    private var exerciseList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ForEach(filteredExercises) { ex in
                    exerciseRow(ex)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)
            .padding(.bottom, selectedIds.isEmpty ? 24 : 100)
        }
    }

    private func exerciseRow(_ ex: Exercise) -> some View {
        let on = selectedIds.contains(ex.id)
        return Button {
            withAnimation(.spring(response: 0.25)) {
                if on { selectedIds.remove(ex.id) }
                else  { selectedIds.insert(ex.id) }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    ExerciseThumbnailView(
                        videoUrl: ex.videoResource,
                        fallbackSymbol: ex.sfSymbol,
                        size: 52,
                        cornerRadius: 12
                    )
                    if on {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appAccent.opacity(0.55))
                            .frame(width: 52, height: 52)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(ex.muscleGroup.uppercased())
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.appAccent)
                        .tracking(0.8)
                    Text(ex.name)
                        .font(.system(size: 15, weight: .semibold))
                    Text("\(ex.sets) sets · \(ex.reps) reps")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(on ? Color.appAccent : Color.secondary.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassEffect(on ? .regular.tint(.appAccent) : .regular, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Confirm button

    private var confirmButton: some View {
        Button {
            let exercises = allExercises.filter { selectedIds.contains($0.id) }
            let muscles = Array(Set(exercises.map(\.muscleGroup))).sorted()
            let name = muscles.count == 1 ? "\(muscles[0]) Focus" : "Custom Workout"
            appState.remoteWorkout = WorkoutDay(
                name: name,
                exercises: exercises,
                durationMinutes: max(30, exercises.count * 8),
                gymType: "Gym",
                muscleGroups: muscles
            )
            onDone()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Use \(selectedIds.count) Exercise\(selectedIds.count == 1 ? "" : "s")")
                    .font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.glassProminent)
        .tint(.appAccent)
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 46))
                .foregroundColor(.appAccent.opacity(0.5))
            Text("No exercises found")
                .font(.system(size: 18, weight: .semibold))
            Text("Load your program first from the dashboard.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Load

    private func loadAllExercises() async {
        isLoading = true
        let week = programService.userProgram?.currentWeek ?? 1
        let weekTemplates = programService.templates.filter { $0.weekNumber == week }
        var result: [Exercise] = []
        for template in weekTemplates {
            let remote = await programService.exercises(for: template.id)
            result += remote.compactMap { $0.toExercise() }
        }
        // Deduplicate by name, keeping first occurrence
        var seen = Set<String>()
        allExercises = result.filter { seen.insert($0.name).inserted }
        isLoading = false
    }
}

#Preview {
    let state = AppState()
    state.onboardingComplete = true
    let service = ProgramService()
    return Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            SwitchSheetView()
                .environment(state)
                .environment(service)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.clear)
        }
        .environment(state)
        .environment(service)
}
