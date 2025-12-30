import SwiftUI
import FirebaseAuth
import PhotosUI

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
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet(user: authViewModel.currentUser)
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

            // Empty state with CTA
            VStack(spacing: DesignTokens.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.App.primary.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                Text("Unlock Your First Badge")
                    .font(DesignTokens.Typography.titleSmall)
                    .foregroundColor(Color.App.textPrimary)

                Text("Complete your first coaching session to earn the \"Getting Started\" achievement")
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(Color.App.textSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    dismiss()
                    HapticManager.shared.impact(style: .medium)
                } label: {
                    Text("Start First Session")
                        .font(DesignTokens.Typography.labelMedium)
                        .foregroundColor(Color.App.primary)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(Color.App.primary.opacity(0.15))
                        .cornerRadius(DesignTokens.Radius.full)
                }
                .accessibilityLabel("Start your first coaching session")
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

            // Empty state with illustration
            VStack(spacing: DesignTokens.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.App.secondary.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Your Journey Begins Here")
                    .font(DesignTokens.Typography.titleSmall)
                    .foregroundColor(Color.App.textPrimary)

                Text("Your workout history will appear here after your first session with your AI coach")
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(Color.App.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignTokens.Spacing.xl)
            .background(Color.App.surface)
            .cornerRadius(DesignTokens.Radius.lg)
        }
    }
}

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
    let user: AppUser?
    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.App.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        // Photo Picker
                        photoSection

                        // Name Field
                        nameSection

                        // Info Section
                        infoSection

                        Spacer(minLength: DesignTokens.Spacing.xl)
                    }
                    .screenPadding()
                    .padding(.top, DesignTokens.Spacing.lg)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.App.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color.App.primary)
                    .disabled(isSaving)
                }
            }
            .onAppear {
                displayName = user?.displayName ?? ""
            }
        }
    }

    // MARK: - Photo Section
    private var photoSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    if let profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.App.primary, Color.App.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        if let user = user {
                            Text(String(user.firstName.prefix(1)).uppercased())
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    }

                    // Camera badge
                    Circle()
                        .fill(Color.App.primary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                        .offset(x: 35, y: 35)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                loadPhoto(from: newValue)
            }

            Text("Change Photo")
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(Color.App.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Profile photo. Tap to change")
    }

    // MARK: - Name Section
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("Display Name")
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(Color.App.textSecondary)

            TextField("Your name", text: $displayName)
                .font(DesignTokens.Typography.bodyLarge)
                .foregroundColor(Color.App.textPrimary)
                .padding(DesignTokens.Spacing.md)
                .background(Color.App.surface)
                .cornerRadius(DesignTokens.Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .stroke(Color.App.border, lineWidth: 1)
                )
                .accessibilityLabel("Display name")
        }
    }

    // MARK: - Info Section
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Email")
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(Color.App.textSecondary)

            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(Color.App.textTertiary)

                Text(user?.email ?? "No email")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(Color.App.textSecondary)

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.App.textTertiary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(Color.App.surface.opacity(0.5))
            .cornerRadius(DesignTokens.Radius.md)

            Text("Email cannot be changed")
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(Color.App.textTertiary)
        }
    }

    // MARK: - Actions
    private func loadPhoto(from item: PhotosPickerItem?) {
        Task {
            if let data = try? await item?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                profileImage = Image(uiImage: uiImage)
                HapticManager.shared.notification(type: .success)
            }
        }
    }

    private func saveProfile() {
        isSaving = true
        HapticManager.shared.impact(style: .medium)

        // TODO: Implement profile update with Firebase
        // Auth.auth().currentUser?.createProfileChangeRequest()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            HapticManager.shared.notification(type: .success)
            dismiss()
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
