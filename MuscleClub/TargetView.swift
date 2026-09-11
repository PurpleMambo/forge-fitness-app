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
    @State private var animatedProgress: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.4

    private let overallProgress: Double = 0.38

    private let milestones: [GoalMilestone] = [
        .init(id: 1,  title: "First Steps",         subtitle: "Weeks 1–2",   icon: "figure.walk",                          status: .completed, detail: "Log your first 6 workouts"),
        .init(id: 2,  title: "Build the Habit",     subtitle: "Weeks 3–4",   icon: "flame.fill",                           status: .completed, detail: "Reach a 2-week workout streak"),
        .init(id: 3,  title: "Stay Consistent",     subtitle: "Weeks 5–8",   icon: "bolt.fill",                            status: .current,   detail: "Complete 12 workouts this month"),
        .init(id: 4,  title: "Find Your Strength",  subtitle: "Month 3",     icon: "dumbbell.fill",                        status: .upcoming,  detail: "Increase weight on every lift"),
        .init(id: 5,  title: "Unlock Volume",       subtitle: "Month 3–4",   icon: "arrow.up.circle.fill",                 status: .upcoming,  detail: "3 sets × 10 reps across the board"),
        .init(id: 6,  title: "Nutrition Lock-In",   subtitle: "Month 4",     icon: "fork.knife",                           status: .upcoming,  detail: "Track meals for 30 straight days"),
        .init(id: 7,  title: "Push the Limit",      subtitle: "Month 4–5",   icon: "chart.line.uptrend.xyaxis",            status: .upcoming,  detail: "Add 5 kg to your baseline lifts"),
        .init(id: 8,  title: "Strength Summit",     subtitle: "Month 5",     icon: "trophy.fill",                          status: .upcoming,  detail: "New 1-rep max on the big 3"),
        .init(id: 9,  title: "Final Sprint",        subtitle: "Month 5–6",   icon: "hare.fill",                            status: .upcoming,  detail: "12 workouts in the last 6 weeks"),
        .init(id: 10, title: "Body Transformation", subtitle: "Month 6",     icon: "figure.strengthtraining.traditional",  status: .upcoming,  detail: "Complete all 40 program workouts"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Hero (no container – floats on gradient) ──────────
                        heroSection
                            .padding(.horizontal, 28)
                            .padding(.top, 12)
                            .padding(.bottom, 44)

                        // ── Timeline label ────────────────────────────────────
                        Text("Road to Your Goal")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.appAccent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 22)

                        // ── Milestones with scroll carousel effect ────────────
                        ForEach(Array(milestones.enumerated()), id: \.element.id) { idx, milestone in
                            milestoneRow(milestone: milestone, isLast: idx == milestones.count - 1)
                                // Vertical carousel: shrinks + fades as it scrolls off-center
                                .scrollTransition { content, phase in
                                    content
                                        .scaleEffect(
                                            1.0 - abs(phase.value) * 0.11,
                                            anchor: .leading
                                        )
                                        .opacity(1.0 - abs(phase.value) * 0.52)
                                        .blur(radius: abs(phase.value) * 1.5)
                                }
                        }

                        // ── Final destination card ────────────────────────────
                        finalGoalSection
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
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
    }

    // MARK: - Hero Section (bare, no glass container)

    private var heroSection: some View {
        VStack(spacing: 22) {

            // Tappable progress ring
            ringView
                .onTapGesture {
                    Task {
                        withAnimation(.easeIn(duration: 0.22)) {
                            animatedProgress = 0
                        }
                        try? await Task.sleep(for: .milliseconds(260))
                        withAnimation(.easeOut(duration: 1.45)) {
                            animatedProgress = overallProgress
                        }
                    }
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 1.4)) {
                        animatedProgress = overallProgress
                    }
                }

            // Goal title & subtitle
            VStack(spacing: 5) {
                Text("Build Muscle")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.primary)

                Text("16-Week Strength Program")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.appAccent)

                Text("Week 6 of 16  ·  Tap ring to replay")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // Inline progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.10)).frame(height: 5)
                    Capsule().fill(Color.appAccent).frame(width: geo.size.width * overallProgress, height: 5)
                }
            }
            .frame(height: 5)

            // Stats strip (bare)
            HStack(spacing: 0) {
                statItem(value: "18",   label: "Workouts")
                statItem(value: "6",    label: "Day Streak")
                statItem(value: "1.2k", label: "XP Earned")
            }
        }
        .frame(maxWidth: .infinity)
    }

    // The ring lives in its own view so `.id()` forcing is isolated to just the ring
    private var ringView: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.appAccent.opacity(0.16), lineWidth: 11)
                .frame(width: 120, height: 120)

            // Progress arc
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: .appAccent.opacity(0.35), location: 0),
                            .init(color: .appAccent,                location: 1),
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 11, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))

            // Center label
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

    // MARK: - Milestone row (node + card side by side)

    private func milestoneRow(milestone: GoalMilestone, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Left column: node + dashed line below
            VStack(spacing: 0) {
                nodeView(for: milestone)
                // always draw the connector, even on last item (leads down to final goal)
                dashedConnector(completed: milestone.status == .completed)
            }
            .frame(width: 56)
            .padding(.leading, 20)

            // Right: card
            milestoneCard(milestone)
                .padding(.leading, 8)
                .padding(.trailing, 20)
                .padding(.bottom, 14)
        }
    }

    // MARK: - Final Goal card

    private var finalGoalSection: some View {
        HStack(alignment: .top, spacing: 0) {
            // Terminal node (flag, no connector below)
            ZStack {
                Circle()
                    .fill(Color.appAccent)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(Color.appAccent.opacity(0.35), lineWidth: 2.5))
                Image(systemName: "flag.checkered")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)
            }
            .frame(width: 56, height: 48)
            .padding(.leading, 20)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("FINAL GOAL")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.2)
                        .foregroundStyle(.appAccent)
                    Spacer()
                    Text("Month 6")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Text("New Body.\nNew Strength.")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineSpacing(2)

                Text("Finish the full 16-week program and unlock your peak physique. Every rep gets you closer.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)

                HStack(spacing: 14) {
                    Label("40 Workouts", systemImage: "dumbbell.fill")
                    Label("16 Weeks",    systemImage: "calendar")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.appAccent.opacity(0.8))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appAccent.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.appAccent.opacity(0.55), .appAccent.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
            )
            .padding(.leading, 8)
            .padding(.trailing, 20)
        }
    }

    // MARK: - Timeline node

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
                // Pulsing ring
                Circle()
                    .stroke(Color.appAccent.opacity(pulseOpacity), lineWidth: 3)
                    .frame(width: 46, height: 46)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                            pulseScale  = 1.24
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
                // Locked node
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

    // MARK: - Milestone card

    private func milestoneCard(_ milestone: GoalMilestone) -> some View {
        HStack(spacing: 12) {

            // Icon badge – locked ones get a small lock overlay
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

            // Text stack
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(milestone.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(milestone.status == .upcoming ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))

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
                        ? AnyShapeStyle(Color.appAccent.opacity(0.38))
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
            // Locked: dashed border gives a "not yet accessible" feel
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.primary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.primary.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
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
}
