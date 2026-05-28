import SwiftUI

struct LessonFlowWorkspace: View {
    @Bindable var viewModel: StudentDetailViewModel
    var detail: StudentDetail
    var lessonContext: CalendarLessonEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let lessonContext {
                LessonContextBanner(event: lessonContext)
            }

            HStack(alignment: .top, spacing: 16) {
                LessonBriefView(brief: detail.lessonBrief)
                LessonRunPanelView(viewModel: viewModel)
                LessonCloseoutView(viewModel: viewModel)
            }
        }
    }
}

private struct LessonContextBanner: View {
    var event: CalendarLessonEvent

    var body: some View {
        WorkbenchPanel {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Label(event.timeLabel, systemImage: "calendar.badge.clock")
                    .font(.headline)
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                StatusBadge(label: event.syncStatus.label, tint: event.syncStatus == .failed ? .red : .accentColor)
            }
            Text("Occurrence \(event.id.uuidString.lowercased().prefix(8))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct LessonBriefView: View {
    var brief: LessonBrief

    var body: some View {
        WorkbenchPanel {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "First Check", subtitle: brief.weakPointBrief)
                Text(brief.firstCheck)
                    .font(.title3.weight(.semibold))
                    .lineLimit(3)
                if let assignmentCue = brief.assignmentCue {
                    StatusBadge(label: assignmentCue, systemImage: "checklist", tint: .orange)
                }
                if let observation = brief.recentObservation {
                    Text(observation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }
            }
        }
    }
}

struct LessonRunPanelView: View {
    @Bindable var viewModel: StudentDetailViewModel

    var body: some View {
        WorkbenchPanel {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Run Notes", subtitle: "Session-local until closeout")
                TextField("Covered", text: $viewModel.runCovered, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                TextField("Observation", text: $viewModel.runObservation, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                TextField("Practice", text: $viewModel.runPractice, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                TextField("Next hint", text: $viewModel.runNextHint, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Button {
                    viewModel.useRunNotesInCloseout()
                } label: {
                    Label("Use in Closeout", systemImage: "arrow.down.doc")
                }
            }
        }
    }
}

struct LessonCloseoutView: View {
    @Bindable var viewModel: StudentDetailViewModel

    var body: some View {
        WorkbenchPanel {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Closeout", subtitle: "Durable teaching record")
                if let draft = viewModel.closeoutDraft {
                    Text(draft.coveredMaterial)
                        .font(.headline)
                    Text(draft.observations)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Next: \(draft.nextStepHint)")
                        .font(.subheadline.weight(.semibold))
                    Button {
                        Task { await viewModel.saveCloseout() }
                    } label: {
                        Label("Save Closeout", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text("Use run notes when the lesson is ready to close.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
