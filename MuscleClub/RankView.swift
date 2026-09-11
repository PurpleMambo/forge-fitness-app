import SwiftUI
import Supabase
import DotLottie

// MARK: - Animated flame (needs its own StateObject lifecycle per row)

private struct AnimatedFlame: View {
    let size: CGFloat
    let active: Bool

    @StateObject private var lottie = DotLottieAnimation(
        fileName: "Flame animation",
        config: AnimationConfig(autoplay: true, loop: true, speed: 1.8)
    )

    var body: some View {
        if active {
            lottie.view()
                .frame(width: size, height: size)
        } else {
            Image(systemName: "flame")
                .font(.system(size: size * 0.55))
                .foregroundStyle(Color.secondary.opacity(0.5))
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Model

private struct LeaderboardRow: Decodable, Identifiable {
    let user_id: String
    let display_name: String
    let total_workouts: Int
    let current_streak: Int

    var id: String { user_id }
}

// MARK: - RankView

struct RankView: View {
    @Environment(AppState.self) private var appState

    @State private var entries: [LeaderboardRow] = []
    @State private var isLoading = true
    @State private var currentUserId: String = ""

    private let avatarNames = ["guy_pfp1", "guy_pfp2", "girl_pfp1", "girl_pfp2", "girl_pfp3"]

    init() {}

    fileprivate init(previewEntries: [LeaderboardRow], currentUserId: String = "") {
        _entries = State(initialValue: previewEntries)
        _isLoading = State(initialValue: false)
        _currentUserId = State(initialValue: currentUserId)
    }

    private func avatar(for userId: String) -> String {
        let hash = userId.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return avatarNames[abs(hash) % avatarNames.count]
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                if isLoading {
                    VStack(spacing: 14) {
                        ProgressView()
                        Text("Loading rankings…")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                } else if entries.isEmpty {
                    emptyState
                } else {
                    scrollContent
                }
            }
            .navigationTitle("Rankings")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await load() }
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                if entries.count >= 3 {
                    podiumSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 36)
                }

                Text("FULL LEADERBOARD")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(Color.appAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)

                VStack(spacing: 8) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                        rankRow(entry: entry, rank: idx + 1)
                            .scrollTransition { content, phase in
                                content
                                    .opacity(1.0 - abs(phase.value) * 0.42)
                                    .offset(x: abs(phase.value) * -10)
                            }
                    }
                }
                .padding(.horizontal, 18)

                Spacer().frame(height: 130)
            }
        }
    }

    // MARK: - Podium (top 3)

    private var podiumSection: some View {
        let top3 = Array(entries.prefix(3))
        return HStack(alignment: .bottom, spacing: 10) {
            podiumSlot(entry: top3[1], rank: 2, podiumHeight: 75)
            podiumSlot(entry: top3[0], rank: 1, podiumHeight: 108)
            podiumSlot(entry: top3[2], rank: 3, podiumHeight: 56)
        }
    }

    private func podiumSlot(entry: LeaderboardRow, rank: Int, podiumHeight: CGFloat) -> some View {
        let isMe = entry.user_id == currentUserId
        let ringColor: Color = rank == 1 ? .appGold : (isMe ? .appAccent : .white.opacity(0.25))

        return VStack(spacing: 6) {
            Image(avatar(for: entry.user_id))
                .resizable()
                .scaledToFill()
                .frame(width: rank == 1 ? 64 : 52, height: rank == 1 ? 64 : 52)
                .clipShape(Circle())
                .overlay(Circle().stroke(ringColor, lineWidth: rank == 1 ? 3 : 1.5))
                .shadow(color: rank == 1 ? Color.appGold.opacity(0.45) : .clear, radius: 10)

            rankBadge(rank: rank)

            Text(isMe ? "You" : (entry.display_name.components(separatedBy: " ").first ?? entry.display_name))
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .foregroundStyle(isMe ? Color.appAccent : Color.primary)

            HStack(spacing: 2) {
                AnimatedFlame(size: 22, active: entry.current_streak > 0)
                Text("\(entry.current_streak)")
                    .font(.system(size: 13, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(entry.current_streak > 0 ? Color.primary : Color.secondary)
            }

            RoundedRectangle(cornerRadius: 10)
                .fill(podiumFill(rank: rank))
                .frame(height: podiumHeight)
                .overlay(
                    Text("#\(rank)")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.black.opacity(0.35))
                        .padding(.bottom, 8),
                    alignment: .bottom
                )
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func rankBadge(rank: Int) -> some View {
        switch rank {
        case 1:
            Image(systemName: "crown.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.appGold)
        case 2:
            ZStack {
                Circle().fill(Color.white.opacity(0.18)).frame(width: 20, height: 20)
                Text("2").font(.system(size: 11, weight: .black)).foregroundStyle(.primary)
            }
        default:
            ZStack {
                Circle().fill(Color(red: 0.75, green: 0.45, blue: 0.2).opacity(0.35)).frame(width: 20, height: 20)
                Text("3").font(.system(size: 11, weight: .black)).foregroundStyle(.primary)
            }
        }
    }

    private func podiumFill(rank: Int) -> Color {
        switch rank {
        case 1: return Color.appGold.opacity(0.80)
        case 2: return Color.white.opacity(0.20)
        case 3: return Color(red: 0.75, green: 0.45, blue: 0.2).opacity(0.65)
        default: return Color.white.opacity(0.10)
        }
    }

    // MARK: - Rank row

    private func rankRow(entry: LeaderboardRow, rank: Int) -> some View {
        let isMe = entry.user_id == currentUserId
        return HStack(spacing: 14) {

            Text("#\(rank)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(rank <= 3 ? Color.appGold : Color.secondary)
                .frame(width: 30, alignment: .trailing)

            Image(avatar(for: entry.user_id))
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(Circle().stroke(isMe ? Color.appAccent : Color.white.opacity(0.12), lineWidth: isMe ? 2 : 0.5))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(isMe ? "You" : entry.display_name)
                        .font(.system(size: 15, weight: isMe ? .bold : .semibold))
                        .foregroundStyle(isMe ? Color.appAccent : Color.primary)
                    if isMe {
                        Text("YOU")
                            .font(.system(size: 8, weight: .black))
                            .tracking(0.8)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(Color.appAccent))
                    }
                }
                Text("\(entry.total_workouts) workouts logged")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    AnimatedFlame(size: 30, active: entry.current_streak > 0)
                    Text("\(entry.current_streak)")
                        .font(.system(size: 17, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(entry.current_streak > 0 ? Color.primary : Color.secondary)
                }
                Text("streak")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .glassEffect(
            isMe ? .regular.tint(.appAccent) : .regular,
            in: .rect(cornerRadius: 18)
        )
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 46))
                .foregroundColor(.appAccent.opacity(0.6))
            Text("No Rankings Yet")
                .font(.system(size: 22, weight: .bold))
            Text("Complete workouts to appear\non the leaderboard.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(36)
        .frame(maxWidth: .infinity)
        .glassEffect(in: .rect(cornerRadius: 22))
        .padding(.horizontal, 32)
    }

    // MARK: - Data loading

    private func load() async {
        currentUserId = (try? await supabase.auth.session.user.id.uuidString) ?? ""
        do {
            let rows: [LeaderboardRow] = try await supabase
                .rpc("get_leaderboard")
                .execute()
                .value
            entries = rows
        } catch {
            print("RankView load error:", error)
        }
        isLoading = false
    }
}

// MARK: - Previews

private let mockEntries: [LeaderboardRow] = [
    LeaderboardRow(user_id: "uid-alex",   display_name: "Alex Johnson",  total_workouts: 31, current_streak: 14),
    LeaderboardRow(user_id: "uid-me",     display_name: "You",           total_workouts: 24, current_streak: 12),
    LeaderboardRow(user_id: "uid-sarah",  display_name: "Sarah Chen",    total_workouts: 18, current_streak: 9),
    LeaderboardRow(user_id: "uid-marcus", display_name: "Marcus Reid",   total_workouts: 22, current_streak: 5),
    LeaderboardRow(user_id: "uid-freya",  display_name: "Freya Hansen",  total_workouts: 15, current_streak: 3),
    LeaderboardRow(user_id: "uid-tom",    display_name: "Tom Blake",     total_workouts: 9,  current_streak: 0),
]

#Preview("Leaderboard — 6 users") {
    RankView(previewEntries: mockEntries, currentUserId: "uid-me")
        .environment(AppState())
}

#Preview("Leaderboard — empty") {
    RankView(previewEntries: [], currentUserId: "uid-me")
        .environment(AppState())
}
