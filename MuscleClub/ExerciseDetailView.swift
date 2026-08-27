import SwiftUI
import AVFoundation

// MARK: - Bundle helper: robust video URL lookup (handles Unicode NFC/NFD normalization edge cases)
extension Bundle {
    func videoURL(named name: String) -> URL? {
        // 1. Standard lookup
        if let u = url(forResource: name, withExtension: "mov") { return u }
        // 2. Direct filesystem path (bypasses Bundle's internal string normalisation)
        if let rp = resourcePath {
            let full = (rp as NSString).appendingPathComponent("\(name).mov")
            if FileManager.default.fileExists(atPath: full) { return URL(fileURLWithPath: full) }
        }
        // 3. Enumerate every .mov in the bundle and compare decoded names
        return urls(forResourcesWithExtension: "mov", subdirectory: nil)?
            .first { $0.deletingPathExtension().lastPathComponent == name }
    }
}

// MARK: - Looping video player (resizeAspectFill crops landscape → portrait)
// isMuted is live-updated via updateUIView so a toggle in SwiftUI takes effect immediately.
struct LoopingVideoPlayer: UIViewRepresentable {
    let url: URL
    var isMuted: Bool = true
    var isPlaying: Bool = true

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.setURL(url, isMuted: isMuted, coordinator: context.coordinator)
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.setMuted(isMuted)
        uiView.setPlaying(isPlaying)
    }

    class Coordinator {
        var observer: NSObjectProtocol?
        weak var player: AVPlayer?
        deinit {
            player?.pause()
            observer.map { NotificationCenter.default.removeObserver($0) }
        }
    }

    class PlayerView: UIView {
        private let playerLayer = AVPlayerLayer()
        private var shouldBePlaying = true

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .black
            playerLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(playerLayer)
        }

        required init?(coder: NSCoder) { fatalError() }

        func setURL(_ url: URL, isMuted: Bool, coordinator: Coordinator) {
            let player = AVPlayer(url: url)
            player.isMuted = isMuted
            playerLayer.player = player
            coordinator.player = player

            coordinator.observer = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { [weak player, weak self] _ in
                player?.seek(to: .zero) { _ in
                    if self?.shouldBePlaying == true { player?.play() }
                }
            }

            player.play()
        }

        func setMuted(_ muted: Bool) {
            playerLayer.player?.isMuted = muted
        }

        func setPlaying(_ playing: Bool) {
            shouldBePlaying = playing
            guard let player = playerLayer.player else { return }
            playing ? player.play() : player.pause()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }
    }
}

// MARK: - Exercise Detail View (tapped from dashboard exercise list)
struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    @State private var showAllAliases = false
    @State private var isMuted = false
    @State private var isVideoPlaying = true

    private let tabs = ["Instructions", "Target", "Equipment"]

    var body: some View {
        ZStack(alignment: .top) {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    contentSection
                }
            }
            .ignoresSafeArea(edges: .top)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 14, weight: .bold))
                }
                .buttonStyle(.glass)
                .padding(.leading, 16)
                .padding(.top, 60)
                Spacer()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        // Full-screen video disabled — tap now pauses/resumes inline
        // .fullScreenCover(isPresented: $showFullscreen) {
        //     FullScreenVideoView(url: url)
        // }
    }

    var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let resource = exercise.videoResource,
               let url = Bundle.main.videoURL(named: resource) {
                // Tapping the video pauses/resumes playback
                Button { isVideoPlaying.toggle() } label: {
                    LoopingVideoPlayer(url: url, isMuted: isMuted, isPlaying: isVideoPlaying)
                        .frame(maxWidth: .infinity)
                        .frame(height: 320)
                        .clipped()
                        .overlay {
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.55)],
                                startPoint: .center, endPoint: .bottom)
                        }
                        .overlay {
                            if !isVideoPlaying {
                                ZStack {
                                    Color.black.opacity(0.25)
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 56))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                            }
                        }
                }
                .buttonStyle(.plain)
            } else {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color(red: 0.15, green: 0.10, blue: 0.25), .black],
                        startPoint: .top, endPoint: .bottom))
                    .frame(height: 320)
                    .overlay {
                        VStack(spacing: 20) {
                            Image(systemName: exercise.sfSymbol)
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.18))
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.18))
                                    .frame(width: 56, height: 56)
                                Image(systemName: "play.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .offset(x: 2)
                            }
                        }
                    }
            }

            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                        .frame(width: 60, height: 60)
                    Image(systemName: exercise.sfSymbol)
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
                Spacer()
                // Mute toggle
                if exercise.videoResource != nil {
                    Button { isMuted.toggle() } label: {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .buttonStyle(.glass)
                }
                Text("1.0 x")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .glassEffect()
            }
            .padding(.horizontal, 16).padding(.bottom, 14)
        }
    }

    var contentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(exercise.name)
                .font(.system(size: 28, weight: .heavy))
                .padding(.horizontal, 20)
                .padding(.top, 20)

            if !exercise.aliasesText.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3)) { showAllAliases.toggle() }
                } label: {
                    HStack(spacing: 5) {
                        Text("Also called: \(exercise.aliasesText)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(showAllAliases ? nil : 1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(showAllAliases ? 180 : 0))
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }

            tabSelector
                .padding(.horizontal, 20)
                .padding(.top, 20)

            tabContent
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 48)
        }
    }

    var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedTab = i }
                } label: {
                    Text(tabs[i])
                        .font(.system(size: 13, weight: selectedTab == i ? .semibold : .regular))
                        .foregroundColor(selectedTab == i ? .primary : .secondary)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .background {
                    if selectedTab == i {
                        Capsule().fill(.white.opacity(0.12))
                    }
                }
            }
        }
        .padding(4)
        .glassEffect(in: .rect(cornerRadius: 22))
    }

    @ViewBuilder
    var tabContent: some View {
        switch selectedTab {
        case 0: instructionsTab
        case 1: targetTab
        default: equipmentTab
        }
    }

    var instructionsTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            if exercise.instructionSteps.isEmpty {
                Text("Video instructions for \(exercise.name) coming soon.")
                    .font(.system(size: 15)).foregroundStyle(.secondary).lineSpacing(4)
            } else {
                ForEach(Array(exercise.instructionSteps.enumerated()), id: \.offset) { i, step in
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            Circle().fill(Color.appAccent).frame(width: 22, height: 22)
                            Text("\(i + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text(step)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    var targetTab: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !exercise.primaryMuscles.isEmpty {
                muscleSection("Primary", muscles: exercise.primaryMuscles)
            }
            if !exercise.secondaryMuscles.isEmpty {
                muscleSection("Secondary", muscles: exercise.secondaryMuscles)
            }
            if exercise.primaryMuscles.isEmpty && exercise.secondaryMuscles.isEmpty {
                Text("Target muscle data coming soon.")
                    .font(.system(size: 15)).foregroundStyle(.secondary)
            }
        }
    }

    func muscleSection(_ title: String, muscles: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1)
            ForEach(muscles, id: \.self) { muscle in
                HStack(spacing: 14) {
                    Image(systemName: "figure.arms.open")
                        .font(.system(size: 18))
                        .foregroundColor(.appAccent)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.tint(.appAccent), in: .rect(cornerRadius: 10))
                    Text(muscle)
                        .font(.system(size: 15, weight: .medium))
                }
            }
        }
    }

    var equipmentTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            if exercise.equipmentList.isEmpty {
                Text("Equipment info coming soon.")
                    .font(.system(size: 15)).foregroundStyle(.secondary)
            } else {
                ForEach(exercise.equipmentList, id: \.self) { item in
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.appAccent)
                        Text(item)
                            .font(.system(size: 15))
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: WorkoutDay.pushDay.exercises[0])
    }
    .preferredColorScheme(.dark)
}
