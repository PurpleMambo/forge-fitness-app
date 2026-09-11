import SwiftUI
import AuthenticationServices
import CryptoKit
import Supabase
import GoogleSignIn

private let googleiOSClientID = "837041480144-s8juc3a72qjc1u3te945e28kvnne5e4u.apps.googleusercontent.com"

struct LoginView: View {
    let onComplete: () -> Void

    @Environment(AppState.self) private var appState
    @Environment(ProgramService.self) private var programService
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentNonce = ""
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "bolt.fill")
                    .font(.system(size: 72, weight: .light))
                    .foregroundColor(.appAccent)
                    .padding(.bottom, 36)

                VStack(spacing: 12) {
                    Text("Welcome back")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Sign in to pick up right where you left off.")
                        .font(.body)
                        .foregroundStyle(.secondary)
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
                    SignInWithAppleButton(.signIn) { request in
                        currentNonce = randomNonceString()
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(currentNonce)
                    } onCompletion: { result in
                        Task { await handleAppleCompletion(result) }
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
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
                                Text("Sign in with Google")
                                    .fontWeight(.semibold)
                            }
                        }
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.appAccent)
                    .controlSize(.extraLarge)
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
            await finishLogin()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Google Sign In

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
            await finishLogin()
        } catch {
            if (error as? GIDSignInError)?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Post-auth routing

    @MainActor
    private func finishLogin() async {
        appState.isAuthenticated = true
        appState.welcomeSeen = true
        // Load programs to check if this is a real returning user.
        // If they accidentally hit "sign in" without an account, Supabase creates
        // one but no program row exists yet — route them through onboarding instead.
        await programService.loadAll()
        if programService.userProgram != nil {
            appState.onboardingComplete = true
        }
        onComplete()
    }

    // MARK: - Nonce helpers

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
    LoginView(onComplete: {})
        .environment(AppState())
        .environment(ProgramService())
        .preferredColorScheme(.dark)
}
