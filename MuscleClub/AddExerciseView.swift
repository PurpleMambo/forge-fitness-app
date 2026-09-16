import SwiftUI
import Supabase

// MARK: - Add Exercise Picker Sheet
struct AddExerciseView: View {
    enum BrowseTab { case all, byMuscle, categories }

    let onAdd: ([Exercise]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: BrowseTab = .all
    @State private var searchText = ""
    @State private var selectedIds: Set<UUID> = []
    @State private var allExercises: [RemoteExercise] = []
    @State private var isLoading = false

    // MARK: - Computed

    private var displayedExercises: [RemoteExercise] {
        guard !searchText.isEmpty else { return allExercises }
        return allExercises.filter { $0.nameEn.localizedCaseInsensitiveContains(searchText) }
    }

    private var alphabeticalSections: [(key: String, exercises: [RemoteExercise])] {
        let grouped = Dictionary(grouping: displayedExercises) { ex -> String in
            guard let first = ex.nameEn.first else { return "#" }
            return first.isNumber ? "#" : String(first).uppercased()
        }
        return grouped.sorted { a, b in
            if a.key == "#" { return b.key != "#" }
            if b.key == "#" { return false }
            return a.key < b.key
        }.map { (key: $0.key, exercises: $0.value.sorted { $0.nameEn < $1.nameEn }) }
    }

    private var muscleGroupSections: [(area: String, groups: [(name: String, count: Int)])] {
        let grouped = Dictionary(grouping: displayedExercises) { $0.muscleGroup }
        let allGroups = grouped.map { (name: $0.key, count: $0.value.count) }.sorted { $0.name < $1.name }

        let torso = Set(["Chest", "Back", "Shoulders", "Abs", "Core", "Lower Back", "Trapezius", "Rear Delt"])
        let arms  = Set(["Biceps", "Triceps", "Forearms"])
        let legs  = Set(["Quads", "Hamstrings", "Glutes", "Calves", "Hip Flexors", "Adductors"])

        let torsoGroups = allGroups.filter { torso.contains($0.name) }
        let armGroups   = allGroups.filter { arms.contains($0.name) }
        let legGroups   = allGroups.filter { legs.contains($0.name) }
        let otherGroups = allGroups.filter { !torso.contains($0.name) && !arms.contains($0.name) && !legs.contains($0.name) }

        var sections: [(area: String, groups: [(name: String, count: Int)])] = []
        if !torsoGroups.isEmpty { sections.append((area: "Torso",  groups: torsoGroups)) }
        if !armGroups.isEmpty   { sections.append((area: "Arms",   groups: armGroups)) }
        if !legGroups.isEmpty   { sections.append((area: "Legs",   groups: legGroups)) }
        if !otherGroups.isEmpty { sections.append((area: "Other",  groups: otherGroups)) }
        return sections
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Picker("Browse", selection: $selectedTab) {
                    Text("All").tag(BrowseTab.all)
                    Text("By Muscle").tag(BrowseTab.byMuscle)
                    Text("Categories").tag(BrowseTab.categories)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

                Group {
                    if isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else {
                        switch selectedTab {
                        case .all:        allTab
                        case .byMuscle:   byMuscleTab
                        case .categories: categoriesTab
                        }
                    }
                }
            }
        }
        .navigationTitle("All Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    ZStack {
                        Circle()
                            .fill(.secondary.opacity(0.2))
                            .frame(width: 28, height: 28)
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .task { await loadExercises() }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 8) {
            if !selectedIds.isEmpty {
                Button { commitSelection() } label: {
                    let n = selectedIds.count
                    Text(n == 1 ? "Add Exercise" : "Add \(n) Exercises")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.glassProminent)
                .tint(.appAccent)
                .padding(.horizontal, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 15))
                TextField("Search exercises", text: $searchText)
                    .font(.system(size: 15))
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .animation(.spring(response: 0.3), value: selectedIds.isEmpty)
    }

    // MARK: - All Tab

    private var allTab: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(alphabeticalSections, id: \.key) { section in
                    Section {
                        ForEach(section.exercises) { ex in
                            exerciseRow(ex)
                            Divider().padding(.leading, 82)
                        }
                    } header: {
                        Text(section.key)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.ultraThinMaterial)
                    }
                }
                Color.clear.frame(height: 8)
            }
        }
    }

    // MARK: - By Muscle Tab

    private var byMuscleTab: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(muscleGroupSections, id: \.area) { section in
                    Text(section.area)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 5)
                    ForEach(section.groups, id: \.name) { group in
                        muscleGroupRow(name: group.name, count: group.count)
                        Divider().padding(.leading, 82)
                    }
                }
                Color.clear.frame(height: 8)
            }
        }
    }

    // MARK: - Categories Tab

    private var categoriesTab: some View {
        let items: [(icon: String, title: String, tab: BrowseTab?)] = [
            ("dumbbell.fill",                        "All Exercises",              .all),
            ("clock.arrow.circlepath",               "Recently Added",             nil),
            ("person.fill",                          "Added By Me",                nil),
            ("figure.strengthtraining.traditional",  "By Muscle Groups",           .byMuscle),
            ("wrench.fill",                          "By Equipment",               nil),
            ("scalemass.fill",                       "Weighted Exercises",         nil),
            ("figure.walk",                          "Bodyweight Only",            nil),
            ("figure.mixed.cardio",                  "Bodyweight with Equipment",  nil),
            ("heart.fill",                           "Cardio",                     nil),
            ("figure.flexibility",                   "Stretching & Mobility",      nil),
        ]
        return ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(items, id: \.title) { item in
                    Button {
                        if let tab = item.tab { selectedTab = tab }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: item.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                                .frame(width: 32)
                            Text(item.title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 62)
                }
                Color.clear.frame(height: 8)
            }
        }
    }

    // MARK: - Row Components

    private func exerciseRow(_ ex: RemoteExercise) -> some View {
        let isSelected = selectedIds.contains(ex.id)
        return Button {
            withAnimation(.spring(response: 0.2)) {
                if isSelected { selectedIds.remove(ex.id) } else { selectedIds.insert(ex.id) }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.secondary.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: ex.sfSymbol)
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                Text(ex.nameEn)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                Spacer()
                checkbox(selected: isSelected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func muscleGroupRow(name: String, count: Int) -> some View {
        Button {
            searchText = name
            selectedTab = .all
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.secondary.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: muscleSymbol(for: name))
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.primary)
                    Text("\(count) exercise\(count == 1 ? "" : "s")")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func checkbox(selected: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .stroke(selected ? Color.appAccent : Color.secondary.opacity(0.4), lineWidth: 1.5)
                .frame(width: 22, height: 22)
            if selected {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.appAccent)
                    .frame(width: 22, height: 22)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Helpers

    private func muscleSymbol(for muscle: String) -> String {
        switch muscle.lowercased() {
        case "chest":                              return "figure.arms.open"
        case "back", "lower back":                return "figure.strengthtraining.traditional"
        case "shoulders", "trapezius", "rear delt": return "figure.mixed.cardio"
        case "biceps", "triceps", "forearms":      return "dumbbell.fill"
        case "abs", "core":                        return "figure.core.training"
        case "quads", "hamstrings", "glutes",
             "calves", "hip flexors", "adductors": return "figure.walk"
        default:                                   return "figure.strengthtraining.functional"
        }
    }

    private func commitSelection() {
        let selected = allExercises.filter { selectedIds.contains($0.id) }
        let exercises = selected.map { ex in
            Exercise(
                name: ex.nameEn,
                sets: 3,
                reps: 10,
                weight: 0,
                weightUnit: "kg",
                muscleGroup: ex.muscleGroup,
                isFocus: false,
                sfSymbol: ex.sfSymbol
            )
        }
        onAdd(exercises)
        dismiss()
    }

    // MARK: - Data

    private func loadExercises() async {
        isLoading = true
        do {
            let results: [RemoteExercise] = try await supabase
                .from("exercises")
                .select()
                .eq("exercise_type", value: "exercise")
                .order("name_en")
                .execute()
                .value
            allExercises = results
        } catch {
            // Falls through with empty list; user still sees UI
        }
        isLoading = false
    }
}
