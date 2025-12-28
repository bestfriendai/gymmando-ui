import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.App.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        // Profile Header
                        profileHeader
                            .padding(.top, DesignTokens.Spacing.xl)

                        // Stats Overview
                        statsOverview

                        // Achievement Section
                        achievementSection

                        // Session History
                        sessionHistorySection

                        Spacer(minLength: DesignTokens.Spacing.xl)
                    }
                    .screenPadding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.App.primary)
                }
            }
            .trackScreen("Profile")
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.App.primary, Color.App.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                if let user = authViewModel.currentUser {
                    Text(String(user.firstName.prefix(1)).uppercased())
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("Profile picture")

            // Name and Email
            VStack(spacing: DesignTokens.Spacing.xxs) {
                if let user = authViewModel.currentUser {
                    Text(user.displayName ?? "User")
                        .font(DesignTokens.Typography.headlineSmall)
                        .foregroundColor(Color.App.textPrimary)

                    Text(user.email ?? "")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(Color.App.textSecondary)
                }
            }

            // Edit Profile Button
            Button {
                showEditProfile = true
                HapticManager.shared.impact(style: .light)
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "pencil")
                    Text("Edit Profile")
                }
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(Color.App.primary)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(Color.App.primary.opacity(0.1))
                .cornerRadius(DesignTokens.Radius.full)
            }
            .accessibilityLabel("Edit profile")
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Stats Overview
    private var statsOverview: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Overview")
                .font(DesignTokens.Typography.titleMedium)
                .foregroundColor(Color.App.textPrimary)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: DesignTokens.Spacing.md) {
                ProfileStatCard(
                    value: "0",
                    title: "Total Sessions",
                    icon: "waveform",
                    color: .cyan
                )

                ProfileStatCard(
                    value: "0m",
                    title: "Total Time",
                    icon: "clock.fill",
                    color: .purple
                )
            }

            HStack(spacing: DesignTokens.Spacing.md) {
                ProfileStatCard(
                    value: "0",
                    title: "Day Streak",
                    icon: "flame.fill",
                    color: .orange
                )

                ProfileStatCard(
                    value: "0",
                    title: "Achievements",
                    icon: "trophy.fill",
                    color: .yellow
                )
            }
        }
    }

    // MARK: - Achievement Section
    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Achievements")
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(Color.App.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button("See All") {
                    HapticManager.shared.impact(style: .light)
                }
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(Color.App.primary)
            }

            // Empty state
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "trophy")
                    .font(.system(size: 40))
                    .foregroundColor(Color.App.textTertiary)

                Text("No achievements yet")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(Color.App.textSecondary)

                Text("Complete sessions to unlock achievements")
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(Color.App.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignTokens.Spacing.xl)
            .background(Color.App.surface)
            .cornerRadius(DesignTokens.Radius.lg)
        }
    }

    // MARK: - Session History
    private var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Recent Sessions")
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(Color.App.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button("See All") {
                    HapticManager.shared.impact(style: .light)
                }
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(Color.App.primary)
            }

            // Empty state
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 40))
                    .foregroundColor(Color.App.textTertiary)

                Text("No sessions yet")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(Color.App.textSecondary)

                Text("Start your first AI coaching session")
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(Color.App.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignTokens.Spacing.xl)
            .background(Color.App.surface)
            .cornerRadius(DesignTokens.Radius.lg)
        }
    }
}

// MARK: - Profile Stat Card
struct ProfileStatCard: View {
    let value: String
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: DesignTokens.IconSize.sm))
                    .foregroundColor(color)
                    .accessibilityHidden(true)

                Spacer()
            }

            Text(value)
                .font(DesignTokens.Typography.headlineMedium)
                .foregroundColor(Color.App.textPrimary)

            Text(title)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(Color.App.textSecondary)
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.App.surface)
        .cornerRadius(DesignTokens.Radius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
