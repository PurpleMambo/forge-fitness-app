import SwiftUI
import Supabase

struct AccountView: View {
    @Environment(AppState.self) private var appState

    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var isLoading = false

    private var initials: String {
        let parts = userName.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map { String($0) } }.joined().uppercased()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Avatar + name + email
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.appAccent)
                                    .frame(width: 80, height: 80)
                                Text(initials.isEmpty ? "?" : initials)
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(spacing: 4) {
                                if !userName.isEmpty {
                                    Text(userName)
                                        .font(.system(size: 22, weight: .bold))
                                }
                                if !userEmail.isEmpty {
                                    Text(userEmail)
                                        .font(.system(size: 15))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.top, 32)

                        // Actions
                        VStack(spacing: 12) {
                            Button {
                                showLogoutAlert = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.right.square")
                                        .font(.system(size: 18))
                                    Text("Log Out")
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                            .buttonStyle(.glass)

                            Button {
                                showDeleteAlert = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 18))
                                    Text("Delete Account")
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                            .buttonStyle(.glass)
                            .tint(.red)
                            .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 18)

                        Spacer(minLength: 80)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Account")
        }
        .task { await loadUser() }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Log Out", role: .destructive) { Task { await logOut() } }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { Task { await logOut() } }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your account and all data will be permanently deleted. This cannot be undone.")
        }
    }

    private func loadUser() async {
        guard let user = try? await supabase.auth.session.user else { return }
        userEmail = user.email ?? ""
        // Google sets "full_name", Apple sets "name"
        if case .string(let name) = user.userMetadata["full_name"] {
            userName = name
        } else if case .string(let name) = user.userMetadata["name"] {
            userName = name
        }
    }

    @MainActor
    private func logOut() async {
        isLoading = true
        try? await supabase.auth.signOut()
        appState.isAuthenticated = false
        appState.onboardingComplete = false
        appState.welcomeSeen = false
        isLoading = false
    }
}

#Preview {
    AccountView()
        .environment(AppState())
}
