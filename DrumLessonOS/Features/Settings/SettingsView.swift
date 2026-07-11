import Accessibility
import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable var syncStatus: SyncStatusViewModel
    let calendar: CalendarRepository
    @Bindable var preferences: AppPreferences
    let localDataDirectoryURL: URL?
    let localDataBackup: LocalDataBackupRepository?
    let onDataRestored: @MainActor () async -> Void

    @State private var backupDocument: LocalDataBackupDocument?
    @State private var isExportingBackup = false
    @State private var isImportingBackup = false
    @State private var isConfirmingRestore = false
    @State private var isWorkingWithBackup = false
    @State private var pendingRestoreData: Data?
    @State private var pendingRestoreName = ""
    @State private var backupFeedback: BackupFeedback?

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 860

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    WorkbenchHeader(title: "설정", subtitle: "앱 기본값, 로컬 데이터, Apple 캘린더")

                    if isCompact {
                        preferencesSection
                        CalendarSettingsView(calendar: calendar)
                        SyncStatusView(viewModel: syncStatus)
                        localDataSection
                    } else {
                        HStack(alignment: .top, spacing: 16) {
                            VStack(alignment: .leading, spacing: 16) {
                                CalendarSettingsView(calendar: calendar)
                                SyncStatusView(viewModel: syncStatus)
                            }
                                .frame(minWidth: 440, maxWidth: .infinity)
                            VStack(alignment: .leading, spacing: 16) {
                                preferencesSection
                                localDataSection
                            }
                            .frame(width: 360)
                        }
                    }
                }
                .frame(maxWidth: AppTheme.contentWidth, alignment: .topLeading)
                .padding(20)
            }
        }
        .navigationTitle("설정")
        .fileExporter(
            isPresented: $isExportingBackup,
            document: backupDocument,
            contentType: .drumLessonBackup,
            defaultFilename: backupFilename
        ) { result in
            backupDocument = nil
            switch result {
            case .success:
                backupFeedback = BackupFeedback(message: "백업 파일을 저장했습니다.", isError: false)
            case .failure(let error):
                backupFeedback = BackupFeedback(message: error.localizedDescription, isError: true)
            }
        }
        .fileImporter(
            isPresented: $isImportingBackup,
            allowedContentTypes: [.drumLessonBackup, .json]
        ) { result in
            prepareRestore(from: result)
        }
        .alert("백업을 복원할까요?", isPresented: $isConfirmingRestore) {
            Button("취소", role: .cancel) {
                pendingRestoreData = nil
                pendingRestoreName = ""
            }
            Button("복원", role: .destructive) {
                restoreSelectedBackup()
            }
        } message: {
            Text("\(pendingRestoreName)의 기록으로 현재 데이터를 교체합니다. 복원 직전 상태는 자동 백업되며 캘린더 대기 작업은 비워집니다.")
        }
    }

    private var preferencesSection: some View {
        WorkbenchSurface(.panel, padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                SectionHeader(title: "사용 환경", subtitle: "자주 쓰는 값을 정해 반복 입력을 줄입니다.")

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("화면 모드")
                        .font(.subheadline.weight(.semibold))
                    Picker("화면 모드", selection: $preferences.appearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.label).tag(appearance)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .accessibilityLabel("화면 모드")
                }

                Divider()

                preferenceRow(
                    title: "새 레슨 기본 길이",
                    detail: "레슨 추가 화면이 이 시간으로 시작됩니다."
                ) {
                    Picker("새 레슨 기본 길이", selection: $preferences.defaultLessonDurationMinutes) {
                        ForEach(AppPreferences.lessonDurationOptions, id: \.self) { minutes in
                            Text("\(minutes)분").tag(minutes)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                    .accessibilityLabel("새 레슨 기본 길이")
                }

                Divider()

                preferenceRow(
                    title: "캘린더 기본 알림",
                    detail: "새로 만드는 Apple 캘린더 일정에 적용됩니다."
                ) {
                    Picker("캘린더 기본 알림", selection: $preferences.calendarReminderMinutes) {
                        ForEach(AppPreferences.calendarReminderOptions, id: \.self) { minutes in
                            Text(calendarReminderLabel(minutes)).tag(minutes)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                    .accessibilityLabel("캘린더 기본 알림")
                }
            }
        }
    }

    private func preferenceRow<Content: View>(
        title: String,
        detail: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: AppTheme.Spacing.sm)
            content()
        }
    }

    private var localDataSection: some View {
        WorkbenchSurface(.quiet, padding: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "데이터 및 앱 정보", subtitle: "학생과 수업 기록은 이 Mac 안에 보관됩니다.")

                if let localDataDirectoryURL {
                    Label("레슨 기록과 캘린더 동기화 대기열을 함께 보관합니다.", systemImage: "internaldrive")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text(localDataDirectoryURL.path)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        NSWorkspace.shared.open(localDataDirectoryURL)
                    } label: {
                        Label("Finder에서 데이터 폴더 열기", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                    .help("데이터베이스와 캘린더 동기화 대기열이 저장된 폴더를 엽니다.")

                    if localDataBackup != nil {
                        Divider()

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                backupButtons
                            }
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                backupButtons
                            }
                        }

                        Text("백업 파일에는 학생과 레슨 기록만 포함됩니다. Apple 캘린더 실행 대기열은 포함되지 않습니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let backupFeedback {
                            Label(
                                backupFeedback.message,
                                systemImage: backupFeedback.isError ? "exclamationmark.triangle" : "checkmark.circle"
                            )
                            .font(.caption)
                            .foregroundStyle(backupFeedback.isError ? AppTheme.Semantic.error : AppTheme.Semantic.success)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else {
                    Label("미리보기 데이터는 앱을 종료하면 유지되지 않습니다.", systemImage: "eye")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Divider()

                LabeledContent("버전", value: appVersion)
                    .font(.footnote)
            }
        }
    }

    @ViewBuilder
    private var backupButtons: some View {
        Button {
            prepareBackupExport()
        } label: {
            Label("백업 저장", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.bordered)
        .disabled(isWorkingWithBackup)

        Button {
            isImportingBackup = true
        } label: {
            Label("백업 복원", systemImage: "arrow.counterclockwise")
        }
        .buttonStyle(.bordered)
        .disabled(isWorkingWithBackup)
    }

    private var backupFilename: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return "Drum-Lesson-OS-\(formatter.string(from: Date()))"
    }

    private func prepareBackupExport() {
        guard let localDataBackup else { return }
        isWorkingWithBackup = true
        backupFeedback = nil
        Task {
            defer { isWorkingWithBackup = false }
            do {
                backupDocument = LocalDataBackupDocument(data: try await localDataBackup.makeBackupData())
                isExportingBackup = true
            } catch {
                backupFeedback = BackupFeedback(message: error.localizedDescription, isError: true)
            }
        }
    }

    private func prepareRestore(from result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess { url.stopAccessingSecurityScopedResource() }
            }
            pendingRestoreData = try Data(contentsOf: url)
            pendingRestoreName = url.lastPathComponent
            isConfirmingRestore = true
        } catch {
            backupFeedback = BackupFeedback(message: error.localizedDescription, isError: true)
        }
    }

    private func restoreSelectedBackup() {
        guard let localDataBackup, let data = pendingRestoreData else { return }
        isWorkingWithBackup = true
        backupFeedback = nil
        Task {
            defer {
                isWorkingWithBackup = false
                pendingRestoreData = nil
                pendingRestoreName = ""
            }
            do {
                let safetyBackupURL = try await localDataBackup.restoreBackup(from: data)
                await onDataRestored()
                backupFeedback = BackupFeedback(
                    message: "복원했습니다. 이전 상태는 \(safetyBackupURL.lastPathComponent)에 보관했습니다.",
                    isError: false
                )
            } catch {
                backupFeedback = BackupFeedback(message: error.localizedDescription, isError: true)
            }
        }
    }

    private func calendarReminderLabel(_ minutes: Int?) -> String {
        guard let minutes else { return "끔" }
        return "\(minutes)분 전"
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "개발"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return build.map { "\(version) (\($0))" } ?? version
    }
}
private struct BackupFeedback: Equatable {
    var message: String
    var isError: Bool
}

private extension UTType {
    static let drumLessonBackup = UTType(
        exportedAs: "com.ericshim.DrumLessonOS.backup",
        conformingTo: .json
    )
}

private struct LocalDataBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.drumLessonBackup, .json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw RepositoryError(message: "백업 파일을 읽을 수 없습니다.")
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
