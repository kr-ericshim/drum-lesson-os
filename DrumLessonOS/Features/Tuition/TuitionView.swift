import Accessibility
import SwiftUI

struct TuitionView: View {
    @Bindable var viewModel: TuitionViewModel
    @State private var editor: TuitionEditorRequest?

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 900

            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                WorkbenchHeader(
                    title: "수강비 관리",
                    subtitle: "활성 학생의 4회 단위 수강 회차와 선결제 입금을 확인합니다."
                ) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Label("새로고침", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading || viewModel.isPerformingAction)
                    .help("수강비 현황 새로고침")
                    .accessibilityLabel("수강비 현황 새로고침")
                }

                summaryGrid(isCompact: isCompact)
                feedback
                rosterContent(
                    isCompact: isCompact,
                    wideTableHeight: max(150, proxy.size.height - 210)
                )
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, AppTheme.Spacing.xxl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(AppTheme.workspaceBackground)
        .navigationTitle("수강비")
        .task {
            await viewModel.load()
        }
        .sheet(item: $editor) {
            TuitionEditorSheet(request: $0, viewModel: viewModel)
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message { AccessibilityNotification.Announcement(message).post() }
        }
        .onChange(of: viewModel.successMessage) { _, message in
            if let message { AccessibilityNotification.Announcement(message).post() }
        }
    }

    private func summaryGrid(isCompact: Bool) -> some View {
        let metrics = [
            ("활성 학생", "\(viewModel.roster.count)명", "person.2"),
            ("설정 필요", "\(viewModel.setupNeededCount)명", "slider.horizontal.3"),
            ("입금 확인 필요", "\(viewModel.outstandingStudentCount)명", "banknote"),
            ("다음 4회 대기", "\(viewModel.readyForNextCycleCount)명", "arrow.forward.circle")
        ]

        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(minimum: 110)), count: isCompact ? 2 : 4),
            spacing: AppTheme.Spacing.md
        ) {
            ForEach(metrics, id: \.0) { metric in
                WorkbenchSurface(.quiet, padding: AppTheme.Spacing.md) {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: metric.2)
                            .font(.title3)
                            .foregroundStyle(AppTheme.Accent.teachingForeground)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(metric.0).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            Text(metric.1).font(.title3.monospacedDigit().weight(.semibold))
                        }
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    @ViewBuilder
    private var feedback: some View {
        if let message = viewModel.errorMessage {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(AppTheme.Semantic.error)
                .accessibilityLabel("수강비 오류: \(message)")
        } else if let message = viewModel.successMessage {
            Label(message, systemImage: "checkmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(AppTheme.Semantic.success)
                .accessibilityLabel("수강비 저장 완료: \(message)")
        }
    }

    @ViewBuilder
    private func rosterContent(isCompact: Bool, wideTableHeight: CGFloat) -> some View {
        if viewModel.isLoading && !viewModel.hasLoaded {
            ProgressView("수강비 현황을 불러오는 중…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.roster.isEmpty {
            ContentUnavailableView {
                Label("활성 학생이 없습니다", systemImage: "person.2")
            } description: {
                Text(viewModel.errorMessage ?? "학생을 추가하면 4회 수강 회차를 관리할 수 있습니다.")
            } actions: {
                Button("다시 불러오기") { Task { await viewModel.load() } }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if isCompact {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.md) {
                    ForEach(viewModel.roster) { item in
                        TuitionCompactRow(
                            item: item,
                            isDisabled: viewModel.isPerformingAction,
                            present: { editor = $0 }
                        )
                    }
                }
            }
        } else {
            TuitionWideTable(
                items: viewModel.roster,
                isDisabled: viewModel.isPerformingAction,
                maxHeight: wideTableHeight,
                present: { editor = $0 }
            )
        }
    }
}

private enum TuitionEditorKind: String {
    case setup
    case progress
    case payment
    case nextCycle

    var showsProgress: Bool { self == .setup || self == .progress }
    var showsPayment: Bool { self != .progress }
}

private struct TuitionEditorRequest: Identifiable {
    let kind: TuitionEditorKind
    let item: TuitionRosterItem
    let cycle: TuitionCycle?

    var id: String {
        "\(kind.rawValue)-\(item.id.uuidString)-\(cycle?.id.uuidString ?? "new")"
    }
}

private struct TuitionWideTable: View {
    let items: [TuitionRosterItem]
    let isDisabled: Bool
    let maxHeight: CGFloat
    let present: (TuitionEditorRequest) -> Void

    var body: some View {
        WorkbenchSurface(.panel, padding: 0) {
            Table(items) {
                TableColumn("학생") { Text($0.studentName).fontWeight(.medium).lineLimit(1) }
                    .width(min: 110, ideal: 150)
                TableColumn("현재 회차") { TuitionStatusCell(item: $0, field: .cycle) }
                    .width(min: 105, ideal: 120)
                TableColumn("다음 레슨") { TuitionStatusCell(item: $0, field: .nextLesson) }
                    .width(min: 105, ideal: 125)
                TableColumn("현재 선결제") { TuitionStatusCell(item: $0, field: .payment) }
                    .width(min: 140, ideal: 160)
                TableColumn("가장 오래된 미입금") { TuitionStatusCell(item: $0, field: .outstanding) }
                    .width(min: 145, ideal: 170)
                TableColumn("관리") { item in
                    TuitionManagementMenu(item: item, isDisabled: isDisabled, present: present)
                }
                .width(min: 90, ideal: 105, max: 120)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: min(maxHeight, min(520, max(150, 42 + CGFloat(items.count) * 38))))
    }
}

private struct TuitionCompactRow: View {
    let item: TuitionRosterItem
    let isDisabled: Bool
    let present: (TuitionEditorRequest) -> Void

    var body: some View {
        WorkbenchSurface(.panel, padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text(item.studentName).font(.headline)
                    Spacer()
                    TuitionStatusCell(item: item, field: .cycle)
                }
                Divider()
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading) {
                    field("다음 레슨", .nextLesson)
                    field("현재 선결제", .payment)
                    field("가장 오래된 미입금", .outstanding)
                }
                TuitionManagementMenu(item: item, isDisabled: isDisabled, present: present)
            }
        }
    }

    private func field(_ title: String, _ field: TuitionStatusField) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TuitionStatusCell(item: item, field: field)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum TuitionStatusField {
    case cycle
    case nextLesson
    case payment
    case outstanding
}

private struct TuitionStatusCell: View {
    let item: TuitionRosterItem
    let field: TuitionStatusField

    @ViewBuilder
    var body: some View {
        switch field {
        case .cycle:
            if let cycle = item.currentCycle {
                StatusBadge(
                    label: "\(cycle.completedLessonCount)/\(cycle.targetLessonCount)",
                    systemImage: cycle.isComplete ? "checkmark.circle.fill" : "number.circle",
                    tint: cycle.isComplete ? AppTheme.Semantic.success : AppTheme.Accent.teachingForeground
                )
                .accessibilityLabel("현재 회차 \(cycle.completedLessonCount)/\(cycle.targetLessonCount)")
            } else {
                StatusBadge(label: "설정 필요", systemImage: "exclamationmark.circle", tint: AppTheme.Semantic.warning)
            }
        case .nextLesson:
            Text(nextLessonLabel).lineLimit(2)
                .foregroundStyle(item.currentCycle == nil ? .secondary : .primary)
        case .payment:
            if let cycle = item.currentCycle, let date = cycle.paymentConfirmedOn {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    StatusBadge(label: "선결제 확인", systemImage: "checkmark.circle.fill", tint: AppTheme.Semantic.success)
                    Text(LessonDateFormatters.displayDate(date)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            } else if item.currentCycle != nil {
                StatusBadge(label: "선결제 미확인", systemImage: "exclamationmark.circle", tint: AppTheme.Semantic.warning)
            } else {
                Text("설정 후 확인").foregroundStyle(.secondary)
            }
        case .outstanding:
            if let cycle = item.oldestOutstandingCycle {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(cycleLabel(cycle)).fontWeight(.medium).foregroundStyle(AppTheme.Semantic.warning)
                    Text("\(cycle.completedLessonCount)/\(cycle.targetLessonCount) 진행")
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            } else if item.currentCycle == nil {
                Label("설정 후 확인", systemImage: "questionmark.circle")
                    .foregroundStyle(.secondary)
            } else {
                Label("없음", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var nextLessonLabel: String {
        guard let cycle = item.currentCycle else { return "설정 후 계산" }
        return cycle.nextLessonNumber.map { "\($0)회차 예정" } ?? "다음 4회 시작 대기"
    }
}

private struct TuitionManagementMenu: View {
    let item: TuitionRosterItem
    let isDisabled: Bool
    let present: (TuitionEditorRequest) -> Void

    var body: some View {
        Menu {
            if let cycle = item.currentCycle {
                Button("완료 회차 수정", systemImage: "pencil") {
                    present(.init(kind: .progress, item: item, cycle: cycle))
                }

                Menu("입금 기록 관리", systemImage: "banknote") {
                    ForEach(Array(item.cycles.reversed())) { paymentCycle in
                        Button {
                            present(.init(kind: .payment, item: item, cycle: paymentCycle))
                        } label: {
                            Label(
                                "\(cycleLabel(paymentCycle)) · \(paymentCycle.isPaymentConfirmed ? "확인됨" : "미확인")",
                                systemImage: paymentCycle.isPaymentConfirmed ? "checkmark.circle" : "exclamationmark.circle"
                            )
                        }
                    }
                }
                if cycle.isComplete {
                    Divider()
                    Button("다음 4회 시작", systemImage: "arrow.forward.circle") {
                        present(.init(kind: .nextCycle, item: item, cycle: cycle))
                    }
                }
            } else {
                Button("현재 회차 설정", systemImage: "slider.horizontal.3") {
                    present(.init(kind: .setup, item: item, cycle: nil))
                }
            }
        } label: {
            Label(item.currentCycle == nil ? "설정" : "관리", systemImage: "ellipsis.circle")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .disabled(isDisabled)
        .help("\(item.studentName) 학생 수강비 관리")
        .accessibilityLabel("\(item.studentName) 학생 수강비 관리")
    }
}

private struct TuitionEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let request: TuitionEditorRequest
    @Bindable var viewModel: TuitionViewModel
    @State private var completedLessonCount: Int
    @State private var isPaymentConfirmed: Bool
    @State private var paymentDate: Date

    init(request: TuitionEditorRequest, viewModel: TuitionViewModel) {
        self.request = request
        self.viewModel = viewModel
        _completedLessonCount = State(initialValue: request.cycle?.completedLessonCount ?? 0)
        _isPaymentConfirmed = State(initialValue: request.kind == .nextCycle || request.cycle?.isPaymentConfirmed == true)
        _paymentDate = State(initialValue: TuitionDateSupport.date(from: request.cycle?.paymentConfirmedOn) ?? Date())
    }

    var body: some View {
        CompactModalSurface(width: 440) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                WorkbenchHeader(title: title, subtitle: subtitle)
                CompactModalPanel {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        if request.kind == .nextCycle {
                            CompactModalSummary(
                                title: "새 수강 주기",
                                value: "0/\(TuitionValidation.targetLessonCount)",
                                systemImage: "number.circle"
                            )
                        }
                        if request.kind.showsProgress {
                            CompactModalField("완료한 레슨", detail: "레슨 마무리 저장 후에는 자동으로 올라갑니다.") {
                                Picker("완료한 레슨", selection: $completedLessonCount) {
                                    ForEach(0...TuitionValidation.targetLessonCount, id: \.self) {
                                        Text("\($0)/\(TuitionValidation.targetLessonCount)").tag($0)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                                .accessibilityLabel("현재 완료 회차")
                            }
                        }
                        if request.kind.showsPayment {
                            Toggle(toggleTitle, isOn: $isPaymentConfirmed)
                                .accessibilityHint(toggleHint)
                            if isPaymentConfirmed {
                                CompactModalField("입금 확인일") {
                                    DatePicker("입금 확인일", selection: $paymentDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .accessibilityLabel("입금 확인일")
                                }
                            } else if request.kind == .payment || request.kind == .nextCycle {
                                Text(uncheckedMessage).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if let message = viewModel.errorMessage { CompactModalError(message: message) }
                CompactModalActions(
                    cancelTitle: "취소",
                    confirmTitle: confirmTitle,
                    confirmSystemImage: request.kind == .nextCycle ? "arrow.forward.circle" : "checkmark",
                    workingTitle: "저장 중",
                    isWorking: viewModel.actionStudentId == request.item.studentId,
                    isConfirmDisabled: viewModel.isPerformingAction,
                    onCancel: { dismiss() },
                    onConfirm: save
                )
            }
        }
    }

    private var title: String {
        switch request.kind {
        case .setup: "현재 회차 설정"
        case .progress: "완료 회차 수정"
        case .payment: "입금 확인 관리"
        case .nextCycle: "다음 4회 시작"
        }
    }

    private var subtitle: String {
        guard let cycle = request.cycle else { return "\(request.item.studentName) · 4회 수강 주기" }
        return request.kind == .payment
            ? "\(request.item.studentName) · \(cycleLabel(cycle))"
            : "\(request.item.studentName) · 현재 \(cycle.completedLessonCount)/\(cycle.targetLessonCount)"
    }

    private var confirmTitle: String {
        switch request.kind {
        case .setup: "설정 저장"
        case .progress: "회차 저장"
        case .payment: "입금 상태 저장"
        case .nextCycle: "다음 4회 시작"
        }
    }

    private var toggleTitle: String {
        request.kind == .nextCycle ? "새 4회 선결제 확인" : "선결제 입금 확인"
    }

    private var toggleHint: String {
        request.kind == .nextCycle
            ? "기본값은 오늘 선결제 완료이며, 끄면 미입금으로 시작합니다."
            : "끄고 저장하면 입금 확인 상태가 취소됩니다."
    }

    private var uncheckedMessage: String {
        request.kind == .nextCycle ? "새 4회가 입금 미확인 상태로 시작됩니다." : "입금 미확인 상태로 저장됩니다."
    }

    private func save() {
        Task {
            let item = request.item
            let confirmedOn = isPaymentConfirmed ? TuitionDateSupport.storageString(from: paymentDate) : nil
            let succeeded: Bool
            switch request.kind {
            case .setup:
                succeeded = await viewModel.configureCycle(
                    studentId: item.studentId,
                    completedLessonCount: completedLessonCount,
                    paymentConfirmedOn: confirmedOn
                )
            case .progress:
                guard let cycle = request.cycle else { return }
                succeeded = await viewModel.correctProgress(
                    cycleId: cycle.id,
                    studentId: item.studentId,
                    completedLessonCount: completedLessonCount
                )
            case .payment:
                guard let cycle = request.cycle else { return }
                succeeded = await viewModel.setPaymentConfirmation(
                    cycleId: cycle.id,
                    studentId: item.studentId,
                    confirmedOn: confirmedOn
                )
            case .nextCycle:
                guard let cycle = request.cycle else { return }
                succeeded = await viewModel.startNextCycle(
                    studentId: item.studentId,
                    currentCycleId: cycle.id,
                    paymentConfirmedOn: confirmedOn
                )
            }
            if succeeded { dismiss() }
        }
    }
}

private func cycleLabel(_ cycle: TuitionCycle) -> String {
    "\(cycle.sequence)번째 4회"
}

private enum TuitionDateSupport {
    static func storageString(from date: Date) -> String { formatter.string(from: date) }
    static func date(from value: String?) -> Date? { value.flatMap(formatter.date) }

    private static var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }
}
