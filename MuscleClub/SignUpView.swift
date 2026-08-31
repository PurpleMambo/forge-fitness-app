import SwiftUI
import AuthenticationServices
import CryptoKit
import Supabase
import GoogleSignIn

private let googleiOSClientID = "837041480144-s8juc3a72qjc1u3te945e28kvnne5e4u.apps.googleusercontent.com"

struct SignUpView: View {
    let onComplete: () -> Void
    var programId: UUID = UUID(uuidString: "a0000000-0000-0000-0000-000000000001")!

    @Environment(AppState.self) private var appState
    @Environment(ProgramService.self) private var programService
    @State private var currentNonce = ""
    @State private var isLoading = false
    @State private var errorMessage = ""

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

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.horizontal, 28)
                }

                Spacer()

                VStack(spacing: 14) {
                    SignInWithAppleButton(.signUp) { request in
                        currentNonce = randomNonceString()
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(currentNonce)
                    } onCompletion: { result in
                        Task { await handleAppleCompletion(result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .clipShape(.capsule)
                    .disabled(isLoading)

                    Button {
                        Task { await signInWithGoogle() }
                    } label: {
                        HStack(spacing: 10) {
                            if isLoading {
                                ProgressView().tint(Color.appAccent)
                            } else {
                                Image("google_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                                Text("Sign up with Google")
                                    .fontWeight(.semibold)
                            }
                        }
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.white)
                    .foregroundStyle(Color.appAccent)
                    .controlSize(.extraLarge)
                    .disabled(isLoading)

                    Button("Not now") { onComplete() }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.top, 6)
                        .disabled(isLoading)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Apple Sign In

    @MainActor
    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        guard case .success(let auth) = result,
              let credential = auth.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8)
        else {
            if case .failure(let error) = result {
                errorMessage = error.localizedDescription
            }
            return
        }

        isLoading = true
        defer { isLoading = false }
        errorMessage = ""

        do {
            try await supabase.auth.signInWithIdToken(credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: currentNonce
            ))
            appState.isAuthenticated = true
            Task { try? await programService.assignProgram(programId: programId) }
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Google Sign In (native SDK — no browser popup)

    @MainActor
    private func signInWithGoogle() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = ""

        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.keyWindow?.rootViewController else {
            errorMessage = "No window available"
            return
        }

        do {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: googleiOSClientID)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Missing Google ID token"
                return
            }

            try await supabase.auth.signInWithIdToken(credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: result.user.accessToken.tokenString
            ))
            appState.isAuthenticated = true
            Task { try? await programService.assignProgram(programId: programId) }
            onComplete()
        } catch {
            if (error as? GIDSignInError)?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Nonce helpers (Apple Sign In)

    private func randomNonceString(length: Int = 32) -> String {
        let charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return String(bytes.map { charset[charset.index(charset.startIndex, offsetBy: Int($0) % charset.count)] })
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

#Preview {
    SignUpView(onComplete: {})
        .environment(AppState())
        .environment(ProgramService())
        .preferredColorScheme(.dark)
}
