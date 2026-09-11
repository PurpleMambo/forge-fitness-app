import SwiftUI

// MARK: - Models

private enum MilestoneStatus {
    case completed, current, upcoming
}

private struct GoalMilestone: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let icon: String
    let status: MilestoneStatus
    let detail: String
}

// MARK: - Target View

struct TargetView: View {
    @Environment(AppState.self)      private var appState
    @Environment(StreakService.self) private var streakService
    @Environment(ProgramService.self) private var programService

    @State private var animatedProgress: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.4

    // MARK: - Derived live values

    private var workoutCount: Int  { streakService.totalWorkouts }
    private var currentStreak: Int { streakService.currentStreak }
    private var currentWeek: Int   { programService.userProgram?.currentWeek ?? 1 }
    private var totalWeeks: Int    { programService.templates.map(\.weekNumber).max() ?? 16 }
    private var overallProgress: Double { min(Double(currentWeek - 1) / Double(totalWeeks), 1.0) }

    private var programName: String {
        guard let up = programService.userProgram,
              let prog = programService.programs.first(where: { $0.id == up.programId })
        else { return "Build Muscle" }
        return prog.name
    }

    private var xpString: String {
        let xp = workoutCount * 100
        return xp >= 1000
            ? String(format: "%.1fk", Double(xp) / 1000)
            : "\(xp)"
    }

    private var weekSubtitle: String { "Week \(currentWeek) of \(totalWeeks)" }
    private var totalWorkouts: Int { programService.milestones.last?.workoutThreshold ?? 40 }

    // The first milestone not yet met becomes .current; everything before → .completed, after → .upcoming
    private var milestones: [GoalMilestone] {
        var foundCurrent = false
        return programService.milestones.map { m in
            let status: MilestoneStatus
            if workoutCount >= m.workoutThreshold {
                status = .completed
            } else if !foundCurrent {
                foundCurrent = true
                status = .current
            } else {
                status = .upcoming
            }
            return GoalMilestone(
                id: m.sortOrder, title: m.title, subtitle: m.subtitle,
                icon: m.sfSymbol, status: status, detail: m.detail
            )
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        heroSection
                            .padding(.horizontal, 28)
                            .padding(.top, 12)
                            .padding(.bottom, 44)

                        Text("Road to Your Goal")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.appAccent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 22)

                        ForEach(Array(milestones.enumerated()), id: \.element.id) { idx, milestone in
                            milestoneRow(milestone: milestone, isLast: idx == milestones.count - 1)
                                .scrollTransition { content, phase in
                                    content
                                        .scaleEffect(1.0 - abs(phase.value) * 0.11, anchor: .leading)
                                        .opacity(1.0 - abs(phase.value) * 0.52)
                                        .blur(radius: abs(phase.value) * 1.5)
                                }
                        }

                        finalGoalSection
                            .scrollTransition { content, phase in
                                content
                                    .scaleEffect(1.0 - abs(phase.value) * 0.08)
                                    .opacity(1.0 - abs(phase.value) * 0.5)
                            }

                        Spacer().frame(height: 130)
                    }
                }
            }
            .navigationTitle("Target")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await streakService.loadStreak() }
        .onChange(of: overallProgress) { _, new in
            withAnimation(.easeOut(duration: 1.0)) { animatedProgress = new }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 22) {

            ringView
                .onTapGesture {
                    Task {
                        withAnimation(.easeIn(duration: 0.22)) { animatedProgress = 0 }
                        try? await Task.sleep(for: .milliseconds(260))
                        withAnimation(.easeOut(duration: 1.45)) { animatedProgress = overallProgress }
                    }
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 1.4)) { animatedProgress = overallProgress }
                }

            VStack(spacing: 5) {
                Text(programName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.primary)

                Text("16-Week Strength Program")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appAccent)

                Text("\(weekSubtitle)  ·  Tap ring to replay")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.10)).frame(height: 5)
                    Capsule().fill(Color.appAccent)
                        .frame(width: geo.size.width * overallProgress, height: 5)
                }
            }
            .frame(height: 5)

            HStack(spacing: 0) {
                statItem(value: "\(workoutCount)", label: "Workouts")
                statItem(value: "\(currentStreak)", label: "Day Streak")
                statItem(value: xpString,           label: "XP Earned")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var ringView: some View {
        ZStack {
            Circle()
                .stroke(Color.appAccent.opacity(0.16), lineWidth: 11)
                .frame(width: 120, height: 120)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: .appAccent.opacity(0.4), location: 0),
                            .init(color: .appAccent,               location: 1),
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 11, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(Int(overallProgress * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("complete")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Milestone row

    private func milestoneRow(milestone: GoalMilestone, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                nodeView(for: milestone)
                dashedConnector(completed: milestone.status == .completed)
            }
            .frame(width: 56)
            .padding(.leading, 20)

            milestoneCard(milestone)
                .padding(.leading, 8)
                .padding(.trailing, 20)
                .padding(.bottom, 14)
        }
    }

    // MARK: - Final Goal card

    private var finalGoalSection: some View {
        HStack(alignment: .top, spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.07))
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.primary.opacity(0.13), lineWidth: 1.5))
                Image(systemName: "flag.checkered")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.45))
            }
            .frame(width: 56, height: 48)
            .padding(.leading, 20)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("FINAL GOAL")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Month 6")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Text("New Body.\nNew Strength.")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)

                Text("Finish the full \(totalWeeks)-week program and unlock your peak physique.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary.opacity(0.55))
                    .lineSpacing(3)

                HStack(spacing: 14) {
                    Label("\(totalWorkouts) Workouts", systemImage: "dumbbell.fill")
                    Label("\(totalWeeks) Weeks",    systemImage: "calendar")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary.opacity(0.45))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.primary.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.primary.opacity(0.08),
                                    style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    )
            )
            .padding(.leading, 8)
            .padding(.trailing, 20)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Timeline components

    @ViewBuilder
    private func nodeView(for milestone: GoalMilestone) -> some View {
        ZStack {
            switch milestone.status {
            case .completed:
                Circle()
                    .fill(Color.appAccent)
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.black)

            case .current:
                Circle()
                    .stroke(Color.appAccent.opacity(pulseOpacity), lineWidth: 3)
                    .frame(width: 46, height: 46)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                            pulseScale   = 1.24
                            pulseOpacity = 0.07
                        }
                    }
                Circle()
                    .fill(Color.appAccent)
                    .frame(width: 32, height: 32)
                Image(systemName: milestone.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black)

            case .upcoming:
                Circle()
                    .fill(Color.primary.opacity(0.07))
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.primary.opacity(0.13), lineWidth: 1.5))
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.45))
            }
        }
        .frame(width: 56, height: 48)
    }

    private func dashedConnector(completed: Bool) -> some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 28, y: 0))
                path.addLine(to: CGPoint(x: 28, y: geo.size.height))
            }
            .stroke(
                completed ? Color.appAccent.opacity(0.5) : Color.primary.opacity(0.13),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5])
            )
        }
        .frame(width: 56, height: 66)
    }

    private func milestoneCard(_ milestone: GoalMilestone) -> some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconBg(for: milestone))
                    .frame(width: 44, height: 44)
                Image(systemName: milestone.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(iconFg(for: milestone))
                    .frame(width: 44, height: 44)

                if milestone.status == .upcoming {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.systemBackground).opacity(0.88))
                            .frame(width: 17, height: 17)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .offset(x: 5, y: 5)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(milestone.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(milestone.status == .upcoming
                            ? AnyShapeStyle(.secondary)
                            : AnyShapeStyle(.primary))

                    if milestone.status == .current {
                        Text("NOW")
                            .font(.system(size: 9, weight: .black))
                            .tracking(0.8)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.appAccent))
                    }

                    Spacer(minLength: 0)
                }

                Text(milestone.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(milestone.status == .upcoming
                        ? AnyShapeStyle(Color.appAccent.opacity(0.32))
                        : AnyShapeStyle(Color.appAccent.opacity(0.82)))

                Text(milestone.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(milestone.status == .upcoming
                        ? AnyShapeStyle(Color.secondary.opacity(0.5))
                        : AnyShapeStyle(Color.secondary))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(for: milestone))
    }

    @ViewBuilder
    private func cardBackground(for milestone: GoalMilestone) -> some View {
        switch milestone.status {
        case .current:
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appAccent.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appAccent.opacity(0.32), lineWidth: 1))
        case .completed:
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.primary.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.primary.opacity(0.09), lineWidth: 1))
        case .upcoming:
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.primary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.primary.opacity(0.08),
                                style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                )
        }
    }

    private func iconBg(for milestone: GoalMilestone) -> Color {
        switch milestone.status {
        case .completed: return .appAccent.opacity(0.18)
        case .current:   return .appAccent.opacity(0.22)
        case .upcoming:  return .primary.opacity(0.05)
        }
    }

    private func iconFg(for milestone: GoalMilestone) -> AnyShapeStyle {
        switch milestone.status {
        case .completed, .current: return AnyShapeStyle(Color.appAccent)
        case .upcoming:            return AnyShapeStyle(Color.secondary.opacity(0.35))
        }
    }
}

// MARK: - Preview

#Preview {
    TargetView()
        .environment(AppState())
        .environment(ProgramService())
        .environment(StreakService(previewStreak: 6))
}
