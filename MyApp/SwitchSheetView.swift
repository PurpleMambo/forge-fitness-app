import SwiftUI

struct SwitchSheetView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private static let selectedGreen = Color(red: 0.3, green: 0.85, blue: 0.45)
    private let trainingDays: [WorkoutDay] = [.pushDay, .pullDay, .legDay]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    trainingSection
                    otherOptionsSection
                }
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
        }
    }

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

    private var trainingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Within Training Split")
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 20)
            VStack(spacing: 8) {
                ForEach(trainingDays) { day in
                    trainingDayRow(day)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var otherOptionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Other Options")
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 20)
            VStack(spacing: 8) {
                otherOptionRow(icon: "scope", label: "Pick muscle groups")
                otherOptionRow(icon: "bookmark.fill", label: "View saved workouts")
                otherOptionRow(icon: "pencil", label: "Create a workout from scratch")
            }
            .padding(.horizontal, 20)
        }
    }

    private func isSelected(_ day: WorkoutDay) -> Bool {
        appState.todayWorkout?.name == day.name
    }

    private func trainingDayRow(_ day: WorkoutDay) -> some View {
        let selected = isSelected(day)
        return Button { } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(
                            selected ? Self.selectedGreen : Color.secondary.opacity(0.5),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Self.selectedGreen)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(day.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(selected ? Self.selectedGreen : .primary)
                    if let first = day.exercises.first {
                        Text(first.name)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: muscleSymbol(for: day))
                    .font(.system(size: 42, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.2))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .glassEffect(
                selected ? .regular.tint(Self.selectedGreen) : .regular,
                in: .rect(cornerRadius: 16)
            )
        }
        .buttonStyle(.plain)
    }

    private func otherOptionRow(icon: String, label: String) -> some View {
        Button { } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .glassEffect(in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func muscleSymbol(for day: WorkoutDay) -> String {
        switch day.name {
        case "Push Day": return "figure.strengthtraining.functional"
        case "Pull Day": return "figure.arms.open"
        case "Leg Day": return "figure.run"
        default: return "figure.mixed.cardio"
        }
    }
}

#Preview {
    let state = AppState()
    state.onboardingComplete = true
    return Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            SwitchSheetView()
                .environment(state)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(red: 0.08, green: 0.05, blue: 0.12))
        }
        .environment(state)
}
