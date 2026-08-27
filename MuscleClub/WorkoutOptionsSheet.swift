import SwiftUI

// MARK: - Workout Options Sheet
// Presented as a bottom sheet when the ··· button is tapped on the workout summary.
struct WorkoutOptionsSheet: View {
    var onResumeAndRefresh: () -> Void = {}
    var onSave: () -> Void = {}
    var onEditDuration: () -> Void = {}
    var onDelete: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Top breathing room (matches the visual gap in the design)
            Spacer().frame(height: 48)

            optionRow(
                icon: "play.fill",
                label: "Resume and Refresh",
                color: .primary
            ) {
                dismiss()
                onResumeAndRefresh()
            }

            rowDivider()

            optionRow(
                icon: "bookmark",
                label: "Save workout",
                color: .primary
            ) {
                dismiss()
                onSave()
            }

            rowDivider()

            optionRow(
                icon: "pencil",
                label: "Edit workout duration",
                color: .primary
            ) {
                dismiss()
                onEditDuration()
            }

            rowDivider()

            optionRow(
                icon: "trash.fill",
                label: "Delete",
                color: .appAccent
            ) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                dismiss()
                onDelete()
            }

            Spacer()
        }
    }

    // MARK: - Row

    private func optionRow(icon: String, label: String, color: Color,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color)
                    .frame(width: 22, alignment: .center)

                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                Spacer()
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func rowDivider() -> some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 26 + 22 + 18) // align with label text
    }
}

#Preview {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            WorkoutOptionsSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(red: 0.08, green: 0.05, blue: 0.12))
        }
}
