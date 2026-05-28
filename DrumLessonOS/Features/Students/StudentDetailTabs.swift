import SwiftUI

struct StudentDetailTabs: View {
    var detail: StudentDetail

    var body: some View {
        TabView {
            SummaryTabView(detail: detail)
                .tabItem { Label("Summary", systemImage: "rectangle.grid.1x2") }
            ProgressTabView(items: detail.progressItems)
                .tabItem { Label("Progress", systemImage: "target") }
            NotesTabView(notes: detail.recentNotes)
                .tabItem { Label("Notes", systemImage: "note.text") }
        }
        .frame(minHeight: 360)
    }
}

struct SummaryTabView: View {
    var detail: StudentDetail

    var body: some View {
        WorkbenchPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Teaching Memory", subtitle: detail.lessonBrief.weakPointBrief)
                if let assignment = detail.assignment {
                    LabeledContent("Assignment", value: "\(assignment.title) · \(assignment.status.rawValue)")
                }
                if let nextPlan = detail.nextPlan {
                    LabeledContent("Next action", value: nextPlan.nextAction)
                }
                ForEach(detail.traits) { trait in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trait.label)
                            .font(.subheadline.weight(.semibold))
                        Text(trait.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.top, 12)
    }
}

struct ProgressTabView: View {
    var items: [StudentProgressItem]

    var body: some View {
        WorkbenchPanel {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.title)
                                .font(.headline)
                            Spacer()
                            StatusBadge(label: item.status.label, tint: item.currentFocus ? .accentColor : .secondary)
                        }
                        Text(item.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let tempo = item.tempoNote, !tempo.isEmpty {
                            Text(tempo)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Divider()
                }
            }
        }
        .padding(.top, 12)
    }
}

struct NotesTabView: View {
    var notes: [StudentLessonNote]

    var body: some View {
        WorkbenchPanel {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(notes) { note in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(note.lessonDate)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text(note.coveredMaterial)
                            .font(.headline)
                        Text(note.observations)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Divider()
                }
            }
        }
        .padding(.top, 12)
    }
}
