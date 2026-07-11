import SwiftUI

private enum DataResetConfirmationStep {
    case scope
    case typedConfirmation
}

struct DataResetConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let reset: LocalDataResetRepository
    let onCompleted: @MainActor () async -> Void

    @State private var step: DataResetConfirmationStep = .scope
    @State private var confirmationText = ""
    @State private var isResetting = false
    @State private var errorMessage: String?
    @FocusState private var isConfirmationFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
            HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Semantic.error.opacity(0.12))
                    Image(systemName: "externaldrive.badge.xmark")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.Semantic.error)
                }
                .frame(width: 44, height: 44)

                SectionHeader(
                    title: "레슨 데이터 초기화",
                    subtitle: "두 단계를 모두 확인해야 삭제가 시작됩니다.",
                    titleFont: .title3.weight(.semibold)
                )
            }

            confirmationProgress

            Group {
                switch step {
                case .scope:
                    scopeConfirmation
                case .typedConfirmation:
                    typedConfirmation
                }
            }

            Divider()
            confirmationActions
        }
        .padding(AppTheme.Spacing.xxl)
        .frame(width: 480)
        .interactiveDismissDisabled(isResetting)
        .onAppear {
            step = .scope
            confirmationText = ""
            errorMessage = nil
        }
        .onChange(of: step) { _, newStep in
            guard newStep == .typedConfirmation else { return }
            Task { @MainActor in
                await Task.yield()
                isConfirmationFieldFocused = true
            }
        }
    }

    private var confirmationProgress: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            stepPill(
                number: 1,
                title: "삭제 범위",
                isActive: step == .scope,
                isComplete: step == .typedConfirmation
            )

            Capsule()
                .fill(Color(nsColor: .separatorColor))
                .frame(height: 1)

            stepPill(
                number: 2,
                title: "직접 입력",
                isActive: step == .typedConfirmation,
                isComplete: false
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(step == .scope ? "초기화 확인 1단계" : "초기화 확인 2단계")
    }

    private func stepPill(
        number: Int,
        title: String,
        isActive: Bool,
        isComplete: Bool
    ) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: isComplete ? "checkmark" : "\(number).circle.fill")
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(isActive || isComplete ? AppTheme.Semantic.error : Color(nsColor: .secondaryLabelColor))
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, 6)
        .background(
            isActive || isComplete ? AppTheme.Semantic.error.opacity(0.10) : AppTheme.surfaceColor(.quiet),
            in: Capsule()
        )
    }

    private var scopeConfirmation: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("1단계 · 삭제 범위 확인")
                .font(.headline)

            resetScopeRow(
                icon: "person.2.slash",
                title: "이 Mac의 레슨 기록",
                detail: "학생, 레슨, 진도, 과제, 메모, 수강비 기록과 동기화 대기열"
            )
            resetScopeRow(
                icon: "calendar.badge.minus",
                title: "연결된 Apple 캘린더 일정",
                detail: "예정, 완료, 취소 상태를 포함해 앱 기록과 연결된 일정"
            )
            resetScopeRow(
                icon: "checkmark.shield",
                title: "유지되는 항목",
                detail: "화면 모드, 기본 레슨 길이, 알림 설정, 기존 백업 파일"
            )

            Text("삭제된 Apple 캘린더 일정은 백업 파일로 복원되지 않습니다. 필요한 경우 먼저 설정의 ‘백업 저장’을 사용하세요.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func resetScopeRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(title == "유지되는 항목" ? AppTheme.Semantic.success : AppTheme.Semantic.error)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var typedConfirmation: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("2단계 · 직접 입력")
                .font(.headline)
            Text("계속하려면 아래에 **초기화**를 정확히 입력하세요.")
                .font(.subheadline)

            TextField("초기화", text: $confirmationText)
                .textFieldStyle(.roundedBorder)
                .focused($isConfirmationFieldFocused)
                .disabled(isResetting)
                .accessibilityLabel("초기화 확인 문구")
                .accessibilityIdentifier("data-reset-confirmation-input")

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Semantic.error)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Apple 캘린더 일정 삭제가 끝나기 전에는 로컬 기록을 비우지 않습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var confirmationActions: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            switch step {
            case .scope:
                Button("취소", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("2단계로 계속") {
                    step = .typedConfirmation
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)

            case .typedConfirmation:
                Button("이전") {
                    errorMessage = nil
                    step = .scope
                }
                .disabled(isResetting)

                Spacer()

                if isResetting {
                    ProgressView()
                        .controlSize(.small)
                }

                Button("데이터 및 캘린더 일정 삭제", role: .destructive) {
                    performReset()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.Semantic.error)
                .disabled(confirmationText != "초기화" || isResetting)
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("data-reset-confirm-button")
            }
        }
    }

    private func performReset() {
        isResetting = true
        errorMessage = nil
        Task { @MainActor in
            do {
                try await reset.resetAllData()
                await onCompleted()
                isResetting = false
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isResetting = false
                isConfirmationFieldFocused = true
            }
        }
    }
}
