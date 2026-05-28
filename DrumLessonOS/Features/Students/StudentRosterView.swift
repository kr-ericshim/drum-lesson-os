import SwiftUI

struct StudentRosterView: View {
    @Environment(AppEnvironment.self) private var environment
    var roster: [StudentRosterItem]
    @State private var showingAddStudentSheet = false

    var body: some View {
        WorkbenchPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    SectionHeader(title: "Students", subtitle: "Active roster")
                    Spacer()
                    Button {
                        showingAddStudentSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .help("Add student")
                    .accessibilityLabel("Add student")
                }

                ForEach(roster) { student in
                    StudentRosterRow(student: student)
                }
                if roster.isEmpty {
                    ContentUnavailableView("No active students", systemImage: "person.2")
                }
            }
        }
        .sheet(isPresented: $showingAddStudentSheet) {
            AddStudentSheet(writes: environment.writes) { studentId in
                await environment.refresh()
                environment.route = .student(studentId)
            }
        }
    }
}

private struct StudentRosterRow: View {
    @Environment(AppEnvironment.self) private var environment
    var student: StudentRosterItem

    var body: some View {
        Button {
            environment.route = .student(student.id)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(student.name)
                        .font(.headline)
                    Spacer()
                    if let status = student.assignmentStatus {
                        StatusBadge(label: status.rawValue.replacingOccurrences(of: "_", with: " "), tint: status == .needsReview ? .orange : .secondary)
                    }
                }
                Text(student.currentFocus?.title ?? student.primaryWeakPoint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(student.name)")
    }
}
