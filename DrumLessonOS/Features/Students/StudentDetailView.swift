import Accessibility
import SwiftUI

struct StudentDetailView: View {
    @State private var viewModel: StudentDetailViewModel
    @State private var isShowingStudentRecord = false
    private let presentedViewModel: StudentDetailViewModel
    private let onStudentDeleted: () async -> Void

    init(viewModel: StudentDetailViewModel, onStudentDeleted: @escaping () async -> Void) {
        presentedViewModel = viewModel
        self.onStudentDeleted = onStudentDeleted
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if let detail = viewModel.detail {
                detailContent(detail)
            } else if viewModel.isLoading {
                ContentUnavailableView("학생 정보를 불러오는 중", systemImage: "hourglass")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "학생 정보를 열 수 없습니다",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text(viewModel.errorMessage ?? "대시보드에서 새로고침하세요.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.workspaceBackground)
        .task(id: presentedViewModelIdentity) {
            if ownedViewModelIdentity != presentedViewModelIdentity {
                viewModel = presentedViewModel
                isShowingStudentRecord = false
            }
            await viewModel.load()
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            guard let message else { return }
            AccessibilityNotification.Announcement(message).post()
        }
        .onChange(of: viewModel.closeoutStatusMessage) { _, message in
            guard let message else { return }
            AccessibilityNotification.Announcement(message).post()
        }
        .navigationTitle(viewModel.detail?.name ?? "학생")
    }

    @ViewBuilder
    private func detailContent(_ detail: StudentDetail) -> some View {
        if viewModel.lessonContext != nil {
            GeometryReader { proxy in
                LessonFlowWorkspace(
                    viewModel: viewModel,
                    detail: detail,
                    lessonContext: viewModel.lessonContext,
                    isShowingStudentRecord: $isShowingStudentRecord
                )
                .disabled(isShowingStudentRecord)
                .allowsHitTesting(!isShowingStudentRecord)
                .accessibilityHidden(isShowingStudentRecord)
                .overlay(alignment: .trailing) {
                    if isShowingStudentRecord {
                        StudentDetailTabs(
                            detail: detail,
                            presentation: .sessionDrawer,
                            onClose: { isShowingStudentRecord = false }
                        )
                        .frame(width: min(420, proxy.size.width))
                        .frame(maxHeight: .infinity)
                        .onExitCommand {
                            isShowingStudentRecord = false
                        }
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(Color(nsColor: .separatorColor))
                                .frame(width: 1)
                        }
                    }
                }
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    StudentHeaderView(detail: detail)

                    LazyVGrid(
                        columns: [
                            GridItem(
                                .adaptive(minimum: 380, maximum: 580),
                                spacing: AppTheme.Spacing.xl,
                                alignment: .top
                            )
                        ],
                        alignment: .leading,
                        spacing: AppTheme.Spacing.xl
                    ) {
                        LessonFlowWorkspace(
                            viewModel: viewModel,
                            detail: detail,
                            lessonContext: nil
                        )
                        StudentDetailTabs(detail: detail)
                    }

                    StudentDetailEditorPanel(
                        viewModel: viewModel,
                        detail: detail,
                        onStudentDeleted: onStudentDeleted
                    )
                        .id(detail.id)
                }
                .frame(maxWidth: AppTheme.contentWidth)
                .padding(AppTheme.Spacing.xl)
            }
        }
    }

    private var presentedViewModelIdentity: ViewModelIdentity {
        ViewModelIdentity(
            studentId: presentedViewModel.studentId,
            lessonId: presentedViewModel.lessonContext?.id
        )
    }

    private var ownedViewModelIdentity: ViewModelIdentity {
        ViewModelIdentity(
            studentId: viewModel.studentId,
            lessonId: viewModel.lessonContext?.id
        )
    }

    private struct ViewModelIdentity: Hashable {
        var studentId: EntityID
        var lessonId: EntityID?
    }
}
