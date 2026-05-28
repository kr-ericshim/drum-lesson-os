import SwiftUI

struct StudentHeaderView: View {
    var detail: StudentDetail

    var body: some View {
        WorkbenchPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(detail.name)
                        .font(.largeTitle.bold())
                    Spacer()
                    if let focus = detail.currentFocus {
                        StatusBadge(label: focus.status.label, systemImage: "target", tint: .accentColor)
                    }
                }
                Text(detail.profileCue)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Watch: \(detail.primaryWeakPoint)")
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}
