import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(.white)
                    .padding(.bottom, 36)

                VStack(spacing: 12) {
                    Text("Save your results")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Create a free account to keep your personalised plan and track your progress over time.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 28)

                Spacer()

                VStack(spacing: 14) {
                    SignInWithAppleButton(.signUp) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { _ in
                        onComplete()
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .clipShape(.capsule)

                    Button {
                        onComplete()
                    } label: {
                        HStack(spacing: 10) {
                            Image("google_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            Text("Sign up with Google")
                                .fontWeight(.semibold)
                        }
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.white)
                    .foregroundStyle(Color.appAccent)
                    .controlSize(.extraLarge)

                    Button("Not now") {
                        onComplete()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.top, 6)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    SignUpView(onComplete: {})
        .preferredColorScheme(.dark)
}
