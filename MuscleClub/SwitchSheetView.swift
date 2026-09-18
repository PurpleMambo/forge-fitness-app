import SwiftUI

struct SwitchSheetView: View {
    @Environment(AppState.self) private var appState
    @Environment(ProgramService.self) private var programService
    @Environment(\.dismiss) private var dismiss

    private let cal = Calendar.current
    @State private var navigateToMuscleGroups = false
    @State private var navigateToSaved = false
    @State private var navigateToCreate = false

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
            .navigationDestination(isPresented: $navigateToSaved) {
                SavedWorkoutsView(onDone: { dismiss() })
            }
            .navigationDestination(isPresented: $navigateToCreate) {
                CreateWorkoutView(onDone: { dismiss() })
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
        return appState.weekTemplateRemap[dayName]
            ?? programService.templates.first { $0.dayOfWeek == dayName && $0.weekNumber == week }?.id
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

                Image(systemName: muscleSymbol(for: template.name))
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
                otherOptionRow(icon: "scope",         label: "Pick muscle groups")        { navigateToMuscleGroups = true }
                otherOptionRow(icon: "bookmark.fill", label: "View saved workouts")       { navigateToSaved = true }
                otherOptionRow(icon: "pencil",        label: "Create a workout from scratch") { navigateToCreate = true }
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
        let weekday = cal.component(.weekday, from: appState.selectedDate)
        let todayName = weekdayName(from: weekday)
        let week = programService.userProgram?.currentWeek ?? 1

        let todayEffectiveId = appState.weekTemplateRemap[todayName]
            ?? programService.templates.first { $0.dayOfWeek == todayName && $0.weekNumber == week }?.id

        guard todayEffectiveId != template.id else { dismiss(); return }

        let allWeekTemplates = programService.templates.filter { $0.weekNumber == week }
        var targetCurrentDay = template.dayOfWeek
        for t in allWeekTemplates {
            let effectiveId = appState.weekTemplateRemap[t.dayOfWeek] ?? t.id
            if effectiveId == template.id {
                targetCurrentDay = t.dayOfWeek
                break
            }
        }

        appState.weekTemplateRemap[todayName] = template.id
        if let displaced = todayEffectiveId {
            appState.weekTemplateRemap[targetCurrentDay] = displaced
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
}

// MARK: - Shared helper

private func muscleSymbol(for name: String) -> String {
    let n = name.lowercased()
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
                chipRow.padding(.vertical, 12)

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
                            .glassEffect(on ? .regular.tint(.appAccent) : .regular, in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var exerciseList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ForEach(filteredExercises) { ex in exerciseRow(ex) }
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
                if on { selectedIds.remove(ex.id) } else { selectedIds.insert(ex.id) }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    ExerciseThumbnailView(videoUrl: ex.videoResource, fallbackSymbol: ex.sfSymbol, size: 52, cornerRadius: 12)
                    if on {
                        RoundedRectangle(cornerRadius: 12).fill(Color.appAccent.opacity(0.55)).frame(width: 52, height: 52)
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(ex.muscleGroup.uppercased()).font(.system(size: 10, weight: .heavy)).foregroundColor(.appAccent).tracking(0.8)
                    Text(ex.name).font(.system(size: 15, weight: .semibold))
                    Text("\(ex.sets) sets · \(ex.reps) reps").font(.system(size: 13)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(on ? Color.appAccent : Color.secondary.opacity(0.4))
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .glassEffect(on ? .regular.tint(.appAccent) : .regular, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var confirmButton: some View {
        Button {
            let exercises = allExercises.filter { selectedIds.contains($0.id) }
            let muscles = Array(Set(exercises.map(\.muscleGroup))).sorted()
            appState.remoteWorkout = WorkoutDay(
                name: muscles.count == 1 ? "\(muscles[0]) Focus" : "Custom Workout",
                exercises: exercises,
                durationMinutes: max(30, exercises.count * 8),
                gymType: "Gym",
                muscleGroups: muscles
            )
            onDone()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 16, weight: .bold))
                Text("Use \(selectedIds.count) Exercise\(selectedIds.count == 1 ? "" : "s")").font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
        }
        .buttonStyle(.glassProminent).tint(.appAccent)
        .padding(.horizontal, 20).padding(.bottom, 32)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "figure.strengthtraining.traditional").font(.system(size: 46)).foregroundColor(.appAccent.opacity(0.5))
            Text("No exercises found").font(.system(size: 18, weight: .semibold))
            Text("Load your program first from the dashboard.").font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private func loadAllExercises() async {
        isLoading = true
        let week = programService.userProgram?.currentWeek ?? 1
        let weekTemplates = programService.templates.filter { $0.weekNumber == week }
        var result: [Exercise] = []
        for template in weekTemplates {
            result += await programService.exercises(for: template.id).compactMap { $0.toExercise() }
        }
        var seen = Set<String>()
        allExercises = result.filter { seen.insert($0.name).inserted }
        isLoading = false
    }
}

// MARK: - Saved Workouts

struct SavedWorkoutsView: View {
    @Environment(AppState.self) private var appState
    @Environment(ProgramService.self) private var programService

    let onDone: () -> Void

    @State private var loadingId: UUID? = nil

    private var groupedTemplates: [(week: Int, templates: [RemoteWorkoutTemplate])] {
        let grouped = Dictionary(grouping: programService.templates) { $0.weekNumber }
        return grouped.sorted { $0.key < $1.key }
            .map { (week: $0.key, templates: $0.value.sorted { $0.sortOrder < $1.sortOrder }) }
    }

    var body: some View {
        ZStack {
            AppBackground()
            if groupedTemplates.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(groupedTemplates, id: \.week) { group in
                            weekSection(group.week, templates: group.templates)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 48)
                }
            }
        }
        .navigationTitle("Saved Workouts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }

    private func weekSection(_ week: Int, templates: [RemoteWorkoutTemplate]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Week \(week)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)
            VStack(spacing: 8) {
                ForEach(templates) { template in
                    savedRow(template)
                }
            }
        }
    }

    private func savedRow(_ template: RemoteWorkoutTemplate) -> some View {
        let loading = loadingId == template.id
        return Button {
            guard loadingId == nil else { return }
            Task { await loadAndApply(template) }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: muscleSymbol(for: template.name))
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundStyle(.secondary)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(template.name).font(.system(size: 16, weight: .semibold))
                    Text("Week \(template.weekNumber) · \(template.dayOfWeek.capitalized)")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                }

                Spacer()

                if loading {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.appAccent.opacity(0.8))
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 14)
            .glassEffect(in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .opacity(loadingId != nil && !loading ? 0.5 : 1)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 46)).foregroundColor(.appAccent.opacity(0.5))
            Text("No workouts found").font(.system(size: 18, weight: .semibold))
            Text("Your program workouts will appear here once loaded.")
                .font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }

    private func loadAndApply(_ template: RemoteWorkoutTemplate) async {
        loadingId = template.id
        let remoteExs = await programService.exercises(for: template.id)
        let exercises = remoteExs.compactMap { $0.toExercise() }
        let muscles = Array(Set(exercises.map(\.muscleGroup))).sorted()
        appState.remoteWorkout = WorkoutDay(
            name: template.name,
            exercises: exercises,
            durationMinutes: max(30, exercises.count * 8),
            gymType: "Gym",
            muscleGroups: muscles
        )
        loadingId = nil
        onDone()
    }
}

// MARK: - Create Workout from Scratch

struct CreateWorkoutView: View {
    @Environment(AppState.self) private var appState

    let onDone: () -> Void

    @State private var workoutName = ""
    @State private var exercises: [Exercise] = []
    @State private var showExercisePicker = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    nameField
                    if !exercises.isEmpty { exerciseList }
                    addButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, exercises.isEmpty ? 24 : 110)
            }

            if !exercises.isEmpty {
                startButton.transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: exercises.count)
        .navigationTitle("Build Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .sheet(isPresented: $showExercisePicker) {
            NavigationStack {
                AddExerciseView { newExercises in
                    exercises.append(contentsOf: newExercises)
                }
            }
            .presentationDragIndicator(.visible)
        }
    }

    private var nameField: some View {
        HStack(spacing: 12) {
            Image(systemName: "pencil")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.appAccent)
                .frame(width: 24)
            TextField("Workout name (optional)", text: $workoutName)
                .font(.system(size: 16, weight: .semibold))
        }
        .padding(.horizontal, 16).padding(.vertical, 16)
        .glassEffect(in: .rect(cornerRadius: 14))
    }

    private var exerciseList: some View {
        VStack(spacing: 8) {
            ForEach(exercises) { ex in
                HStack(spacing: 12) {
                    ExerciseThumbnailView(videoUrl: ex.videoResource, fallbackSymbol: ex.sfSymbol, size: 48, cornerRadius: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex.name).font(.system(size: 15, weight: .semibold))
                        Text("\(ex.sets) sets · \(ex.reps) reps").font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.25)) { exercises.removeAll { $0.id == ex.id } }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.secondary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .glassEffect(in: .rect(cornerRadius: 14))
            }
        }
    }

    private var addButton: some View {
        Button { showExercisePicker = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill").font(.system(size: 16, weight: .bold)).foregroundColor(.appAccent)
                Text("Add Exercises").font(.system(size: 15, weight: .semibold)).foregroundColor(.appAccent)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 16)
        }
        .buttonStyle(.glass)
    }

    private var startButton: some View {
        Button {
            let name = workoutName.trimmingCharacters(in: .whitespaces).isEmpty
                ? "Custom Workout"
                : workoutName.trimmingCharacters(in: .whitespaces)
            let muscles = Array(Set(exercises.map(\.muscleGroup))).sorted()
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
                Image(systemName: "play.circle.fill").font(.system(size: 16, weight: .bold))
                Text("Start Workout").font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
        }
        .buttonStyle(.glassProminent).tint(.appAccent)
        .padding(.horizontal, 20).padding(.bottom, 32)
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
