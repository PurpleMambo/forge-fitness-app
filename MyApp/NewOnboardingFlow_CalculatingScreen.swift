import SwiftUI

struct NewOnboardingFlow_CalculatingScreen: View {
    let model: NewOnboardingFlowViewModel

    @State private var progress: Double = 0
    @State private var statusText = "Analyzing your fitness profile…"
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Pulsing bolt icon
            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.10))
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulseScale)
                Circle()
                    .fill(Color.appAccent.opacity(0.05))
                    .frame(width: 210, height: 210)
                    .scaleEffect(pulseScale)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 62, weight: .heavy))
                    .foregroundStyle(.appAccent)
            }
            .padding(.bottom, 48)

            Spacer()

            VStack(spacing: 6) {
                Text("Building your")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                Text("custom plan…")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.appAccent)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
            .padding(.bottom, 44)

            // Circular progress
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.appAccent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.05), value: progress)
                Text("\(Int(progress * 100))%")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .frame(width: 88, height: 88)

            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 14)
                .animation(.easeInOut(duration: 0.3), value: statusText)

            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                pulseScale = 1.18
            }
        }
        .task { await run() }
    }

    private func run() async {
        let totalTicks = 60
        for tick in 0..<totalTicks {
            try? await Task.sleep(for: .milliseconds(55))
            withAnimation(.linear(duration: 0.05)) {
                progress = Double(tick + 1) / Double(totalTicks)
            }
            if tick == 20 { withAnimation { statusText = "Calibrating your starting weights…" } }
            if tick == 40 { withAnimation { statusText = "Structuring your training week…" } }
        }
        try? await Task.sleep(for: .milliseconds(600))
        model.advance()
    }
}
