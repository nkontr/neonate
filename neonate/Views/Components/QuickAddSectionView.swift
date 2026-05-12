import SwiftUI

struct QuickAddSectionView: View {
    @Binding var showingAddFeeding: Bool
    @Binding var showingAddSleep: Bool
    @Binding var showingAddDiaper: Bool
    @Binding var showingSleepTimer: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "dashboard_quick_add"))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 12) {
                QuickActionButton(
                    title: String(localized: "event_feeding"),
                    icon: "fork.knife.circle.fill",
                    color: .green
                ) {
                    showingAddFeeding = true
                }

                Menu {
                    Button {
                        showingSleepTimer = true
                    } label: {
                        Label(String(localized: "sleep_timer"), systemImage: "timer")
                    }

                    Button {
                        showingAddSleep = true
                    } label: {
                        Label(String(localized: "sleep_manual_entry"), systemImage: "pencil")
                    }
                } label: {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.indigo.opacity(0.3), Color.indigo.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .shadow(color: Color.indigo.opacity(0.3), radius: 8, x: 0, y: 4)

                            Image(systemName: "moon.zzz.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.indigo, Color.indigo.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        Text(String(localized: "event_sleep"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .liquidGlassCard(backgroundColor: .indigo, cornerRadius: 18)
                }

                QuickActionButton(
                    title: String(localized: "event_diaper"),
                    icon: "drop.fill",
                    color: .blue
                ) {
                    showingAddDiaper = true
                }
            }
        }
    }
}
