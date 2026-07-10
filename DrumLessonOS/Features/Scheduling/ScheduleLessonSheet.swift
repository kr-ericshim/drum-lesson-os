import Accessibility
import SwiftUI

struct CompactModalSurface<Content: View>: View {
    var width: CGFloat
    let content: Content

    init(width: CGFloat, @ViewBuilder content: () -> Content) {
        self.width = width
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppTheme.Spacing.xxl)
            .frame(width: width, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct CompactModalPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        WorkbenchSurface(.panel, padding: AppTheme.Spacing.lg) {
            content
        }
    }
}

struct CompactModalField<Content: View>: View {
    var title: String
    var detail: String?
    let content: Content

    init(_ title: String, detail: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.detail = detail
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CompactModalSummary: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.md) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: AppTheme.Spacing.md)
            Text(value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

struct CompactModalError: View {
    var message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundStyle(AppTheme.Semantic.error)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("오류")
            .accessibilityValue(message)
    }
}

struct CompactModalActions: View {
    var cancelTitle: String
    var confirmTitle: String
    var confirmSystemImage: String
    var workingTitle: String
    var isWorking: Bool
    var isConfirmDisabled: Bool
    var onCancel: () -> Void
    var onConfirm: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Spacer(minLength: 0)
            Button(cancelTitle, role: .cancel, action: onCancel)
                .keyboardShortcut(.cancelAction)
                .disabled(isWorking)

            Button(action: onConfirm) {
                if isWorking {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ProgressView()
                            .controlSize(.small)
                        Text(workingTitle)
                    }
                } else {
                    Label(confirmTitle, systemImage: confirmSystemImage)
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(isConfirmDisabled)
            .accessibilityLabel(isWorking ? workingTitle : confirmTitle)
            .accessibilityValue(isWorking ? "진행 중" : "")
        }
    }
}

struct ScheduleLessonSheet: View {
    @Environment(\.dismiss) private var dismiss
    let repository: ScheduleRepository
    let roster: [StudentRosterItem]
    var onSaved: () async -> Void = {}

    @State private var form: ScheduleLessonFormState
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var hasSavedLocally = false
    @FocusState private var focusedField: FocusedField?

    private enum FocusedField: Hashable {
        case title
    }

    init(
        repository: ScheduleRepository,
        roster: [StudentRosterItem],
        defaultDurationMinutes: Int = 50,
        onSaved: @escaping () async -> Void = {}
    ) {
        self.repository = repository
        self.roster = roster
        self.onSaved = onSaved
        _form = State(initialValue: ScheduleLessonFormState(
            roster: roster,
            defaultDurationMinutes: defaultDurationMinutes
        ))
    }

    var body: some View {
        CompactModalSurface(width: 520) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                SectionHeader(
                    title: "레슨 추가",
                    subtitle: "학생과 시간을 정하면 앱 일정과 Apple 캘린더에 함께 반영됩니다.",
                    titleFont: .title2.weight(.semibold)
                )

                if roster.isEmpty {
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("활성 학생이 없습니다")
                            .font(.headline)
                        Text("먼저 학생을 추가한 뒤 레슨을 예약하세요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.xxl)
                } else {
                    CompactModalPanel {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                            CompactModalField("일정 방식", detail: form.mode.explanation) {
                                Picker("일정 방식", selection: $form.mode) {
                                    ForEach(ScheduleLessonMode.allCases) { mode in
                                        Text(mode.label).tag(mode)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .accessibilityLabel("일정 방식")
                            }

                            Divider()

                            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                                CompactModalField("학생") {
                                    Picker("학생", selection: $form.selectedStudentId) {
                                        ForEach(roster) { student in
                                            Text(student.name).tag(Optional(student.id))
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .accessibilityLabel("학생")
                                    .onChange(of: form.selectedStudentId) { _, studentId in
                                        form.selectStudent(studentId)
                                    }
                                }
                                .frame(width: 156)

                                CompactModalField("제목") {
                                    TextField("레슨 제목", text: Binding(
                                        get: { form.title },
                                        set: { form.updateTitle($0) }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .title)
                                    .accessibilityLabel("레슨 제목")
                                }
                            }

                            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                                CompactModalField(
                                    form.mode == .oneOff ? "시작" : "반복 시작일",
                                    detail: form.mode == .weekly ? "선택한 요일의 첫 회차는 이 날짜 이후에 만들어집니다." : nil
                                ) {
                                    DatePicker(
                                        form.mode == .oneOff ? "시작" : "반복 시작일",
                                        selection: $form.startDate,
                                        displayedComponents: [.date, .hourAndMinute]
                                    )
                                    .labelsHidden()
                                    .datePickerStyle(.field)
                                    .fixedSize()
                                    .accessibilityLabel(form.mode == .oneOff ? "시작" : "반복 시작일")
                                    .environment(\.timeZone, TimeZone(identifier: form.timezone) ?? .current)
                                }

                                CompactModalField("레슨 길이") {
                                    Stepper("\(form.durationMinutes)분", value: $form.durationMinutes, in: 15...240, step: 5)
                                        .font(.body.monospacedDigit().weight(.medium))
                                        .fixedSize()
                                        .accessibilityLabel("레슨 길이")
                                        .accessibilityValue("\(form.durationMinutes)분")
                                }
                                .frame(width: 128)
                            }

                            if form.mode == .weekly {
                                Divider()

                                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                                    CompactModalField("반복 요일") {
                                        Picker("반복 요일", selection: $form.recurrenceWeekday) {
                                            ForEach(ScheduleLessonFormState.weekdayOptions, id: \.value) { option in
                                                Text(option.label).tag(option.value)
                                            }
                                        }
                                        .labelsHidden()
                                        .pickerStyle(.menu)
                                        .fixedSize()
                                        .accessibilityLabel("반복 요일")
                                    }

                                    CompactModalField("반복 간격") {
                                        Stepper("\(form.recurrenceInterval)주마다", value: $form.recurrenceInterval, in: 1...12)
                                            .font(.body.monospacedDigit().weight(.medium))
                                            .fixedSize()
                                            .accessibilityLabel("반복 간격")
                                            .accessibilityValue("\(form.recurrenceInterval)주마다")
                                    }
                                }

                                CompactModalField("반복 종료") {
                                    HStack(spacing: AppTheme.Spacing.md) {
                                        Toggle("종료일 지정", isOn: $form.hasEndDate)
                                            .toggleStyle(.switch)
                                        Spacer(minLength: AppTheme.Spacing.sm)
                                        if form.hasEndDate {
                                            DatePicker("종료일", selection: $form.endDate, displayedComponents: .date)
                                                .labelsHidden()
                                                .datePickerStyle(.field)
                                                .fixedSize()
                                                .accessibilityLabel("반복 종료일")
                                                .environment(\.timeZone, TimeZone(identifier: form.timezone) ?? .current)
                                        }
                                    }
                                }

                                CompactModalSummary(
                                    title: "반복 요약",
                                    value: form.recurrenceSummary,
                                    systemImage: "repeat"
                                )
                            }

                            Divider()

                            CompactModalSummary(
                                title: "시간대",
                                value: form.timezoneDisplayName,
                                systemImage: "clock"
                            )
                        }
                    }
                }

                if let errorMessage {
                    CompactModalError(message: errorMessage)
                }

                CompactModalActions(
                    cancelTitle: hasSavedLocally ? "닫기" : "취소",
                    confirmTitle: saveButtonTitle,
                    confirmSystemImage: "checkmark",
                    workingTitle: "저장 중",
                    isWorking: isSaving,
                    isConfirmDisabled: roster.isEmpty || !form.canSubmit || isSaving || hasSavedLocally,
                    onCancel: { dismiss() },
                    onConfirm: { Task { await save() } }
                )
            }
        }
        .environment(\.locale, Locale(identifier: "ko_KR"))
        .interactiveDismissDisabled(isSaving)
        .onAppear {
            if !roster.isEmpty {
                focusedField = .title
            }
        }
        .onChange(of: errorMessage) { _, message in
            guard let message else { return }
            AccessibilityNotification.Announcement(message).post()
        }
    }

    private func save() async {
        guard !isSaving, !hasSavedLocally else { return }
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            let savedOccurrences: [LessonOccurrence]
            switch form.mode {
            case .oneOff:
                savedOccurrences = [try await repository.createOneOffOccurrence(form.makeOneOffInput())]
            case .weekly:
                savedOccurrences = try await repository.createWeeklySchedule(form.makeWeeklyInput())
            }
            hasSavedLocally = true
            await onSaved()
            if let syncFailure = calendarSyncFailureMessage(for: savedOccurrences) {
                errorMessage = syncFailure
                return
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var saveButtonTitle: String {
        if isSaving { return "저장 중" }
        if hasSavedLocally { return "저장됨" }
        return "저장"
    }
}

enum ScheduleLessonMode: String, CaseIterable, Identifiable {
    case oneOff
    case weekly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .oneOff: "한 번"
        case .weekly: "반복"
        }
    }

    var explanation: String {
        switch self {
        case .oneOff: "선택한 날짜에 레슨 한 번을 추가합니다."
        case .weekly: "정한 요일과 간격에 맞춰 레슨을 반복합니다."
        }
    }
}

struct ScheduleLessonFormState: Equatable {
    static let weekdayOptions = [
        (value: 0, label: "일요일"),
        (value: 1, label: "월요일"),
        (value: 2, label: "화요일"),
        (value: 3, label: "수요일"),
        (value: 4, label: "목요일"),
        (value: 5, label: "금요일"),
        (value: 6, label: "토요일")
    ]

    var roster: [StudentRosterItem]
    var mode: ScheduleLessonMode
    var selectedStudentId: EntityID?
    var title: String
    var startDate: Date
    var durationMinutes: Int
    var timezone: String
    var recurrenceInterval: Int
    var recurrenceWeekday: Int
    var hasEndDate: Bool
    var endDate: Date
    private(set) var isUsingSuggestedTitle: Bool

    var recurrenceSummary: String {
        let weekday = Self.weekdayOptions.first(where: { $0.value == recurrenceWeekday })?.label ?? "선택한 요일"
        let cadence = recurrenceInterval == 1 ? "매주" : "\(recurrenceInterval)주마다"
        let ending = hasEndDate ? "\(Self.koreanDate(endDate, timeZone: resolvedTimeZone))까지" : "종료일 없음"
        return "\(cadence) \(weekday) · \(Self.koreanDate(startDate, timeZone: resolvedTimeZone))부터 · \(ending)"
    }

    var timezoneDisplayName: String {
        Self.timezoneDisplayName(for: timezone)
    }

    var canSubmit: Bool {
        selectedStudentId != nil && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(roster: [StudentRosterItem], now: Date = Date(), defaultDurationMinutes: Int = 50) {
        let initiallySelectedStudent = roster.first(where: \.active) ?? roster.first
        self.roster = roster
        self.mode = .oneOff
        self.selectedStudentId = initiallySelectedStudent?.id
        self.title = initiallySelectedStudent.map { "\($0.name) 드럼 레슨" } ?? "드럼 레슨"
        self.startDate = now
        self.durationMinutes = min(max(defaultDurationMinutes, 15), 240)
        self.timezone = TimeZone.current.identifier
        self.recurrenceInterval = 1
        self.recurrenceWeekday = max(0, Calendar.iso8601SeoulCompatible.component(.weekday, from: now) - 1)
        self.hasEndDate = false
        self.endDate = Calendar.iso8601SeoulCompatible.date(byAdding: .month, value: 2, to: now) ?? now
        self.isUsingSuggestedTitle = true
    }

    mutating func selectStudent(_ studentId: EntityID?) {
        selectedStudentId = studentId
        guard isUsingSuggestedTitle else { return }
        title = suggestedTitle(for: studentId)
    }

    mutating func updateTitle(_ title: String) {
        self.title = title
        isUsingSuggestedTitle = title == suggestedTitle(for: selectedStudentId)
    }

    func makeOneOffInput() throws -> ScheduleLessonInput {
        guard let selectedStudentId else {
            throw RepositoryError(message: "학생을 선택하세요.")
        }

        let endDate = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startDate) ?? startDate
        return ScheduleLessonInput(
            studentId: selectedStudentId,
            title: title,
            startsAt: ISO8601DateFormatter.plain.string(from: startDate),
            endsAt: ISO8601DateFormatter.plain.string(from: endDate),
            timezone: timezone,
            durationMinutes: durationMinutes
        )
    }

    func makeWeeklyInput() throws -> WeeklyScheduleInput {
        guard let selectedStudentId else {
            throw RepositoryError(message: "학생을 선택하세요.")
        }

        return WeeklyScheduleInput(
            studentId: selectedStudentId,
            title: title,
            defaultDurationMinutes: durationMinutes,
            timezone: timezone,
            recurrenceInterval: recurrenceInterval,
            recurrenceWeekday: recurrenceWeekday,
            startsOn: DateOnly.string(from: startDate, timeZone: resolvedTimeZone),
            endsOn: hasEndDate ? DateOnly.string(from: endDate, timeZone: resolvedTimeZone) : nil,
            startTime: Self.timeString(from: startDate, timeZone: resolvedTimeZone)
        )
    }

    private var resolvedTimeZone: TimeZone {
        TimeZone(identifier: timezone) ?? .current
    }

    private static func timeString(from date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.calendar = .iso8601SeoulCompatible
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    private static func koreanDate(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = .iso8601SeoulCompatible
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: date)
    }

    fileprivate static func timezoneDisplayName(for identifier: String) -> String {
        let timeZone = TimeZone(identifier: identifier) ?? .current
        return timeZone.localizedName(for: .generic, locale: Locale(identifier: "ko_KR"))
            ?? timeZone.localizedName(for: .standard, locale: Locale(identifier: "ko_KR"))
            ?? "현재 Mac의 시간대"
    }

    private func suggestedTitle(for studentId: EntityID?) -> String {
        guard let student = roster.first(where: { $0.id == studentId }) else {
            return "드럼 레슨"
        }
        return "\(student.name) 드럼 레슨"
    }
}

struct EditOccurrenceSheet: View {
    @Environment(\.dismiss) private var dismiss
    let event: CalendarLessonEvent
    let repository: ScheduleRepository
    var onSaved: () async -> Void = {}

    @State private var form: EditOccurrenceFormState
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var hasSavedLocally = false
    @FocusState private var isStartDateFocused: Bool

    init(event: CalendarLessonEvent, repository: ScheduleRepository, onSaved: @escaping () async -> Void = {}) {
        self.event = event
        self.repository = repository
        self.onSaved = onSaved
        _form = State(initialValue: EditOccurrenceFormState(event: event))
    }

    var body: some View {
        CompactModalSurface(width: 440) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                SectionHeader(
                    title: "레슨 시간 수정",
                    subtitle: "\(event.studentName) · 이번 회차만 변경하며 Apple 캘린더에도 반영됩니다.",
                    titleFont: .title2.weight(.semibold)
                )

                CompactModalPanel {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                            CompactModalField("시작") {
                                DatePicker(
                                    "시작",
                                    selection: $form.startDate,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .labelsHidden()
                                .datePickerStyle(.field)
                                .fixedSize()
                                .focused($isStartDateFocused)
                                .accessibilityLabel("레슨 시작")
                                .environment(\.timeZone, TimeZone(identifier: form.timezone) ?? .current)
                            }

                            CompactModalField("레슨 길이") {
                                Stepper("\(form.durationMinutes)분", value: $form.durationMinutes, in: 15...240, step: 5)
                                    .font(.body.monospacedDigit().weight(.medium))
                                    .fixedSize()
                                    .accessibilityLabel("레슨 길이")
                                    .accessibilityValue("\(form.durationMinutes)분")
                            }
                            .frame(width: 128)
                        }

                        Divider()

                        CompactModalSummary(
                            title: "시간대",
                            value: form.timezoneDisplayName,
                            systemImage: "clock"
                        )
                    }
                }

                if let errorMessage {
                    CompactModalError(message: errorMessage)
                }

                CompactModalActions(
                    cancelTitle: hasSavedLocally ? "닫기" : "취소",
                    confirmTitle: editSaveButtonTitle,
                    confirmSystemImage: "checkmark",
                    workingTitle: "저장 중",
                    isWorking: isSaving,
                    isConfirmDisabled: isSaving || hasSavedLocally,
                    onCancel: { dismiss() },
                    onConfirm: { Task { await save() } }
                )
            }
        }
        .environment(\.locale, Locale(identifier: "ko_KR"))
        .interactiveDismissDisabled(isSaving)
        .onAppear { isStartDateFocused = true }
        .onChange(of: errorMessage) { _, message in
            guard let message else { return }
            AccessibilityNotification.Announcement(message).post()
        }
    }

    private func save() async {
        guard !isSaving, !hasSavedLocally else { return }
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            let occurrence = try await repository.editOccurrence(form.makeInput(occurrenceId: event.id))
            hasSavedLocally = true
            await onSaved()
            if let syncFailure = calendarSyncFailureMessage(for: [occurrence]) {
                errorMessage = syncFailure
                return
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var editSaveButtonTitle: String {
        if isSaving { return "저장 중" }
        if hasSavedLocally { return "저장됨" }
        return "변경 저장"
    }
}

private func calendarSyncFailureMessage(for occurrences: [LessonOccurrence]) -> String? {
    guard let failed = occurrences.first(where: { $0.nativeCalendarSyncStatus == .failed }) else {
        return nil
    }
    let reason = failed.nativeCalendarSyncError ?? "설정 > 동기화 대기열에서 다시 시도하세요."
    return "레슨은 드럼 레슨 OS에 저장됐지만 Apple 캘린더 동기화에 실패했습니다: \(reason)"
}

struct EditOccurrenceFormState: Equatable {
    var startDate: Date
    var durationMinutes: Int
    var timezone: String

    var timezoneDisplayName: String {
        ScheduleLessonFormState.timezoneDisplayName(for: timezone)
    }

    init(event: CalendarLessonEvent) {
        let start = ISO8601DateFormatter.withFractions.date(from: event.startsAt) ?? ISO8601DateFormatter.plain.date(from: event.startsAt) ?? Date()
        self.startDate = start
        self.durationMinutes = max(15, event.durationMinutes)
        self.timezone = event.timezone
    }

    func makeInput(occurrenceId: EntityID) -> EditOccurrenceInput {
        let endDate = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startDate) ?? startDate
        return EditOccurrenceInput(
            occurrenceId: occurrenceId,
            startsAt: ISO8601DateFormatter.plain.string(from: startDate),
            endsAt: ISO8601DateFormatter.plain.string(from: endDate),
            timezone: timezone
        )
    }
}
