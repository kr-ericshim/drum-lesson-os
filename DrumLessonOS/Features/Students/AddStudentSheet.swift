import Accessibility
import SwiftUI

struct AddStudentSheet: View {
    @Environment(\.dismiss) private var dismiss
    let writes: StudentWriteRepository
    var onCreated: (EntityID) async -> Void = { _ in }

    @State private var form = AddStudentFormState()
    @State private var errorMessage: String?
    @State private var isSaving = false
    @FocusState private var focusedField: FocusedField?

    private enum FocusedField: Hashable {
        case name
    }

    var body: some View {
        CompactModalSurface(width: 480) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                SectionHeader(
                    title: "학생 추가",
                    subtitle: "다음 레슨에 필요한 세 가지를 짧게 입력하세요. 모든 항목이 필요합니다.",
                    titleFont: .title2.weight(.semibold)
                )

                CompactModalPanel {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        CompactModalField("이름") {
                            TextField("학생 이름", text: $form.name)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .name)
                                .accessibilityLabel("학생 이름")
                        }

                        CompactModalField(
                            "프로필 단서",
                            detail: "설명 방식, 좋아하는 곡처럼 수업을 여는 데 도움이 되는 정보"
                        ) {
                            TextField("예: 짧게 시범을 보여주면 바로 따라와요", text: $form.profileCue, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...3)
                                .accessibilityLabel("프로필 단서")
                        }

                        CompactModalField(
                            "먼저 확인할 점",
                            detail: "다음 레슨 시작 전에 가장 먼저 볼 한 가지"
                        ) {
                            TextField("예: 필인 뒤 첫 박 착지", text: $form.primaryWeakPoint, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...3)
                                .accessibilityLabel("먼저 확인할 점")
                        }
                    }
                }

                if let errorMessage {
                    CompactModalError(message: errorMessage)
                }

                CompactModalActions(
                    cancelTitle: "취소",
                    confirmTitle: "학생 만들기",
                    confirmSystemImage: "person.badge.plus",
                    workingTitle: "만드는 중",
                    isWorking: isSaving,
                    isConfirmDisabled: isSaving || !form.canSubmit,
                    onCancel: { dismiss() },
                    onConfirm: { Task { await save() } }
                )
            }
        }
        .interactiveDismissDisabled(isSaving)
        .onAppear { focusedField = .name }
        .onChange(of: errorMessage) { _, message in
            guard let message else { return }
            AccessibilityNotification.Announcement(message).post()
        }
    }

    private func save() async {
        guard !isSaving else { return }
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            let input = form.makeInput()
            try StudentEditingValidation.validate(input)
            let id = try await writes.createStudent(input)
            await onCreated(id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AddStudentFormState: Equatable {
    var name = ""
    var profileCue = ""
    var primaryWeakPoint = ""
    let active = true

    var canSubmit: Bool {
        [name, profileCue, primaryWeakPoint]
            .allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func makeInput() -> StudentProfileInput {
        StudentProfileInput(
            studentId: nil,
            name: name,
            profileCue: profileCue,
            primaryWeakPoint: primaryWeakPoint,
            active: active
        )
    }
}
