import SwiftUI

// MARK: - Full-screen video player (presented when tapping the hero video in ExerciseDetailView)
struct FullScreenVideoView: View {
    let url: URL
    @Environment(\.dismiss) var dismiss
    @State private var isMuted = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            LoopingVideoPlayer(url: url, isMuted: isMuted)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
                    }
                    .buttonStyle(.glass)
                    .padding(.leading, 16)
                    .padding(.top, 60)

                    Spacer()

                    Button { isMuted.toggle() } label: {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .buttonStyle(.glass)
                    .padding(.trailing, 16)
                    .padding(.top, 60)
                }
                Spacer()
            }
        }
        .statusBarHidden()
    }
}
