import Accessibility
import Observation
import SwiftUI

struct CalendarSettingsView: View {
    @Environment(\.openURL) private var openURL
    @State private var viewModel: CalendarSettingsViewModel

    init(calendar: CalendarRepository) {
        _viewModel = State(initialValue: CalendarSettingsViewModel(calendar: calendar))
    }

    var body: some View {
        WorkbenchSurface(.panel, padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 12) {
                WorkbenchHeader(title: "Apple 캘린더", subtitle: "Apple 비밀번호를 저장하지 않고 캘린더 권한으로 연결합니다.") {
                    StatusBadge(
                        label: viewModel.permission.label,
                        systemImage: permissionIcon,
                        tint: permissionTint
                    )
                }

                permissionContent

                if let feedback = viewModel.feedback {
                    Label(feedback.message, systemImage: feedback.systemImage)
                        .font(.footnote)
                        .foregroundStyle(feedback.tint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .task { await viewModel.refresh() }
        .onChange(of: viewModel.feedback) { _, feedback in
            guard let feedback else { return }
            AccessibilityNotification.Announcement(feedback.message).post()
        }
    }

    @ViewBuilder
    private var permissionContent: some View {
        switch viewModel.permission {
        case .authorized:
            authorizedContent
        case .notDetermined:
            permissionExplanation(
                title: "캘린더 연결이 필요합니다",
                description: "레슨 일정을 만들고 수정하려면 Apple 캘린더 전체 접근을 허용하세요.",
                systemImage: "calendar.badge.plus"
            )
            requestAccessButton
        case .denied:
            permissionExplanation(
                title: "캘린더 접근이 꺼져 있습니다",
                description: "시스템 설정의 개인정보 보호 및 보안에서 Drum Lesson OS의 캘린더 접근을 허용하세요.",
                systemImage: "calendar.badge.exclamationmark"
            )
            Button {
                guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else { return }
                openURL(url)
            } label: {
                Label("시스템 설정 열기", systemImage: "gear")
            }
        case .restricted:
            permissionExplanation(
                title: "이 Mac에서 캘린더 접근이 제한됩니다",
                description: "관리자 또는 스크린 타임 제한을 확인한 뒤 다시 시도하세요.",
                systemImage: "lock.trianglebadge.exclamationmark"
            )
        case .writeOnly:
            permissionExplanation(
                title: "전체 접근이 필요합니다",
                description: "현재는 쓰기 전용 권한입니다. 캘린더를 선택하고 기존 일정을 안전하게 수정하려면 전체 접근을 허용하세요.",
                systemImage: "calendar.badge.exclamationmark"
            )
            requestAccessButton
        case .unknown:
            permissionExplanation(
                title: "캘린더 권한 상태를 확인할 수 없습니다",
                description: "상태를 다시 확인하거나 시스템 설정에서 캘린더 권한을 살펴보세요.",
                systemImage: "questionmark.circle"
            )
            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label("상태 다시 확인", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isBusy)
        }
    }

    @ViewBuilder
    private var authorizedContent: some View {
        if viewModel.isLoadingCalendars && viewModel.calendars.isEmpty {
            HStack(spacing: AppTheme.Spacing.sm) {
                ProgressView()
                    .controlSize(.small)
                Text("쓸 수 있는 캘린더를 불러오는 중…")
                    .foregroundStyle(.secondary)
            }
        } else if viewModel.hasLoadedCalendars && viewModel.calendars.isEmpty {
            ContentUnavailableView {
                Label("쓸 수 있는 캘린더가 없습니다", systemImage: "calendar.badge.exclamationmark")
            } description: {
                Text("Apple 캘린더에서 수정 가능한 캘린더를 만든 뒤 다시 불러오세요.")
            } actions: {
                reloadCalendarsButton
            }
        } else {
            if !viewModel.hasLoadedCalendars {
                reloadCalendarsButton
            }

            ForEach(viewModel.calendars) { item in
                calendarRow(item)
            }

            if !viewModel.calendars.isEmpty, viewModel.selectedCalendarID == nil {
                Label("레슨 일정을 저장할 캘린더를 선택하세요.", systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.Semantic.warning)
            }

            if viewModel.hasLoadedCalendars, !viewModel.calendars.isEmpty {
                reloadCalendarsButton
                    .controlSize(.small)
            }
        }
    }

    private func permissionExplanation(title: String, description: String, systemImage: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(permissionTint)
        }
    }

    private var requestAccessButton: some View {
        Button {
            Task { await viewModel.requestPermission() }
        } label: {
            if viewModel.isRequestingPermission {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ProgressView()
                        .controlSize(.small)
                    Text("접근 요청 중…")
                }
            } else {
                Label("캘린더 접근 허용", systemImage: "checkmark.shield")
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isBusy)
    }

    private var reloadCalendarsButton: some View {
        Button {
            Task { await viewModel.loadCalendars() }
        } label: {
            if viewModel.isLoadingCalendars {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ProgressView()
                        .controlSize(.small)
                    Text("불러오는 중…")
                }
            } else {
                Label("캘린더 다시 불러오기", systemImage: "arrow.clockwise")
            }
        }
        .disabled(viewModel.isBusy)
    }

    private func calendarRow(_ item: WritableCalendar) -> some View {
        let isSelected = item.id == viewModel.selectedCalendarID
        let isSelecting = item.id == viewModel.selectingCalendarID

        return Button {
            Task { await viewModel.selectCalendar(item) }
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                    Text(item.sourceTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: AppTheme.Spacing.md)
                if isSelecting {
                    ProgressView()
                        .controlSize(.small)
                } else if isSelected {
                    Label("현재 저장 위치", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.Semantic.success)
                }
            }
            .padding(AppTheme.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AppTheme.Accent.teaching.opacity(0.10) : Color.secondary.opacity(0.055), in: AppTheme.softPanel)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isBusy)
        .accessibilityLabel("\(item.title), \(item.sourceTitle)")
        .accessibilityValue(isSelected ? "현재 레슨 저장 위치" : "선택되지 않음")
        .accessibilityHint(isSelected ? "" : "레슨 일정을 저장할 Apple 캘린더로 선택합니다.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var permissionIcon: String {
        switch viewModel.permission {
        case .authorized: "checkmark.circle.fill"
        case .denied, .restricted: "xmark.circle.fill"
        case .writeOnly: "pencil.circle"
        case .notDetermined, .unknown: "questionmark.circle"
        }
    }

    private var permissionTint: Color {
        switch viewModel.permission {
        case .authorized: AppTheme.Semantic.success
        case .denied, .restricted: AppTheme.Semantic.error
        case .notDetermined, .writeOnly, .unknown: AppTheme.Semantic.warning
        }
    }
}

struct CalendarSettingsFeedback: Equatable {
    enum Kind: Equatable {
        case success
        case warning
        case error
    }

    var kind: Kind
    var message: String

    var systemImage: String {
        switch kind {
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.circle.fill"
        case .error: "xmark.circle.fill"
        }
    }

    var tint: Color {
        switch kind {
        case .success: AppTheme.Semantic.success
        case .warning: AppTheme.Semantic.warning
        case .error: AppTheme.Semantic.error
        }
    }
}

@MainActor
@Observable
final class CalendarSettingsViewModel {
    private(set) var permission: EventKitPermissionState = .notDetermined
    private(set) var calendars: [WritableCalendar] = []
    private(set) var selectedCalendarID: String?
    private(set) var feedback: CalendarSettingsFeedback?
    private(set) var isRequestingPermission = false
    private(set) var isLoadingCalendars = false
    private(set) var selectingCalendarID: String?
    private(set) var hasLoadedCalendars = false

    private let calendar: CalendarRepository

    init(calendar: CalendarRepository) {
        self.calendar = calendar
    }

    var isBusy: Bool {
        isRequestingPermission || isLoadingCalendars || selectingCalendarID != nil
    }

    func refresh() async {
        permission = calendar.permissionStatus()
        selectedCalendarID = calendar.selectedCalendar()?.id
        feedback = nil

        guard permission == .authorized else {
            calendars = []
            hasLoadedCalendars = false
            return
        }
        await loadCalendars()
    }

    func requestPermission() async {
        guard !isBusy else { return }
        isRequestingPermission = true
        feedback = nil
        defer { isRequestingPermission = false }

        do {
            permission = try await calendar.requestPermission()
            if permission == .authorized {
                feedback = CalendarSettingsFeedback(kind: .success, message: "Apple 캘린더 접근을 허용했습니다.")
                await loadCalendars()
            } else {
                calendars = []
                hasLoadedCalendars = false
                feedback = CalendarSettingsFeedback(
                    kind: .warning,
                    message: "캘린더 권한이 \(permission.label) 상태입니다. 안내에 따라 권한을 확인하세요."
                )
            }
        } catch {
            feedback = CalendarSettingsFeedback(kind: .error, message: "캘린더 접근을 요청하지 못했습니다. \(error.localizedDescription)")
        }
    }

    func loadCalendars() async {
        guard !isLoadingCalendars, selectingCalendarID == nil else { return }
        guard permission == .authorized else {
            feedback = CalendarSettingsFeedback(kind: .warning, message: "캘린더 전체 접근을 허용한 뒤 목록을 불러오세요.")
            return
        }

        isLoadingCalendars = true
        hasLoadedCalendars = false
        if !isRequestingPermission {
            feedback = nil
        }
        defer { isLoadingCalendars = false }

        do {
            calendars = try await calendar.listWritableCalendars()
                .sorted { lhs, rhs in
                    let sourceOrder = lhs.sourceTitle.localizedStandardCompare(rhs.sourceTitle)
                    if sourceOrder == .orderedSame {
                        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                    }
                    return sourceOrder == .orderedAscending
                }
            let selectedID = calendar.selectedCalendar()?.id
            selectedCalendarID = calendars.contains { $0.id == selectedID } ? selectedID : nil
            hasLoadedCalendars = true
        } catch {
            calendars = []
            hasLoadedCalendars = false
            feedback = CalendarSettingsFeedback(kind: .error, message: "캘린더 목록을 불러오지 못했습니다. \(error.localizedDescription)")
        }
    }

    func selectCalendar(_ item: WritableCalendar) async {
        guard !isBusy, item.id != selectedCalendarID else { return }
        selectingCalendarID = item.id
        feedback = nil
        defer { selectingCalendarID = nil }

        do {
            try await calendar.selectCalendar(item)
            selectedCalendarID = item.id
            feedback = CalendarSettingsFeedback(kind: .success, message: "‘\(item.title)’ 캘린더에 레슨 일정을 저장합니다.")
        } catch {
            feedback = CalendarSettingsFeedback(kind: .error, message: "캘린더를 선택하지 못했습니다. \(error.localizedDescription)")
        }
    }
}
