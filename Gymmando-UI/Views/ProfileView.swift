import SwiftUI
import FirebaseAuth
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditProfile = false
    @State private var showAchievements = false
    @State private var showAllSessions = false

    // Real stats from AppStorage
    @AppStorage("totalSessionCount") private var totalSessionCount = 0
    @AppStorage("totalMinutes") private var totalMinutes = 0
    @AppStorage("currentStreak") private var currentStreak = 0
    @AppStorage("hasCompletedFirstSession") private var hasCompletedFirstSession = false
    @AppStorage("longestStreak") private var longestStreak = 0

    // Computed achievements count
    private var unlockedAchievements: Int {
        var count = 0
        if hasCompletedFirstSession { count += 1 }
        if totalSessionCount >= 5 { count += 1 }
        if totalSessionCount >= 10 { count += 1 }
        if totalSessionCount >= 25 { count += 1 }
        if currentStreak >= 3 { count += 1 }
        if currentStreak >= 7 { count += 1 }
        if totalMinutes >= 60 { count += 1 }
        if totalMinutes >= 300 { count += 1 }
        return count
    }

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
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
            }
            .sheet(isPresented: $showAllSessions) {
                SessionHistoryDetailView()
            }
            .trackScreen("Profile")
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Avatar with level badge
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

                // Level badge
                if totalSessionCount > 0 {
                    LevelBadge(level: userLevel)
                        .offset(x: 40, y: 40)
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

                    // Level info
                    if totalSessionCount > 0 {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Text("Level \(userLevel)")
                                .font(DesignTokens.Typography.labelMedium)
                                .foregroundColor(Color.App.primary)

                            Text("•")
                                .foregroundColor(Color.App.textTertiary)

                            Text(levelTitle)
                                .font(DesignTokens.Typography.labelMedium)
                                .foregroundColor(Color.App.textSecondary)
                        }
                        .padding(.top, DesignTokens.Spacing.xxs)
                    }
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

    // User level based on sessions
    private var userLevel: Int {
        switch totalSessionCount {
        case 0: return 1
        case 1...4: return 1
        case 5...14: return 2
        case 15...29: return 3
        case 30...49: return 4
        case 50...99: return 5
        default: return 6
        }
    }

    private var levelTitle: String {
        switch userLevel {
        case 1: return "Beginner"
        case 2: return "Regular"
        case 3: return "Committed"
        case 4: return "Dedicated"
        case 5: return "Expert"
        default: return "Master"
        }
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
                    value: "\(totalSessionCount)",
                    title: "Total Sessions",
                    icon: "waveform",
                    color: .cyan
                )

                ProfileStatCard(
                    value: formatMinutes(totalMinutes),
                    title: "Total Time",
                    icon: "clock.fill",
                    color: .purple
                )
            }

            HStack(spacing: DesignTokens.Spacing.md) {
                ProfileStatCard(
                    value: "\(currentStreak)",
                    title: "Day Streak",
                    icon: "flame.fill",
                    color: .orange
                )

                ProfileStatCard(
                    value: "\(unlockedAchievements)",
                    title: "Achievements",
                    icon: "trophy.fill",
                    color: .yellow
                )
            }
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
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
                    showAchievements = true
                    HapticManager.shared.impact(style: .light)
                }
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(Color.App.primary)
            }

            if hasCompletedFirstSession {
                // Show recent achievements
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        AchievementBadge(
                            icon: "star.fill",
                            title: "Getting Started",
                            isUnlocked: hasCompletedFirstSession,
                            size: 70
                        )

                        AchievementBadge(
                            icon: "flame.fill",
                            title: "3-Day Streak",
                            isUnlocked: currentStreak >= 3,
                            size: 70
                        )

                        AchievementBadge(
                            icon: "5.circle.fill",
                            title: "High Five",
                            isUnlocked: totalSessionCount >= 5,
                            size: 70
                        )

                        AchievementBadge(
                            icon: "clock.fill",
                            title: "Hour Power",
                            isUnlocked: totalMinutes >= 60,
                            size: 70
                        )
                    }
                    .padding(.horizontal, 2)
                }
            } else {
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

                if totalSessionCount > 0 {
                    Button("See All") {
                        showAllSessions = true
                        HapticManager.shared.impact(style: .light)
                    }
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(Color.App.primary)
                }
            }

            if totalSessionCount > 0 {
                // Show mini calendar week view
                WeekCalendarView()
            } else {
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
}

// MARK: - Level Badge
struct LevelBadge: View {
    let level: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.App.backgroundElevated)
                .frame(width: 28, height: 28)

            Circle()
                .fill(
                    LinearGradient(
                        colors: levelColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 24, height: 24)

            Text("\(level)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private var levelColors: [Color] {
        switch level {
        case 1: return [.gray, .gray.opacity(0.7)]
        case 2: return [.green, .green.opacity(0.7)]
        case 3: return [.blue, .cyan]
        case 4: return [.purple, .pink]
        case 5: return [.orange, .yellow]
        default: return [.yellow, .orange]
        }
    }
}

// MARK: - Week Calendar View
struct WeekCalendarView: View {
    @AppStorage("lastSessionDate") private var lastSessionDate: Double = 0
    @AppStorage("todaySessions") private var todaySessions = 0

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(weekDays, id: \.self) { date in
                    WeekDayCell(date: date, hasSession: hasSession(on: date))
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color.App.surface)
        .cornerRadius(DesignTokens.Radius.lg)
    }

    private var weekDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (-6...0).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }

    private func hasSession(on date: Date) -> Bool {
        let calendar = Calendar.current
        let lastSession = Date(timeIntervalSince1970: lastSessionDate)

        // Check if the date matches today and we have sessions
        if calendar.isDate(date, inSameDayAs: Date()) && todaySessions > 0 {
            return true
        }

        // Check if date matches last session date
        if calendar.isDate(date, inSameDayAs: lastSession) {
            return true
        }

        return false
    }
}

struct WeekDayCell: View {
    let date: Date
    let hasSession: Bool

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxs) {
            Text(dayName)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(Color.App.textTertiary)

            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)

                if hasSession {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text(dayNumber)
                        .font(DesignTokens.Typography.labelMedium)
                        .foregroundColor(isToday ? Color.App.primary : Color.App.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var backgroundColor: Color {
        if hasSession {
            return Color.App.success
        } else if isToday {
            return Color.App.primary.opacity(0.15)
        } else {
            return Color.App.backgroundSecondary
        }
    }
}

// MARK: - Achievements View
struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("totalSessionCount") private var totalSessionCount = 0
    @AppStorage("totalMinutes") private var totalMinutes = 0
    @AppStorage("currentStreak") private var currentStreak = 0
    @AppStorage("longestStreak") private var longestStreak = 0
    @AppStorage("hasCompletedFirstSession") private var hasCompletedFirstSession = false

    private var achievements: [Achievement] {
        [
            Achievement(icon: "star.fill", title: "Getting Started", description: "Complete your first session", isUnlocked: hasCompletedFirstSession, color: .yellow),
            Achievement(icon: "5.circle.fill", title: "High Five", description: "Complete 5 sessions", isUnlocked: totalSessionCount >= 5, color: .cyan),
            Achievement(icon: "10.circle.fill", title: "Perfect 10", description: "Complete 10 sessions", isUnlocked: totalSessionCount >= 10, color: .green),
            Achievement(icon: "25.circle.fill", title: "Quarter Century", description: "Complete 25 sessions", isUnlocked: totalSessionCount >= 25, color: .purple),
            Achievement(icon: "flame.fill", title: "3-Day Streak", description: "Maintain a 3-day streak", isUnlocked: currentStreak >= 3 || longestStreak >= 3, color: .orange),
            Achievement(icon: "flame.fill", title: "Week Warrior", description: "Maintain a 7-day streak", isUnlocked: currentStreak >= 7 || longestStreak >= 7, color: .red),
            Achievement(icon: "clock.fill", title: "Hour Power", description: "Train for 60 total minutes", isUnlocked: totalMinutes >= 60, color: .blue),
            Achievement(icon: "clock.badge.checkmark.fill", title: "Time Master", description: "Train for 5 total hours", isUnlocked: totalMinutes >= 300, color: .indigo)
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.App.background.ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.md) {
                        ForEach(achievements) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                    .padding(DesignTokens.Spacing.lg)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.App.primary)
                }
            }
        }
    }
}

struct Achievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let isUnlocked: Bool
    let color: Color
}

struct AchievementCard: View {
    let achievement: Achievement
    @State private var showGlow = false

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                if achievement.isUnlocked && showGlow {
                    Circle()
                        .fill(achievement.color.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .blur(radius: 10)
                }

                Circle()
                    .fill(
                        achievement.isUnlocked
                            ? LinearGradient(colors: [achievement.color, achievement.color.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color.App.surface, Color.App.backgroundSecondary], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: achievement.icon)
                    .font(.system(size: 28))
                    .foregroundColor(achievement.isUnlocked ? .white : Color.App.textTertiary)
            }

            Text(achievement.title)
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(achievement.isUnlocked ? Color.App.textPrimary : Color.App.textTertiary)
                .multilineTextAlignment(.center)

            Text(achievement.description)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(Color.App.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if !achievement.isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.App.textTertiary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.App.surface)
        .cornerRadius(DesignTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .stroke(achievement.isUnlocked ? achievement.color.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .onAppear {
            if achievement.isUnlocked {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    showGlow = true
                }
            }
        }
    }
}

// MARK: - Session History Detail View
struct SessionHistoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("totalSessionCount") private var totalSessionCount = 0
    @AppStorage("totalMinutes") private var totalMinutes = 0
    @State private var selectedMonth = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.App.background.ignoresSafeArea()

                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Month selector
                    HStack {
                        Button {
                            withAnimation {
                                selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                            }
                            HapticManager.shared.impact(style: .light)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.App.primary)
                        }

                        Spacer()

                        Text(monthYearString)
                            .font(DesignTokens.Typography.titleMedium)
                            .foregroundColor(Color.App.textPrimary)

                        Spacer()

                        Button {
                            withAnimation {
                                selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                            }
                            HapticManager.shared.impact(style: .light)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(canGoForward ? Color.App.primary : Color.App.textTertiary)
                        }
                        .disabled(!canGoForward)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)

                    // Calendar grid
                    CalendarGridView(month: selectedMonth)
                        .padding(.horizontal, DesignTokens.Spacing.md)

                    // Summary
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Text("All Time Stats")
                            .font(DesignTokens.Typography.titleSmall)
                            .foregroundColor(Color.App.textSecondary)

                        HStack(spacing: DesignTokens.Spacing.xl) {
                            VStack {
                                Text("\(totalSessionCount)")
                                    .font(DesignTokens.Typography.headlineLarge)
                                    .foregroundColor(Color.App.textPrimary)
                                Text("Sessions")
                                    .font(DesignTokens.Typography.labelSmall)
                                    .foregroundColor(Color.App.textSecondary)
                            }

                            Divider()
                                .frame(height: 40)

                            VStack {
                                Text(formatHoursMinutes(totalMinutes))
                                    .font(DesignTokens.Typography.headlineLarge)
                                    .foregroundColor(Color.App.textPrimary)
                                Text("Total Time")
                                    .font(DesignTokens.Typography.labelSmall)
                                    .foregroundColor(Color.App.textSecondary)
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .frame(maxWidth: .infinity)
                    .background(Color.App.surface)
                    .cornerRadius(DesignTokens.Radius.lg)
                    .padding(.horizontal, DesignTokens.Spacing.lg)

                    Spacer()
                }
                .padding(.top, DesignTokens.Spacing.lg)
            }
            .navigationTitle("Session History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.App.primary)
                }
            }
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private var canGoForward: Bool {
        let calendar = Calendar.current
        return calendar.compare(selectedMonth, to: Date(), toGranularity: .month) == .orderedAscending
    }

    private func formatHoursMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Calendar Grid View
struct CalendarGridView: View {
    let month: Date
    @AppStorage("lastSessionDate") private var lastSessionDate: Double = 0

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekDaySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Week day headers
            HStack {
                ForEach(weekDaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(Color.App.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar days
            LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.sm) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(date: date, hasSession: hasSession(on: date))
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color.App.surface)
        .cornerRadius(DesignTokens.Radius.lg)
    }

    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!

        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    private func hasSession(on date: Date) -> Bool {
        let calendar = Calendar.current
        let lastSession = Date(timeIntervalSince1970: lastSessionDate)
        return calendar.isDate(date, inSameDayAs: lastSession)
    }
}

struct CalendarDayCell: View {
    let date: Date
    let hasSession: Bool

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var isFuture: Bool {
        date > Date()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 36, height: 36)

            if hasSession {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(textColor)
            }
        }
    }

    private var backgroundColor: Color {
        if hasSession {
            return Color.App.success
        } else if isToday {
            return Color.App.primary.opacity(0.15)
        } else {
            return Color.clear
        }
    }

    private var textColor: Color {
        if isFuture {
            return Color.App.textTertiary
        } else if isToday {
            return Color.App.primary
        } else {
            return Color.App.textSecondary
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
