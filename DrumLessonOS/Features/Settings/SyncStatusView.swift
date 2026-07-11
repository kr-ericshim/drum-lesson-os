import Accessibility
import Observation
import SwiftUI

@MainActor
@Observable
final class SyncStatusViewModel {
    var queue: LocalWriteQueue
    var retry: RetryScheduler
    var schedules: ScheduleRepository?
    var lastMessage: String?
    var isRetrying = false

    init(queue: LocalWriteQueue, retry: RetryScheduler, schedules: ScheduleRepository? = nil) {
        self.queue = queue
        self.retry = retry
        self.schedules = schedules
    }

    func refresh() {
        lastMessage = queue.hasPendingWrites ? "대기 중인 작업 \(queue.writes.count)개" : "로컬 작업이 모두 처리됐습니다."
    }

    func retryNow() async {
        guard !isRetrying else { return }
        isRetrying = true
        lastMessage = "동기화를 다시 시도하는 중…"
        defer { isRetrying = false }

        var attemptedOccurrences: Set<EntityID> = []
        await retry.retryNow { [schedules] write in
            guard write.kind == .calendar else {
                throw RepositoryError(message: "지원하지 않는 동기화 대기 작업입니다.")
            }
            guard let occurrenceId = write.recordId else {
                throw RepositoryError(message: "동기화 대기 작업에 일정 식별자가 없습니다.")
            }
            guard let schedules else {
                throw RepositoryError(message: "캘린더 동기화 저장소를 사용할 수 없습니다.")
            }
            guard attemptedOccurrences.insert(occurrenceId).inserted else {
                throw RepositoryError(message: "같은 일정의 앞선 동기화 작업을 먼저 완료해야 합니다.")
            }
            try await schedules.retryNativeCalendarSync(occurrenceId: occurrenceId)
        }
        refresh()
    }
}

struct SyncStatusView: View {
    @Bindable var viewModel: SyncStatusViewModel

    var body: some View {
        WorkbenchSurface(.panel, padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "동기화 대기열", subtitle: viewModel.lastMessage)
                if viewModel.queue.writes.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Label("동기화할 일정이 없습니다", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.Semantic.success)
                        Text("새 일정은 선택한 Apple 캘린더와 자동으로 동기화됩니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                } else {
                    ForEach(viewModel.queue.writes) { write in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(write.kind.label) · \(write.operationLabel)")
                                .font(.subheadline.weight(.semibold))
                            Text(write.payloadSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let error = write.lastError {
                                Label(error, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.Semantic.error)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(AppTheme.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.055), in: AppTheme.softPanel)
                    }
                }
                Button {
                    Task { await viewModel.retryNow() }
                } label: {
                    if viewModel.isRetrying {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            ProgressView()
                                .controlSize(.small)
                            Text("다시 시도하는 중…")
                        }
                    } else {
                        Label("지금 재시도", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .disabled(viewModel.isRetrying || !viewModel.queue.hasPendingWrites)
                .help(viewModel.queue.hasPendingWrites ? "대기 중인 캘린더 동기화를 다시 시도합니다." : "현재 대기 중인 동기화가 없습니다.")
                .accessibilityLabel(viewModel.isRetrying ? "동기화 재시도 중" : "동기화 지금 재시도")
            }
        }
        .onAppear { viewModel.refresh() }
        .onChange(of: viewModel.lastMessage) { _, message in
            guard let message else { return }
            AccessibilityNotification.Announcement(message).post()
        }
    }
}
